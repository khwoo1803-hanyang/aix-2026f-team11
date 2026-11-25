import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/screens/recommendation/recommendation_screen.dart';
import 'package:travel_planner/models/destination.dart';
import 'package:travel_planner/models/recommendation.dart';
import 'package:travel_planner/models/trip_condition.dart';
import 'package:travel_planner/providers/condition_provider.dart';
import 'package:travel_planner/providers/destination_provider.dart';
import 'package:travel_planner/providers/recommendation_provider.dart';
import 'package:travel_planner/services/destination_service.dart';
import 'package:travel_planner/services/recommendation_service.dart';

class _FakeRecommendationService implements RecommendationService {
  _FakeRecommendationService({this.error});

  final RecommendationException? error;
  final calls = <String>[];

  @override
  Future<int> request(String roomId) async {
    calls.add(roomId);
    if (error != null) throw error!;
    return 3;
  }

  @override
  Stream<List<Recommendation>> watchRecommendations(String roomId) =>
      const Stream.empty();
}

class _FakeDestinationService implements DestinationService {
  final added = <(String, String?)>[];

  @override
  Future<void> addDestination({
    required String roomId,
    required String name,
    String? reason,
  }) async {
    added.add((name, reason));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Recommendation _rec(String batch, int rank, String name, DateTime at) =>
    Recommendation(
      id: '$batch-$rank',
      batchId: batch,
      rank: rank,
      name: name,
      reason: '$name 추천 이유',
      createdAt: at,
    );

final _gangneung = Recommendation(
  id: 'a',
  batchId: 'b1',
  rank: 1,
  name: '강릉',
  region: '강원',
  reason: '서울에서 KTX로 2시간 안팎이고 바다와 맛집이 많아요.',
  matches: const [
    ConditionMatch(
      field: ConditionField.departure,
      status: MatchStatus.match,
      note: 'KTX 직통',
    ),
    ConditionMatch(
      field: ConditionField.budget,
      status: MatchStatus.partial,
      note: '성수기 숙박비',
    ),
  ],
  caution: '성수기 숙박 요금을 확인하세요.',
  createdAt: DateTime(2026, 11, 25),
);

final _yeosu = Recommendation(
  id: 'b',
  batchId: 'b1',
  rank: 2,
  name: '여수',
  reason: '밤바다와 해산물이 유명해요.',
  createdAt: DateTime(2026, 11, 25),
);

Widget _screen({
  required RecommendationService service,
  required DestinationService destinations,
  List<TripCondition> conditions = const [
    TripCondition(field: ConditionField.departure, value: '서울'),
  ],
  List<Recommendation>? recommendations,
  List<Destination> candidates = const [],
}) {
  return ProviderScope(
    overrides: [
      recommendationServiceProvider.overrideWithValue(service),
      destinationServiceProvider.overrideWithValue(destinations),
      roomConditionsProvider('r')
          .overrideWith((ref) => Stream.value(conditions)),
      roomRecommendationsProvider('r').overrideWith(
        (ref) => Stream.value(recommendations ?? [_gangneung, _yeosu]),
      ),
      roomDestinationsProvider('r')
          .overrideWith((ref) => Stream.value(candidates)),
    ],
    child: const MaterialApp(home: RecommendationScreen(roomId: 'r')),
  );
}

void main() {
  test('조건별 일치 여부를 읽고 알 수 없는 값은 건너뛴다', () {
    final item = Recommendation.fromJson({
      'id': 'x',
      'batch_id': 'b',
      'rank': 1,
      'name': '경주',
      'region': '경북',
      'reason': '역사 유적',
      'matches': [
        {'field': 'budget', 'status': 'match', 'note': '저렴'},
        {'field': 'weather', 'status': 'match', 'note': ''},
        {'field': 'people', 'status': 'mismatch', 'note': ''},
        'oops',
      ],
      'caution': null,
      'created_at': '2026-11-25T03:00:00Z',
    });
    expect(item.matches, hasLength(1));
    expect(item.matches.single.field, ConditionField.budget);
    expect(item.matches.single.status, MatchStatus.match);
    expect(item.caution, isNull);
  });

  test('가장 최근 추천 묶음만 순위대로 고른다', () {
    final old = DateTime(2026, 11, 24);
    final now = DateTime(2026, 11, 25);
    final result = latestBatch([
      _rec('old', 1, '부산', old),
      _rec('new', 2, '여수', now),
      _rec('new', 1, '강릉', now),
      _rec('old', 2, '제주', old),
    ]);
    expect(result.map((r) => r.name), ['강릉', '여수']);
    expect(latestBatch(const []), isEmpty);
  });

  test('서버 오류 코드를 한국어 안내로 바꾼다', () {
    expect(
      describeRecommendationError({'error': 'no_conditions'}).message,
      contains('여행 조건'),
    );
    expect(
      describeRecommendationError({
        'error': 'ai_failed',
        'reason': 'ai_no_credit',
      }).message,
      contains('준비되지 않았어요'),
    );
    expect(describeRecommendationError(null).message, contains('추천을 받지 못했어요'));
  });

  testWidgets('추천 이유, 조건 일치, 확인할 점을 보여준다', (tester) async {
    await tester.pumpWidget(
      _screen(
        service: _FakeRecommendationService(),
        destinations: _FakeDestinationService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('강릉'), findsOneWidget);
    expect(find.text('강원'), findsOneWidget);
    expect(find.textContaining('KTX로 2시간'), findsOneWidget);
    expect(find.text('출발지 맞음'), findsOneWidget);
    expect(find.text('예산 조정 필요'), findsOneWidget);
    expect(find.textContaining('확인할 점'), findsOneWidget);
    expect(find.text('여수'), findsOneWidget);
  });

  testWidgets('추천 버튼을 누르면 AI를 부르고 결과를 알려준다', (tester) async {
    final service = _FakeRecommendationService();
    await tester.pumpWidget(
      _screen(service: service, destinations: _FakeDestinationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 추천 받기'));
    await tester.pumpAndSettle();

    expect(service.calls, ['r']);
    expect(find.text('여행지 3곳을 추천받았어요.'), findsOneWidget);
  });

  testWidgets('AI 호출이 실패하면 안내를 보여준다', (tester) async {
    final service = _FakeRecommendationService(
      error: const RecommendationException('AI가 응답하지 않았어요.'),
    );
    await tester.pumpWidget(
      _screen(service: service, destinations: _FakeDestinationService()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 추천 받기'));
    await tester.pumpAndSettle();

    expect(find.text('AI가 응답하지 않았어요.'), findsOneWidget);
  });

  testWidgets('조건이 없으면 추천 버튼을 누를 수 없다', (tester) async {
    final service = _FakeRecommendationService();
    await tester.pumpWidget(
      _screen(
        service: service,
        destinations: _FakeDestinationService(),
        conditions: const [],
        recommendations: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 추천 받기'));
    await tester.pumpAndSettle();

    expect(service.calls, isEmpty);
    expect(find.textContaining('먼저 여행 조건'), findsOneWidget);
  });

  testWidgets('추천을 투표 후보로 올리고, 이미 있는 후보는 표시만 한다', (tester) async {
    final destinations = _FakeDestinationService();
    await tester.pumpWidget(
      _screen(
        service: _FakeRecommendationService(),
        destinations: destinations,
        candidates: [
          Destination(
            id: 'd1',
            roomId: 'r',
            proposedBy: 'm1',
            name: '여수',
            createdAt: DateTime(2026, 11, 25),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('후보에 있음'), findsOneWidget);
    await tester.tap(find.text('투표 후보로 올리기'));
    await tester.pumpAndSettle();

    expect(destinations.added.single.$1, '강릉');
    expect(destinations.added.single.$2, startsWith('AI 추천 · '));
    expect(find.text('강릉을(를) 투표 후보로 올렸어요.'), findsOneWidget);
  });
}
