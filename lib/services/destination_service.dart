import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/destination.dart';

const maxDestinationsPerMember = 2;

/// 사용자에게 그대로 보여줄 수 있는 여행지 투표 오류.
class DestinationException implements Exception {
  const DestinationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DestinationService {
  const DestinationService(this._client);

  final SupabaseClient _client;

  Stream<List<Destination>> watchDestinations(String roomId) {
    return _client
        .from('destinations')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Destination.fromJson).toList());
  }

  Stream<List<DestinationVote>> watchVotes(String roomId) {
    return _client
        .from('destination_votes')
        .stream(primaryKey: ['destination_id', 'user_id'])
        .eq('room_id', roomId)
        .map((rows) => rows.map(DestinationVote.fromJson).toList());
  }

  Future<void> addDestination({
    required String roomId,
    required String name,
    String? reason,
  }) async {
    try {
      await _client.from('destinations').insert({
        'room_id': roomId,
        'name': name,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } on PostgrestException catch (error) {
      throw _describe(error);
    }
  }

  Future<void> vote({
    required String destinationId,
    required VoteChoice choice,
  }) async {
    try {
      await _client.from('destination_votes').upsert(
        {'destination_id': destinationId, 'choice': choice.value},
        onConflict: 'destination_id,user_id',
      );
    } on PostgrestException catch (error) {
      throw _describe(error);
    }
  }

  Future<void> confirm(String destinationId) async {
    try {
      await _client.rpc(
        'confirm_destination',
        params: {'target': destinationId},
      );
    } on PostgrestException catch (error) {
      throw _describe(error);
    }
  }
}

DestinationException _describe(PostgrestException error) {
  final message = error.message;
  if (message.contains('destination_limit')) {
    return const DestinationException('후보는 한 사람당 2개까지 올릴 수 있어요.');
  }
  if (message.contains('not_majority')) {
    return const DestinationException('찬성이 과반이어야 확정할 수 있어요.');
  }
  if (message.contains('not_room_owner')) {
    return const DestinationException('방장만 여행지를 확정할 수 있어요.');
  }
  if (error.code == '23505') {
    return const DestinationException('이미 올라온 여행지예요.');
  }
  return const DestinationException('요청을 처리하지 못했어요. 다시 시도해 주세요.');
}
