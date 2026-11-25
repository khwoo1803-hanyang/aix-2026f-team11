import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/supabase_client.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(supabase);
});

final roomMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  roomId,
) {
  return ref.watch(chatServiceProvider).watchMessages(roomId);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).value?.user.id;
});
