import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/travel_room.dart';
import '../services/room_service.dart';
import '../services/supabase_client.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService(supabase);
});

final myRoomsProvider = FutureProvider<List<TravelRoom>>((ref) {
  return ref.watch(roomServiceProvider).fetchMyRooms();
});

final roomProvider = FutureProvider.family<TravelRoom, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchRoom(roomId);
});

final roomMembersProvider =
    FutureProvider.family<List<RoomMember>, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchMembers(roomId);
});
