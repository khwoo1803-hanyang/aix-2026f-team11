import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/screens/itinerary/itinerary_screen.dart';
import 'package:travel_planner/models/itinerary.dart';
import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/providers/chat_provider.dart';
import 'package:travel_planner/providers/itinerary_provider.dart';
import 'package:travel_planner/providers/room_provider.dart';
import 'package:travel_planner/services/itinerary_service.dart';

class _FakeItineraryService implements ItineraryService {
  final calls = <String>[];
  List<String>? reordered;
  ItineraryException? reorderError;

  @override
  Future<void> addPlace({
    required String roomId,
    required String name,
    required PlaceCategory category,
    String? address,
    String? memo,
  }) async {
    calls.add('addPlace $name ${category.value}');
  }

  @override
  Future<void> setLike({required String placeId, required bool liked}) async {
    calls.add('like $placeId $liked');
  }

  @override
  Future<void> addDay({required String roomId, required int dayNumber}) async {
    calls.add('addDay $dayNumber');
  }

  @override
  Future<void> addItem({
    required String dayId,
    required String placeId,
    TimeOfDay? visitTime,
  }) async {
    calls.add('addItem $dayId $placeId');
  }

  @override
  Future<void> reorder({
    required String dayId,
    required List<String> orderedIds,
  }) async {
    if (reorderError != null) throw reorderError!;
    reordered = orderedIds;
  }

  @override
  Future<void> deleteItem(String itemId) async {
    calls.add('deleteItem $itemId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Place _place(
  String id,
  String name, {
  String by = 'me',
  PlaceCategory category = PlaceCategory.sight,
  int order = 0,
}) => Place(
  id: id,
  roomId: 'r',
  addedBy: by,
  name: name,
  category: category,
  createdAt: DateTime(2026, 11, 25, 9, order),
);

final _places = [
  _place('p1', '성산일출봉'),
  _place('p2', '흑돼지 거리', by: 'friend', category: PlaceCategory.food, order: 1),
  _place('p3', '카페 델문도', by: 'friend', category: PlaceCategory.cafe, order: 2),
];

const _days = [
  ItineraryDay(id: 'd1', dayNumber: 1),
  ItineraryDay(id: 'd2', dayNumber: 2),
];

const _items = [
  ItineraryItem(
    id: 'i2',
    dayId: 'd1',
    placeId: 'p2',
    position: 1,
    visitTime: TimeOfDay(hour: 12, minute: 30),
  ),
  ItineraryItem(
    id: 'i1',
    dayId: 'd1',
    placeId: 'p1',
    position: 0,
    visitTime: TimeOfDay(hour: 6, minute: 0),
    memo: '일출',
  ),
  ItineraryItem(id: 'i3', dayId: 'd1', placeId: 'p3', position: 2),
  ItineraryItem(id: 'i4', dayId: 'd2', placeId: 'p3', position: 0),
];

Widget _screen(
  _FakeItineraryService service, {
  List<ItineraryDay> days = _days,
  List<PlaceVote> votes = const [],
}) {
  return ProviderScope(
    overrides: [
      itineraryServiceProvider.overrideWithValue(service),
      roomPlacesProvider('r').overrideWith((ref) => Stream.value(_places)),
      roomPlaceVotesProvider('r').overrideWith((ref) => Stream.value(votes)),
      roomDaysProvider('r').overrideWith((ref) => Stream.value(days)),
      roomItineraryItemsProvider('r')
          .overrideWith((ref) => Stream.value(_items)),
      roomMembersProvider('r').overrideWith(
        (ref) async => const [
          RoomMember(userId: 'me', nickname: '현우', isOwner: true),
          RoomMember(userId: 'friend', nickname: '영욱', isOwner: false),
        ],
      ),
      currentUserIdProvider.overrideWithValue('me'),
    ],
    child: const MaterialApp(home: ItineraryScreen(roomId: 'r')),
  );
}

List<String> _visibleTitles(WidgetTester tester) => tester
    .widgetList<ListTile>(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.byType(ListTile),
      ),
    )
    .map((tile) => (tile.title! as Text).data!)
    .toList();

void main() {
  test('좋아요를 세고 많은 순으로 정렬한다', () {
    final likes = tallyPlaceVotes(const [
      PlaceVote(placeId: 'p3', userId: 'me'),
      PlaceVote(placeId: 'p3', userId: 'friend'),
      PlaceVote(placeId: 'p2', userId: 'friend'),
    ], 'me');
    expect(likes['p3'], (count: 2, mine: true));
    expect(likes['p2'], (count: 1, mine: false));
    expect(sortPlacesByLikes(_places, likes).map((p) => p.id), [
      'p3',
      'p2',
      'p1',
    ]);
  });

  test('일차별로 순서대로 묶고 시간을 읽는다', () {
    final grouped = groupItemsByDay(_items);
    expect(grouped['d1']!.map((i) => i.id), ['i1', 'i2', 'i3']);
    expect(grouped['d2']!.map((i) => i.id), ['i4']);
    expect(parseVisitTime('09:05:00'), const TimeOfDay(hour: 9, minute: 5));
    expect(parseVisitTime(null), isNull);
    expect(formatVisitTime(const TimeOfDay(hour: 6, minute: 0)), '06:00');
  });

  test('서버 오류를 한국어 안내로 바꾼다', () {
    expect(
      describeItineraryError('P0001', 'order_out_of_date').message,
      contains('다른 멤버'),
    );
    expect(
      describeItineraryError('23505', 'duplicate').message,
      contains('이미 있는'),
    );
  });

  testWidgets('선택한 일차의 일정을 순서와 시간대로 보여준다', (tester) async {
    await tester.pumpWidget(_screen(_FakeItineraryService()));
    await tester.pumpAndSettle();

    expect(find.text('1일차'), findsOneWidget);
    expect(find.text('2일차'), findsOneWidget);
    expect(_visibleTitles(tester), ['성산일출봉', '흑돼지 거리', '카페 델문도']);
    expect(find.text('06:00 · 일출'), findsOneWidget);
    expect(find.text('시간 미정'), findsOneWidget);
    // 마지막 일차만 지울 수 있다.
    expect(find.text('1일차 삭제'), findsNothing);

    await tester.tap(find.text('2일차'));
    await tester.pumpAndSettle();
    expect(_visibleTitles(tester), ['카페 델문도']);
    expect(find.text('2일차 삭제'), findsOneWidget);
  });

  testWidgets('순서를 바꾸면 바로 보이고 서버에 새 순서를 보낸다', (tester) async {
    final service = _FakeItineraryService();
    await tester.pumpWidget(_screen(service));
    await tester.pumpAndSettle();

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 2);
    await tester.pumpAndSettle();

    expect(service.reordered, ['i2', 'i3', 'i1']);
    expect(_visibleTitles(tester), ['흑돼지 거리', '카페 델문도', '성산일출봉']);
  });

