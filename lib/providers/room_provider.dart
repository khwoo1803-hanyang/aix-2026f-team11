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

/// 방장이 여행지를 확정하면 다른 멤버 화면에도 바로 반영되도록 실시간으로 받는다.
final roomProvider = StreamProvider.family<TravelRoom, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).watchRoom(roomId);
});

final roomMembersProvider =
    FutureProvider.family<List<RoomMember>, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchMembers(roomId);
});
