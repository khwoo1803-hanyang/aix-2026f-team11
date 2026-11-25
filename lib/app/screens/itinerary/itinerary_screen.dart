import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/itinerary.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/itinerary_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../services/itinerary_service.dart';
import '../chat/chat_sheet.dart';

/// 장소 후보함과 공동 일정표 (활동지 #10).
/// 멤버가 장소를 올리고 좋아요를 누른 뒤, 일차별 일정에 넣고 순서를 바꾼다. 모두 실시간으로 공유된다.
class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  String? _selectedDayId;

  /// 방금 추가한 일차. 실시간으로 들어오면 그 일차를 고른다.
  int? _wantDayNumber;

  /// 순서를 바꾼 직후 서버 반영 전까지 화면에 먼저 보여줄 순서 (일차 id → 항목 id 목록).
  final _pendingOrder = <String, List<String>>{};

  ItineraryService get _service => ref.read(itineraryServiceProvider);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on ItineraryException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('네트워크 상태를 확인해 주세요.');
    }
    return false;
  }

  // 장소 -----------------------------------------------------------------

  Future<void> _addPlace() async {
    final input = await showDialog<_PlaceInput>(
      context: context,
      builder: (_) => const _AddPlaceDialog(),
    );
    if (input == null) return;
    await _run(
      () => _service.addPlace(
        roomId: widget.roomId,
        name: input.name,
        category: input.category,
        address: input.address,
        memo: input.memo,
      ),
    );
  }

  Future<void> _deletePlace(Place place) async {
    final ok = await _confirm(
      '장소 삭제',
      '${place.name}을(를) 지울까요? 일정에 넣은 것도 함께 지워져요.',
    );
    if (ok) await _run(() => _service.deletePlace(place.id));
  }

  Future<void> _addPlaceToDay(Place place, List<ItineraryDay> days) async {
    if (days.isEmpty) {
      _showMessage('일정표 탭에서 일차를 먼저 추가해 주세요.');
      return;
    }
    final day = await showDialog<ItineraryDay>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${place.name}을(를) 넣을 날'),
        children: [
          for (final day in days)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(day),
              child: Text('${day.dayNumber}일차'),
            ),
        ],
      ),
    );
    if (day == null) return;
    final ok = await _run(
      () => _service.addItem(dayId: day.id, placeId: place.id),
    );
    if (ok && mounted) {
      setState(() => _selectedDayId = day.id);
      _showMessage('${day.dayNumber}일차에 ${place.name}을(를) 넣었어요.');
    }
  }

  // 일정 -----------------------------------------------------------------

  Future<void> _addDay(List<ItineraryDay> days) async {
    final next = days.isEmpty ? 1 : days.last.dayNumber + 1;
    final ok = await _run(
      () => _service.addDay(roomId: widget.roomId, dayNumber: next),
    );
    if (ok && mounted) setState(() => _wantDayNumber = next);
  }

  Future<void> _deleteDay(ItineraryDay day) async {
    final ok = await _confirm('${day.dayNumber}일차 삭제', '이날 일정도 함께 지워져요.');
    if (!ok) return;
    if (await _run(() => _service.deleteDay(day.id)) && mounted) {
      setState(() => _selectedDayId = null);
    }
  }

  Future<void> _pickPlaceForDay(ItineraryDay day, List<Place> places) async {
    if (places.isEmpty) {
      _showMessage('장소 후보함에 장소를 먼저 올려 주세요.');
      return;
    }
    final place = await showModalBottomSheet<Place>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '${day.dayNumber}일차에 넣을 장소',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final place in places)
            ListTile(
              leading: Icon(place.category.icon),
              title: Text(place.name),
              subtitle: place.address == null ? null : Text(place.address!),
              onTap: () => Navigator.of(context).pop(place),
            ),
        ],
      ),
    );
    if (place == null) return;
    await _run(() => _service.addItem(dayId: day.id, placeId: place.id));
  }

  Future<void> _editItem(ItineraryItem item, Place? place) async {
    final result = await showDialog<_ItemEdit>(
      context: context,
      builder: (_) =>
          _EditItemDialog(item: item, placeName: place?.name ?? '장소'),
    );
    if (result == null) return;
    await _run(
      () => _service.updateItem(
        itemId: item.id,
        visitTime: result.visitTime,
        memo: result.memo,
      ),
    );
  }

  Future<void> _reorder(
    String dayId,
    List<ItineraryItem> current,
    int from,
    int to,
  ) async {
    final ids = current.map((item) => item.id).toList();
    ids.insert(to, ids.removeAt(from));
    setState(() => _pendingOrder[dayId] = ids);
    final ok = await _run(
      () => _service.reorder(dayId: dayId, orderedIds: ids),
    );
    if (!ok && mounted) setState(() => _pendingOrder.remove(dayId));
  }

  /// 서버 순서에 아직 반영되지 않은 내 변경이 있으면 그 순서로 보여준다.
  List<ItineraryItem> _ordered(String dayId, List<ItineraryItem> fromServer) {
    final pending = _pendingOrder[dayId];
    if (pending == null) return fromServer;
    final serverIds = fromServer.map((item) => item.id).toList();
    final sameItems =
        serverIds.length == pending.length &&
        serverIds.toSet().containsAll(pending);
    if (!sameItems) return fromServer;
    final byId = {for (final item in fromServer) item.id: item};
    return [for (final id in pending) byId[id]!];
  }

  Future<bool> _confirm(String title, String content) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    final places = ref.watch(roomPlacesProvider(roomId)).value ?? const [];
    final votes = ref.watch(roomPlaceVotesProvider(roomId)).value ?? const [];
    final days = ref.watch(roomDaysProvider(roomId)).value ?? const [];
    final items =
        ref.watch(roomItineraryItemsProvider(roomId)).value ?? const [];
    final members = ref.watch(roomMembersProvider(roomId)).value ?? const [];
    final myId = ref.watch(currentUserIdProvider);

    final nicknames = {for (final m in members) m.userId: m.nickname};
    final likes = tallyPlaceVotes(votes, myId);
    final sortedPlaces = sortPlacesByLikes(places, likes);
    final placesById = {for (final p in places) p.id: p};
    final itemsByDay = groupItemsByDay(items);

    // 남은 항목이 서버 순서와 같아지면 임시 순서를 버린다.
    _pendingOrder.removeWhere((dayId, pending) {
      final server =
          itemsByDay[dayId]?.map((item) => item.id).toList() ?? const [];
      return server.length == pending.length &&
          Iterable.generate(server.length)
              .every((i) => server[i] == pending[i]);
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('장소·일정'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '일정표'),
              Tab(text: '장소 후보함'),
            ],
          ),
        ),
        floatingActionButton: ChatButton(roomId: roomId),
        body: TabBarView(
          children: [
            _buildSchedule(days, itemsByDay, placesById, sortedPlaces),
            _buildPlaces(sortedPlaces, likes, days, nicknames, myId),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedule(
    List<ItineraryDay> days,
    Map<String, List<ItineraryItem>> itemsByDay,
    Map<String, Place> placesById,
    List<Place> sortedPlaces,
  ) {
    final wanted = days.where((d) => d.dayNumber == _wantDayNumber).firstOrNull;
    if (wanted != null) {
      _selectedDayId = wanted.id;
      _wantDayNumber = null;
    }
    final selected =
        days.where((d) => d.id == _selectedDayId).firstOrNull ??
        days.firstOrNull;
    final dayItems = selected == null
        ? const <ItineraryItem>[]
        : _ordered(selected.id, itemsByDay[selected.id] ?? const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final day in days)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${day.dayNumber}일차'),
                    selected: day.id == selected?.id,
                    onSelected: (_) => setState(() => _selectedDayId = day.id),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('일차 추가'),
                onPressed: () => _addDay(days),
              ),
            ],
          ),
        ),
        if (selected == null)
          const Expanded(child: Center(child: Text('일차를 추가하고 장소를 넣어 보세요.')))
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dayItems.length > 1 ? '길게 눌러 끌면 순서를 바꿀 수 있어요.' : '',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (selected.id == days.last.id)
                  TextButton(
                    onPressed: () => _deleteDay(selected),
                    child: Text('${selected.dayNumber}일차 삭제'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: dayItems.isEmpty
                ? const Center(child: Text('아직 넣은 장소가 없어요.'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: dayItems.length,
                    onReorderItem: (from, to) =>
                        _reorder(selected.id, dayItems, from, to),
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      final place = placesById[item.placeId];
                      final time = item.visitTime == null
                          ? '시간 미정'
                          : formatVisitTime(item.visitTime!);
                      return Card(
                        key: ValueKey(item.id),
                        child: ListTile(
                          leading: Icon(place?.category.icon ?? Icons.place),
                          title: Text(place?.name ?? '지워진 장소'),
                          subtitle: Text(
                            item.memo == null ? time : '$time · ${item.memo}',
                          ),
                          onTap: () => _editItem(item, place),
                          trailing: IconButton(
                            tooltip: '일정에서 빼기',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                _run(() => _service.deleteItem(item.id)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 88, 16),
            child: FilledButton.icon(
              onPressed: () => _pickPlaceForDay(selected, sortedPlaces),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text('${selected.dayNumber}일차에 장소 넣기'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaces(
    List<Place> places,
    Map<String, PlaceLikes> likes,
    List<ItineraryDay> days,
    Map<String, String> nicknames,
    String? myId,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        const Text('가고 싶은 장소를 올리고 좋아요를 눌러 주세요. 좋아요가 많은 순서로 보여요.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addPlace,
          icon: const Icon(Icons.add),
          label: const Text('장소 올리기'),
        ),
        const SizedBox(height: 12),
        if (places.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('아직 올라온 장소가 없어요.', textAlign: TextAlign.center),
          ),
        for (final place in places)
          _PlaceCard(
            place: place,
            likes: likes[place.id] ?? (count: 0, mine: false),
            addedBy: nicknames[place.addedBy] ?? '알 수 없음',
            canDelete: place.addedBy == myId,
            onLike: (liked) =>
                _run(() => _service.setLike(placeId: place.id, liked: liked)),
            onAddToDay: () => _addPlaceToDay(place, days),
            onDelete: () => _deletePlace(place),
          ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.likes,
    required this.addedBy,
    required this.canDelete,
    required this.onLike,
    required this.onAddToDay,
    required this.onDelete,
  });

  final Place place;
  final PlaceLikes likes;
  final String addedBy;
  final bool canDelete;
  final ValueChanged<bool> onLike;
  final VoidCallback onAddToDay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = [
      place.category.label,
      if (place.address != null) place.address!,
      if (place.memo != null) place.memo!,
      '$addedBy 님',
    ].join(' · ');

    return Card(
      child: ListTile(
        leading: Icon(place.category.icon),
        title: Text(place.name),
        subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => onLike(!likes.mine),
              icon: Icon(likes.mine ? Icons.favorite : Icons.favorite_border),
              label: Text('${likes.count}'),
            ),
            PopupMenuButton<String>(
              tooltip: '더보기',
              onSelected: (value) =>
                  value == 'delete' ? onDelete() : onAddToDay(),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'add', child: Text('일정에 넣기')),
                if (canDelete)
                  const PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _PlaceInput = ({
  String name,
  PlaceCategory category,
  String address,
  String memo,
});

class _AddPlaceDialog extends StatefulWidget {
  const _AddPlaceDialog();

  @override
  State<_AddPlaceDialog> createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<_AddPlaceDialog> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _memo = TextEditingController();
  var _category = PlaceCategory.sight;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('장소 올리기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('place-name'),
              controller: _name,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: '장소 이름',
                hintText: '예: 성산일출봉',
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final category in PlaceCategory.values)
                  ChoiceChip(
                    avatar: Icon(category.icon, size: 16),
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            TextField(
              controller: _address,
              maxLength: 200,
              decoration: const InputDecoration(labelText: '주소 (선택)'),
            ),
            TextField(
              controller: _memo,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '예: 일출 보려면 6시 전 도착',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop((
              name: name,
              category: _category,
              address: _address.text.trim(),
              memo: _memo.text.trim(),
            ));
          },
          child: const Text('올리기'),
        ),
      ],
    );
  }
}

typedef _ItemEdit = ({TimeOfDay? visitTime, String memo});

class _EditItemDialog extends StatefulWidget {
  const _EditItemDialog({required this.item, required this.placeName});

  final ItineraryItem item;
  final String placeName;

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TimeOfDay? _time = widget.item.visitTime;
  late final _memo = TextEditingController(text: widget.item.memo);

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.placeName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(_time == null ? '방문 시간 미정' : formatVisitTime(_time!)),
            onTap: _pickTime,
            trailing: _time == null
                ? null
                : IconButton(
                    tooltip: '시간 지우기',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _time = null),
                  ),
          ),
          TextField(
            key: const Key('item-memo'),
            controller: _memo,
            maxLength: 200,
            decoration: const InputDecoration(labelText: '메모'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context)
                  .pop((visitTime: _time, memo: _memo.text.trim())),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
