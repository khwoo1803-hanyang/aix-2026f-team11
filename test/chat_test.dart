import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_planner/app/screens/chat/chat_sheet.dart';
import 'package:travel_planner/models/chat_message.dart';
import 'package:travel_planner/models/travel_room.dart';
import 'package:travel_planner/providers/chat_provider.dart';
import 'package:travel_planner/providers/room_provider.dart';
import 'package:travel_planner/services/chat_service.dart';

class _FakeChatService implements ChatService {
  final sent = <String>[];

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return Stream.value([
      ChatMessage(
        id: 1,
        roomId: roomId,
        userId: 'friend',
        content: '차 1대로 가자',
        createdAt: DateTime(2026, 11, 18, 9, 5),
      ),
      ChatMessage(
        id: 2,
        roomId: roomId,
        userId: 'me',
        content: '좋아',
        createdAt: DateTime(2026, 11, 18, 9, 6),
      ),
    ]);
  }

  @override
  Future<void> send({required String roomId, required String content}) async {
    sent.add(content);
  }
}

Widget _sheet(_FakeChatService chat) {
  return ProviderScope(
    overrides: [
      chatServiceProvider.overrideWithValue(chat),
      currentUserIdProvider.overrideWithValue('me'),
      roomMembersProvider('room1').overrideWith(
        (ref) async => const [
          RoomMember(userId: 'me', nickname: '현우', isOwner: true),
          RoomMember(userId: 'friend', nickname: '영욱', isOwner: false),
        ],
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ChatSheet(roomId: 'room1')),
    ),
  );
}

void main() {
  test('메시지 JSON을 읽는다', () {
    final message = ChatMessage.fromJson({
      'id': 7,
      'room_id': 'r',
      'user_id': 'u',
      'content': '안녕',
      'created_at': '2026-11-18T00:00:00+00:00',
    });

    expect(message.id, 7);
    expect(message.content, '안녕');
  });

  testWidgets('다른 멤버 메시지에는 닉네임을 표시한다', (tester) async {
    await tester.pumpWidget(_sheet(_FakeChatService()));
    await tester.pumpAndSettle();

    expect(find.text('차 1대로 가자'), findsOneWidget);
    expect(find.text('좋아'), findsOneWidget);
    expect(find.text('영욱'), findsOneWidget);
    expect(find.text('현우'), findsNothing);
  });

  testWidgets('앞뒤 공백을 지우고 보내며, 빈 메시지는 보내지 않는다', (tester) async {
    final chat = _FakeChatService();
    await tester.pumpWidget(_sheet(chat));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('chat-input')), '   ');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();
    expect(chat.sent, isEmpty);

    await tester.enterText(find.byKey(const Key('chat-input')), '  3박 어때?  ');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pumpAndSettle();

    expect(chat.sent, ['3박 어때?']);
    expect(find.widgetWithText(TextField, '3박 어때?'), findsNothing);
  });
}
