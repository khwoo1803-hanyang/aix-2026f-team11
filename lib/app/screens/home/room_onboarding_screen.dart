import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/travel_room.dart';
import '../../../providers/room_provider.dart';
import '../../travel_theme.dart';
import '../room/invite_code_card.dart';

class RoomOnboardingScreen extends ConsumerStatefulWidget {
  const RoomOnboardingScreen({super.key});

  @override
  ConsumerState<RoomOnboardingScreen> createState() => _RoomOnboardingState();
}

class _RoomOnboardingState extends ConsumerState<RoomOnboardingScreen> {
  static const _places = ['제주', '부산', '강릉', '경주', '여수', '전주'];
  static const _steps = ['여행지', '동행', '친구 초대'];
  final _destination = TextEditingController();
  final _roomName = TextEditingController();
  final _form = GlobalKey<FormState>();
  int _step = 0;
  bool _withFriends = true;
  int _expected = 3;
  bool _creating = false;
  String? _error;
  TravelRoom? _createdRoom;

  @override
  void dispose() {
    _destination.dispose();
    _roomName.dispose();
    super.dispose();
  }

  void _chooseDestination(String destination) {
    FocusScope.of(context).unfocus();
    _destination.text = destination;
    _roomName.text = destination.isEmpty ? '' : '$destination 여행';
    setState(() => _step = 1);
  }

  Future<void> _createRoom() async {
    if (_creating || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final room = await ref
          .read(roomServiceProvider)
          .createRoom(
            name: _roomName.text.trim(),
            expectedMembers: _withFriends ? _expected : 1,
          );
      if (!mounted) return;
      ref.invalidate(myRoomsProvider);
      if (!_withFriends) {
        setState(() => _creating = false);
        Navigator.of(context).pop(room);
        return;
      }
      setState(() {
        _createdRoom = room;
        _step = 2;
        _creating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = '여행방을 만들지 못했습니다. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_creating && _step != 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_creating && _step == 1) {
          setState(() {
            _step = 0;
            _error = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_step == 2 ? '친구 초대' : '여행방 만들기')),
        body: SafeArea(
          bottom: false,
          child: TravelWidth(
            child: SingleChildScrollView(
              key: ValueKey(_step),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TravelSteps(steps: _steps, current: _step),
                  const SizedBox(height: 28),
                  ...switch (_step) {
                    0 => _destinationFields(),
                    1 => _companionFields(),
                    _ => _invitation(),
                  },
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: TravelWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: switch (_step) {
                      0 =>
                        _destination.text.trim().isEmpty
                            ? null
                            : () =>
                                  _chooseDestination(_destination.text.trim()),
                      1 => _creating ? null : _createRoom,
                      _ => () => Navigator.of(context).pop(_createdRoom),
                    },
                    child: Text(switch (_step) {
                      0 => '선택한 곳으로 계속',
                      1 when _creating => '여행방 만드는 중…',
                      1 when _withFriends => '친구 초대하기',
                      1 => '여행방 만들기',
                      _ => '여행방으로 가기',
                    }),
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _chooseDestination(''),
                      child: const Text('아직 못 정했어요 · 같이 정할게요'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _destinationFields() {
    final selected = _destination.text.trim();
    return [
      const TravelHeading(
        '어디로 떠나세요?',
        description: '가고 싶은 곳을 선택하거나 도시 이름을 직접 입력해 주세요.',
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _destination,
        maxLength: 36,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) _chooseDestination(value.trim());
        },
        decoration: const InputDecoration(
          labelText: '도시나 지역',
          hintText: '예: 강릉, 제주, 부산',
          prefixIcon: Icon(Icons.search),
          counterText: '',
        ),
      ),
      const SizedBox(height: 24),
      Text('많이 가는 곳', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final place in _places)
              SizedBox(
                width: (constraints.maxWidth - 16) / 3,
                child: Semantics(
                  selected: place == selected,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _destination.text = place),
                    style: place == selected
                        ? OutlinedButton.styleFrom(
                            backgroundColor: travelTint,
                            foregroundColor: travelBlue,
                            side: const BorderSide(color: travelBlue, width: 2),
                          )
                        : null,
                    child: Text(place),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (selected.isNotEmpty) ...[
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tileColor: travelGray,
          leading: const Icon(Icons.place_outlined, color: travelBlue),
          title: Text(selected),
          trailing: const Text('선택됨', style: TextStyle(color: travelBlue)),
        ),
      ],
    ];
  }

  List<Widget> _companionFields() => [
    const TravelHeading(
      '누구와 가나요?',
      description: '함께 떠난다면 초대 코드로 친구를 모을 수 있어요.',
    ),
    const SizedBox(height: 20),
    _companionCard(
      forFriends: false,
      title: '혼자 가요',
      description: '바로 여행방으로 이동해요.',
      icon: Icons.person_outline,
    ),
    const SizedBox(height: 10),
    _companionCard(
      forFriends: true,
      title: '친구랑 가요',
      description: '친구를 초대해서 같이 정해요.',
      icon: Icons.group_outlined,
    ),
    const SizedBox(height: 20),
    Form(
      key: _form,
      child: TextFormField(
        controller: _roomName,
        enabled: !_creating,
        maxLength: 40,
        decoration: const InputDecoration(
          labelText: '여행방 이름',
          hintText: '예: 바다 보러 가는 주말',
        ),
        validator: (value) =>
            (value ?? '').trim().isEmpty ? '여행방 이름을 입력해 주세요.' : null,
      ),
    ),
    if (_error case final message?)
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
  ];

  Widget _companionCard({
    required bool forFriends,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _withFriends == forFriends;
    return Card(
      color: selected ? travelTint : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? travelBlue : travelLine,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            selected: selected,
            onTap: _creating
                ? null
                : () => setState(() => _withFriends = forFriends),
            leading: CircleAvatar(
              backgroundColor: selected ? travelBlue : travelGray,
              foregroundColor: selected ? Colors.white : travelMuted,
              child: Icon(icon, size: 22),
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(description),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
            ),
          ),
          if (selected && forFriends) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Expanded(child: Text('예상 인원')),
                  IconButton(
                    tooltip: '예상 인원 줄이기',
                    onPressed: _creating || _expected <= 2
                        ? null
                        : () => setState(() => _expected--),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$_expected명',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: '예상 인원 늘리기',
                    onPressed: _creating || _expected >= 20
                        ? null
                        : () => setState(() => _expected++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _invitation() => [
    const TravelHeading(
      '친구를 불러 모아요',
      description: '친구가 앱에서 초대 코드를 입력하면 이 여행방에 들어올 수 있어요.',
    ),
    const SizedBox(height: 24),
    InviteCodeCard(code: _createdRoom!.inviteCode),
  ];
}
