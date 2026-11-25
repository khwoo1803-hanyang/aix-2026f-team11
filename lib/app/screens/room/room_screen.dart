import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/travel_room.dart';
import '../../../models/trip_condition.dart';
import '../../../providers/condition_provider.dart';
import '../../../providers/destination_provider.dart';
import '../../../providers/room_provider.dart';
import '../../travel_theme.dart';
import '../chat/chat_sheet.dart';
import '../conditions/conditions_screen.dart';
import '../destination/destination_vote_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../recommendation/recommendation_screen.dart';
import 'invite_code_card.dart';

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  String _voteSummary(WidgetRef ref, String? confirmedId) {
    final destinations = ref.watch(roomDestinationsProvider(roomId));
    final list = destinations.value;
    if (destinations.hasError) return '후보를 불러오지 못했어요';
    if (list == null) return '후보를 불러오는 중';
    for (final destination in list) {
      if (destination.id == confirmedId) return '확정: ${destination.name}';
    }
    return list.isEmpty ? '가고 싶은 곳을 후보로 올려요' : '후보 ${list.length}개 투표 중';
  }

  String _conditionSummary(WidgetRef ref) {
    final conditions = ref.watch(roomConditionsProvider(roomId));
    if (conditions.hasError) return '조건을 불러오지 못했어요';
    final list = conditions.value;
    if (list == null) return '조건을 불러오는 중';
    if (list.isEmpty) return '채팅에서 정리하거나 직접 입력해요';
    return '${ConditionField.values.length}개 중 ${list.length}개 정리됨';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId));
    final members = ref.watch(roomMembersProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행방'),
        actions: [
          IconButton(
            tooltip: '참여 현황 새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(roomMembersProvider(roomId)),
          ),
        ],
      ),
      floatingActionButton: ChatButton(roomId: roomId),
      body: TravelWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(roomMembersProvider(roomId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 96),
            children: [
              Text(
                room.value?.name ?? '여행방',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                members.value == null
                    ? '참여 현황'
                    : '${members.value!.length}명 참여 중',
                style: const TextStyle(color: travelMuted),
              ),
              const SizedBox(height: 16),
              members.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('멤버 목록을 불러오지 못했습니다.'),
                data: (list) => _TravelersPanel(
                  members: list,
                  expected: room.value?.expectedMembers,
                ),
              ),
              const SizedBox(height: 16),
              room.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('여행방 정보를 불러오지 못했습니다.'),
                data: (data) => InviteCodeCard(code: data.inviteCode),
              ),
              const SizedBox(height: 24),
              Text('다음 할 일', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune, color: travelBlue),
                      title: const Text('여행 조건'),
                      subtitle: Text(_conditionSummary(ref)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConditionsScreen(roomId: roomId),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.auto_awesome,
                        color: travelBlue,
                      ),
                      title: const Text('AI 여행지 추천'),
                      subtitle: const Text('조건에 맞는 국내 여행지 3곳'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecommendationScreen(roomId: roomId),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.how_to_vote_outlined,
                        color: travelBlue,
                      ),
                      title: const Text('여행지 투표'),
                      subtitle: Text(
                        _voteSummary(ref, room.value?.confirmedDestinationId),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DestinationVoteScreen(roomId: roomId),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: travelBlue,
                      ),
                      title: const Text('장소·일정'),
                      subtitle: const Text('장소 후보함과 일차별 일정표'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItineraryScreen(roomId: roomId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (members.value case final list? when list.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('참여 멤버', style: Theme.of(context).textTheme.titleLarge),
                for (final member in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: member.isOwner ? travelBlue : travelTint,
                      foregroundColor: member.isOwner
                          ? Colors.white
                          : travelBlue,
                      child: const Icon(Icons.person_outline, size: 20),
                    ),
                    title: Text(member.nickname),
                    trailing: member.isOwner ? const Text('방장') : null,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelersPanel extends StatelessWidget {
  const _TravelersPanel({required this.members, required this.expected});

  final List<RoomMember> members;
  final int? expected;

  @override
  Widget build(BuildContext context) {
    final waiting = math.max((expected ?? 0) - members.length, 0);
    final visible = members.take(3).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: travelTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.flight_takeoff, color: travelBlue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '참여 현황',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  waiting > 0 ? '$waiting명 대기 중' : '${members.length}명 참여',
                  style: const TextStyle(
                    color: travelBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (visible.isNotEmpty || waiting > 0) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, member) in visible.indexed)
                    Expanded(
                      child: _Traveler(
                        label: member.nickname,
                        color: index.isEven ? travelBlue : travelOrange,
                      ),
                    ),
                  if (visible.length < 3 && waiting > 0)
                    const Expanded(child: _Traveler(label: '초대 대기')),
                ],
              ),
            ],
            if (expected case final total? when total > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: math.min(members.length / total, 1),
                borderRadius: BorderRadius.circular(4),
                semanticsLabel: '${members.length}명 참여, 예상 $total명',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Traveler extends StatelessWidget {
  const _Traveler({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          color == null ? Icons.luggage_outlined : Icons.luggage,
          size: 50,
          color: color ?? const Color(0xFF6982BF),
        ),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