  testWidgets('순서 바꾸기가 실패하면 원래 순서로 돌리고 안내한다', (tester) async {
    final service = _FakeItineraryService()
      ..reorderError = const ItineraryException('다른 멤버가 일정을 바꿨어요.');
    await tester.pumpWidget(_screen(service));
    await tester.pumpAndSettle();

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 2);
    await tester.pumpAndSettle();

    expect(_visibleTitles(tester), ['성산일출봉', '흑돼지 거리', '카페 델문도']);
    expect(find.text('다른 멤버가 일정을 바꿨어요.'), findsOneWidget);
  });

  testWidgets('일차를 추가하면 다음 번호로 만든다', (tester) async {
    final service = _FakeItineraryService();
    await tester.pumpWidget(_screen(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('일차 추가'));
    await tester.pumpAndSettle();
    expect(service.calls, ['addDay 3']);
  });

  testWidgets('일차가 없으면 추가하라고 안내한다', (tester) async {
    await tester.pumpWidget(_screen(_FakeItineraryService(), days: const []));
    await tester.pumpAndSettle();

    expect(find.text('일차를 추가하고 장소를 넣어 보세요.'), findsOneWidget);
  });

  testWidgets('장소 후보함에서 좋아요 순으로 보고 좋아요를 누른다', (tester) async {
    final service = _FakeItineraryService();
    await tester.pumpWidget(
      _screen(
        service,
        votes: const [PlaceVote(placeId: 'p2', userId: 'friend')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('장소 후보함'));
    await tester.pumpAndSettle();

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data!)
        .toList();
    expect(titles, ['흑돼지 거리', '성산일출봉', '카페 델문도']);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(service.calls, ['like p2 true']);
  });

  testWidgets('장소를 올리고 일정에 넣는다', (tester) async {
    final service = _FakeItineraryService();
    await tester.pumpWidget(_screen(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장소 후보함'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장소 올리기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place-name')), '우도');
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();
    expect(service.calls, ['addPlace 우도 sight']);

    await tester.tap(find.byTooltip('더보기').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('일정에 넣기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2일차').last);
    await tester.pumpAndSettle();
    expect(service.calls.last, 'addItem d2 p1');
  });

  testWidgets('내가 올린 장소만 삭제 메뉴가 보인다', (tester) async {
    await tester.pumpWidget(_screen(_FakeItineraryService()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장소 후보함'));
    await tester.pumpAndSettle();

    // 첫 번째는 내가 올린 성산일출봉
    await tester.tap(find.byTooltip('더보기').first);
    await tester.pumpAndSettle();
    expect(find.text('삭제'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기').last);
    await tester.pumpAndSettle();
    expect(find.text('삭제'), findsNothing);
  });
}
