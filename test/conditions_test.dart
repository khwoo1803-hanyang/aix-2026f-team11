import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/screens/conditions/conditions_screen.dart';
import 'package:travel_planner/models/chat_message.dart';
import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/models/trip_condition.dart';
import 'package:travel_planner/providers/chat_provider.dart';
import 'package:travel_planner/providers/condition_provider.dart';
import 'package:travel_planner/providers/room_provider.dart';
import 'package:travel_planner/services/condition_service.dart';

class _FakeConditionService implements ConditionService {
  _FakeConditionService({this.result = (found: 2, kept: 0), this.error});

  final ExtractResult result;
  final ConditionException? error;
  final calls = <String>[];
  final saved = <(ConditionField, String)>[];
  final cleared = <ConditionField>[];

  @override
  Future<ExtractResult> extractFromChat(String roomId) async {
    calls.add(roomId);
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<void> save({
    required String roomId,
    required ConditionField field,
    required String value,
  }) async {
    saved.add((field, value));
  }

  @override
  Future<void> clear({
    required String roomId,
    required ConditionField field,
  }) async {
    cleared.add(field);
  }

  @override
  Stream<List<TripCondition>> watchConditions(String roomId) =>
      const Stream.empty();
}

Widget _screen(_FakeConditionService service, List<TripCondition> conditions) {
  return ProviderScope(
    overrides: [
      conditionServiceProvider.overrideWithValue(service),
      roomConditionsProvider('r')
          .overrideWith((ref) => Stream.value(conditions)),
      roomMessagesProvider('r').overrideWith(
        (ref) => Stream.value([
          ChatMessage(
            id: 7,
            roomId: 'r',
            userId: 'm1',
            content: '8월 둘째 주 2박 3일 어때',
            createdAt: DateTime(2026, 11, 18),
          ),
        ]),
      ),
      roomMembersProvider('r').overrideWith(
        (ref) async => const [
          RoomMember(userId: 'm1', nickname: '영욱', isOwner: false),
          RoomMember(userId: 'm2', nickname: '현우', isOwner: true),
        ],
      ),
    ],
    child: const MaterialApp(home: ConditionsScreen(roomId: 'r')),
  );
}

void main() {
  test('알 수 없는 항목은 건너뛴다', () {
    expect(TripCondition.fromJson({'field': 'weather', 'value': '맑음'}), isNull);
    final condition = TripCondition.fromJson({
      'field': 'budget',
      'value': '1인 30만 원',
      'source_message_id': 3,
      'inferred': true,
      'manual': false,
    })!;
    expect(condition.field, ConditionField.budget);
    expect(condition.sourceMessageId, 3);
    expect(condition.inferred, isTrue);
    expect(condition.manual, isFalse);
  });

  testWidgets('조건을 출처, AI 추측, 직접 입력 표시와 함께 보여준다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _screen(_FakeConditionService(), const [
        TripCondition(
          field: ConditionField.dates,
          value: '8월 둘째 주, 2박 3일',
          sourceMessageId: 7,
        ),
        TripCondition(
          field: ConditionField.transport,
          value: '대중교통',
          inferred: true,
        ),
        TripCondition(
          field: ConditionField.budget,
          value: '1인 25만 원',
          manual: true,
          updatedBy: 'm2',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('8월 둘째 주, 2박 3일'), findsOneWidget);
    expect(find.text('출처 · 영욱: 8월 둘째 주 2박 3일 어때'), findsOneWidget);
    expect(find.text('AI 추측'), findsOneWidget);
    expect(find.text('현우 님이 직접 입력'), findsOneWidget);
    expect(find.text('아직 없음 · 눌러서 입력'), findsNWidgets(3));
  });

  testWidgets('정리 버튼을 누르면 AI를 부르고 결과를 알려준다', (tester) async {
    final service = _FakeConditionService(result: (found: 3, kept: 1));
    await tester.pumpWidget(_screen(service, const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('채팅에서 조건 정리'));
    await tester.pumpAndSettle();

    expect(service.calls, ['r']);
    expect(find.text('조건 3개를 정리했어요. 직접 고친 1개는 그대로 뒀어요.'), findsOneWidget);
  });

  testWidgets('AI 호출이 실패하면 안내를 보여준다', (tester) async {
    final service = _FakeConditionService(
      error: const ConditionException('AI가 응답하지 않았어요.'),
    );
    await tester.pumpWidget(_screen(service, const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('채팅에서 조건 정리'));
    await tester.pumpAndSettle();

    expect(find.text('AI가 응답하지 않았어요.'), findsOneWidget);
  });

  testWidgets('항목을 눌러 직접 입력한 값을 저장한다', (tester) async {
    final service = _FakeConditionService();
    await tester.pumpWidget(_screen(service, const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('예산'));
    await tester.pumpAndSettle();
    expect(find.text('비우기'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('condition-value')),
      '  1인 30만 원 ',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(service.saved, [(ConditionField.budget, '1인 30만 원')]);
  });

  testWidgets('빈 값은 저장하지 않고, 비우기로 항목을 지운다', (tester) async {
    final service = _FakeConditionService();
    await tester.pumpWidget(
      _screen(service, const [
        TripCondition(
          field: ConditionField.people,
          value: '4명',
          sourceMessageId: 7,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('4명'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('condition-value')), '   ');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(service.saved, isEmpty);

    await tester.tap(find.text('비우기'));
    await tester.pumpAndSettle();
    expect(service.cleared, [ConditionField.people]);
  });
}
