import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/trip_condition.dart';
import '../../../providers/condition_provider.dart';
import '../../../providers/destination_provider.dart';
import '../../../providers/room_provider.dart';
import '../chat/chat_sheet.dart';
import '../conditions/conditions_screen.dart';
import '../destination/destination_vote_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../recommendation/recommendation_screen.dart';

/// 여행방 대시보드. 초대 코드, 여행 조건, AI 추천, 여행지 투표, 장소·일정, 멤버 목록을 보여준다.
class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  String _voteSummary(WidgetRef ref, String? confirmedId) {
    final list = ref.watch(roomDestinationsProvider(roomId)).value;
    if (list == null) return '후보를 불러오는 중';
    for (final destination in list) {
      if (destination.id == confirmedId) return '확정: ${destination.name}';
    }
    return list.isEmpty ? '아직 후보가 없어요' : '후보 ${list.length}개 투표 중';
  }

  String _conditionSummary(WidgetRef ref) {
    final list = ref.watch(roomConditionsProvider(roomId)).value;
    if (list == null) return '조건을 불러오는 중';
    if (list.isEmpty) return '채팅에서 조건을 정리해 보세요';
    return '${ConditionField.values.length}개 중 ${list.length}개 정리됨';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId));
    final members = ref.watch(roomMembersProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: Text(room.value?.name ?? '여행방')),
      floatingActionButton: ChatButton(roomId: roomId),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(roomMembersProvider(roomId).future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            room.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('여행방 정보를 불러오지 못했습니다.'),
              data: (data) => Card(
                child: ListTile(
                  title: const Text('초대 코드'),
                  subtitle: Text(
                    data.inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  trailing: IconButton(
                    tooltip: '복사',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드를 복사했습니다.')),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('여행 조건'),
                subtitle: Text(_conditionSummary(ref)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConditionsScreen(roomId: roomId),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI 여행지 추천'),
                subtitle: const Text('조건에 맞는 국내 여행지 3곳'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecommendationScreen(roomId: roomId),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.how_to_vote_outlined),
                title: const Text('여행지 투표'),
                subtitle: Text(_voteSummary(ref, room.value?.confirmedDestinationId)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DestinationVoteScreen(roomId: roomId),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('장소·일정'),
                subtitle: const Text('장소 후보함과 일차별 일정표'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ItineraryScreen(roomId: roomId),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('멤버', style: Theme.of(context).textTheme.titleMedium),
            members.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('멤버 목록을 불러오지 못했습니다.'),
              data: (list) => Column(
                children: [
                  for (final member in list)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(member.nickname),
                      trailing: member.isOwner ? const Text('방장') : null,
                    ),
                  Text('${list.length}명 참여 중'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
