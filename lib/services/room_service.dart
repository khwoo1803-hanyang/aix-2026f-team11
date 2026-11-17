import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/travel_room.dart';

class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException();
}

/// 사용자가 입력한 초대 코드를 비교 가능한 형태로 맞춘다.
String normalizeInviteCode(String input) {
  return input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
}

bool isValidInviteCode(String code) {
  return RegExp(r'^[A-Z2-9]{6}$').hasMatch(code);
}

class RoomService {
  const RoomService(this._client);

  final SupabaseClient _client;

  /// RLS 정책에 따라 내가 멤버인 여행방만 돌아온다.
  Future<List<TravelRoom>> fetchMyRooms() async {
    final rows = await _client
        .from('travel_rooms')
        .select('id, name, invite_code, owner_id, expected_members, created_at')
        .order('created_at', ascending: false);
    return rows.map(TravelRoom.fromJson).toList();
  }

  Future<TravelRoom> createRoom({
    required String name,
    int? expectedMembers,
  }) async {
    final row = await _client.rpc(
      'create_room',
      params: {'room_name': name, 'expected': expectedMembers},
    );
    return TravelRoom.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// 초대 코드로 입장하고 여행방 ID를 돌려준다.
  Future<String> joinByCode(String code) async {
    try {
      final roomId = await _client.rpc(
        'join_room_by_code',
        params: {'code': normalizeInviteCode(code)},
      );
      return roomId as String;
    } on PostgrestException catch (error) {
      if (error.message.contains('invalid_invite_code')) {
        throw const InvalidInviteCodeException();
      }
      rethrow;
    }
  }

  Future<TravelRoom> fetchRoom(String roomId) async {
    final row = await _client
        .from('travel_rooms')
        .select('id, name, invite_code, owner_id, expected_members, created_at')
        .eq('id', roomId)
        .single();
    return TravelRoom.fromJson(row);
  }

  Future<List<RoomMember>> fetchMembers(String roomId) async {
    final rows = await _client
        .from('room_members')
        .select('user_id, role, profiles(nickname)')
        .eq('room_id', roomId)
        .order('joined_at');
    return rows.map(RoomMember.fromJson).toList();
  }
}
