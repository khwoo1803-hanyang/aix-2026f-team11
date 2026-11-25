import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/app/screens/home/room_onboarding_screen.dart';
import 'package:travel_planner/app/travel_theme.dart';
import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/providers/room_provider.dart';
import 'package:travel_planner/services/room_service.dart';

class _RoomService extends Fake implements RoomService {
  final requests = <(String, int?)>[];

  @override
  Future<TravelRoom> createRoom({
    required String name,
    int? expectedMembers,
  }) async {
    requests.add((name, expectedMembers));
    return TravelRoom(
      id: 'room',
      name: name,
      inviteCode: 'K7Q2MX',
      ownerId: 'owner',
      createdAt: DateTime(2026),
      expectedMembers: expectedMembers,
    );
  }
}

Future<void> _open(WidgetTester tester, _RoomService rooms) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [roomServiceProvider.overrideWithValue(rooms)],
      child: MaterialApp(
        theme: travelTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<TravelRoom>(
                  MaterialPageRoute(
                    builder: (_) => const RoomOnboardingScreen(),
                  ),
                );
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('생성됨: ${result.name}')),
                  );
                }
              },
              child: const Text('온보딩 열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, '온보딩 열기');
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('여행지를 고르고 동행 인원을 설정하면 실제 초대 코드가 표시된다', (tester) async {
    final rooms = _RoomService();
    await _open(tester, rooms);
    await _tap(tester, '강릉');
    await _tap(tester, '선택한 곳으로 계속');
    await tester.tap(find.byTooltip('예상 인원 늘리기'));
    await tester.pump();
    await _tap(tester, '친구 초대하기');

    expect(rooms.requests, [('강릉 여행', 4)]);
    expect(find.text('친구를 불러 모아요'), findsOneWidget);
    expect(find.text('K7Q2MX'), findsOneWidget);
    await _tap(tester, '여행방으로 가기');
    expect(find.text('생성됨: 강릉 여행'), findsOneWidget);
  });

  testWidgets('목적지를 건너뛰고 혼자 가면 방 이름을 검증한 뒤 바로 입장한다', (tester) async {
    final rooms = _RoomService();
    await _open(tester, rooms);
    await _tap(tester, '아직 못 정했어요 · 같이 정할게요');
    await _tap(tester, '혼자 가요');
    final create = find.widgetWithText(FilledButton, '여행방 만들기');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(rooms.requests, isEmpty);
    expect(find.text('여행방 이름을 입력해 주세요.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '주말 여행');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(rooms.requests, [('주말 여행', 1)]);
    expect(find.text('생성됨: 주말 여행'), findsOneWidget);
  });
}
