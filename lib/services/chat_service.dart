import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';

const maxMessageLength = 1000;

class ChatService {
  const ChatService(this._client);

  final SupabaseClient _client;

  /// 여행방 메시지를 오래된 순으로 받고, 새 메시지가 오면 목록을 다시 보낸다.
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  Future<void> send({required String roomId, required String content}) {
    return _client.from('messages').insert({
      'room_id': roomId,
      'content': content,
    });
  }
}
