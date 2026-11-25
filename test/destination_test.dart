import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/screens/destination/destination_vote_screen.dart';
import 'package:travel_planner/models/destination.dart';
import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/providers/chat_provider.dart';
import 'package:travel_planner/providers/destination_provider.dart';
import 'package:travel_planner/providers/room_provider.dart';
import 'package:travel_planner/services/destination_service.dart';

class _FakeDestinationService implements DestinationService {
  final votes = <(String, VoteChoice)>[];
  final confirmed = <String>[];

  @override
  Future<void> vote({
    required String destinationId,
    required VoteChoice choice,
  }) async {
    votes.add((destinationId, choice));
  }

  @override
  Future<void> confirm(String destinationId) async => confirmed.add(destinationId);

  @override
  Future<void> addDestination({
    required String roomId,
    required String name,
    String? reason,
  }) async {}

  @override
  Stream<List<Destination>> watchDestinations(String roomId) => const Stream.empty();

  @override
  Stream<List<DestinationVote>> watchVotes(String roomId) => const Stream.empty();
}

DestinationVote _vote(String dest, String user, VoteChoice choice) =>
    DestinationVote(destinationId: dest, userId: user, choice: choice);

final _created = DateTime(2026, 11, 18);

Widget _screen({
  required String myId,
  required List<DestinationVote> votes,
  required _FakeDestinationService service,
  String? confirmedId,
}) {
  return ProviderScope(
    overrides: [
      destinationServiceProvider.overrideWithValue(service),
      currentUserIdProvider.overrideWithValue(myId),
      roomProvider('r').overrideWith(
        (ref) => Stream.value(TravelRoom(
          id: 'r',
          name: '여름 여행',
          inviteCode: 'ABCDEF',
          ownerId: 'owner',
          createdAt: _created,
          confirmedDestinationId: confirmedId,
        )),
      ),
      roomMembersProvider('r').overrideWith(
        (ref) async => const [
          RoomMember(userId: 'owner', nickname: '현우', isOwner: true),
          RoomMember(userId: 'm1', nickname: '영욱', isOwner: false),
          RoomMember(userId: 'm2', nickname: '민지', isOwner: false),
        ],
      ),
      roomDestinationsProvider('r').overrideWith(
        (ref) => Stream.value([
          Destination(
            id: 'd1',
            roomId: 'r',
            proposedBy: 'm1',
            name: '강릉',
            reason: '바다',
            createdAt: _created,
          ),
          Destination(
            id: 'd2',
            roomId: 'r',
            proposedBy: 'owner',
            name: '경주',
            createdAt: _created,
          ),
        ]),
      ),
      roomVotesProvider('r').overrideWith((ref) => Stream.value(votes)),
    ],
    child: const MaterialApp(home: DestinationVoteScreen(roomId: 'r')),
  );
}

TextButton _confirmButton(WidgetTester tester, int index) {
  return tester.widgetList<TextButton>(
    find.widgetWithText(TextButton, '이 여행지로 확정'),
  ).elementAt(index);
}

void main() {
  group('투표 집계', () {
    test('후보별 찬성·보통·반대와 내 선택을 센다', () {
      final tallies = tallyVotes([
        _vote('d1', 'a', VoteChoice.agree),
        _vote('d1', 'b', VoteChoice.disagree),
        _vote('d1', 'me', VoteChoice.agree),
        _vote('d2', 'a', VoteChoice.neutral),
      ], 'me');

      expect(tallies['d1']!.agree, 2);
      expect(tallies['d1']!.disagree, 1);
      expect(tallies['d1']!.mine, VoteChoice.agree);
      expect(tallies['d2']!.neutral, 1);
      expect(tallies['d2']!.mine, isNull);
    });

    test('찬성이 멤버 절반을 넘어야 과반이다', () {
      expect(const VoteTally(agree: 2).hasMajority(3), isTrue);
      expect(const VoteTally(agree: 1).hasMajority(2), isFalse);
      expect(const VoteTally(agree: 2).hasMajority(4), isFalse);
      expect(const VoteTally(agree: 0).hasMajority(0), isFalse);
    });
  });

  testWidgets('집계를 보여주고 누른 선택으로 투표한다', (tester) async {
    final service = _FakeDestinationService();
    await tester.pumpWidget(_screen(
      myId: 'm1',
      service: service,
      votes: [_vote('d1', 'owner', VoteChoice.agree)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('찬성 1 · 보통 0 · 반대 0'), findsOneWidget);
    expect(find.text('영욱 님 추천 · 바다'), findsOneWidget);
    expect(find.text('후보 올리기 (1/2)'), findsOneWidget);
    expect(find.text('이 여행지로 확정'), findsNothing);

    await tester.tap(find.text('반대').first);
    await tester.pump();

    expect(service.votes, [('d1', VoteChoice.disagree)]);
  });

  testWidgets('방장은 찬성이 과반인 후보만 확정할 수 있다', (tester) async {
    final service = _FakeDestinationService();
    await tester.pumpWidget(_screen(
      myId: 'owner',
      service: service,
      votes: [
        _vote('d1', 'owner', VoteChoice.agree),
        _vote('d1', 'm1', VoteChoice.agree),
        _vote('d2', 'owner', VoteChoice.agree),
      ],
    ));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester, 0).onPressed, isNotNull);
    expect(_confirmButton(tester, 1).onPressed, isNull);

    await tester.tap(find.widgetWithText(TextButton, '이 여행지로 확정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '확정'));
    await tester.pumpAndSettle();

    expect(service.confirmed, ['d1']);
  });

  testWidgets('확정된 여행지를 위에 표시한다', (tester) async {
    await tester.pumpWidget(_screen(
      myId: 'm2',
      service: _FakeDestinationService(),
      votes: const [],
      confirmedId: 'd2',
    ));
    await tester.pumpAndSettle();

    expect(find.text('확정된 여행지: 경주'), findsOneWidget);
    expect(find.text('확정'), findsOneWidget);
  });
}
