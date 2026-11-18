import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/app/screens/room/travel_conditions_screen.dart';
import 'package:travel_planner/models/travel_conditions.dart';
import 'package:travel_planner/providers/travel_conditions_provider.dart';
import 'package:travel_planner/services/travel_conditions_service.dart';

class _FakeTravelConditionsService implements TravelConditionsService {
  final saves = <(String, TravelConditions)>[];
  bool hasConflict = false;

  @override
  Future<TravelConditions> fetch(String roomId) async =>
      const TravelConditions(departure: '서울', travelerCount: 3, revision: 2);

  @override
  Future<void> save(String roomId, TravelConditions conditions) async {
    if (hasConflict) throw const TravelConditionsConflict();
    saves.add((roomId, conditions));
  }
}

Future<void> _openScreen(
  WidgetTester tester,
  _FakeTravelConditionsService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [travelConditionsServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TravelConditionsScreen(roomId: 'room'),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, '저장');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('입력 범위를 확인하고 읽은 버전으로 여행 조건을 저장한다', (tester) async {
    final service = _FakeTravelConditionsService();
    await _openScreen(tester, service);
    final travelers = find.widgetWithText(TextFormField, '여행 인원');
    expect(find.text('서울'), findsOneWidget);

    await tester.enterText(travelers, '0');
    await _tapSave(tester);
    expect(service.saves, isEmpty);

    await tester.ensureVisible(travelers);
    await tester.enterText(travelers, '4');
    await _tapSave(tester);
    final (roomId, saved) = service.saves.single;
    expect(roomId, 'room');
    expect(saved.travelerCount, 4);
    expect(saved.revision, 2);
    expect(find.text('여행 조건을 저장했습니다.'), findsOneWidget);
  });

  testWidgets('저장 충돌 시 수정 중인 값을 유지한다', (tester) async {
    final service = _FakeTravelConditionsService()..hasConflict = true;
    await _openScreen(tester, service);
    final departure = find.widgetWithText(TextFormField, '출발지');
    await tester.enterText(departure, '수원');
    await _tapSave(tester);

    expect(find.textContaining('다른 멤버가 먼저 저장했습니다'), findsOneWidget);
    await tester.ensureVisible(departure);
    expect(find.text('수원'), findsOneWidget);
  });
}
