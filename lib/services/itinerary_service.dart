import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/itinerary.dart';

/// 사용자에게 그대로 보여줄 수 있는 장소·일정 오류.
class ItineraryException implements Exception {
  const ItineraryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItineraryService {
  const ItineraryService(this._client);

  final SupabaseClient _client;

  Stream<List<Place>> watchPlaces(String roomId) {
    return _client
        .from('places')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) => rows.map(Place.fromJson).toList());
  }

  Stream<List<PlaceVote>> watchPlaceVotes(String roomId) {
    return _client
        .from('place_votes')
        .stream(primaryKey: ['place_id', 'user_id'])
        .eq('room_id', roomId)
        .map((rows) => rows.map(PlaceVote.fromJson).toList());
  }

  Stream<List<ItineraryDay>> watchDays(String roomId) {
    return _client
        .from('itinerary_days')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('day_number', ascending: true)
        .map((rows) => rows.map(ItineraryDay.fromJson).toList());
  }

  Stream<List<ItineraryItem>> watchItems(String roomId) {
    return _client
        .from('itinerary_items')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) => rows.map(ItineraryItem.fromJson).toList());
  }

  Future<void> addPlace({
    required String roomId,
    required String name,
    required PlaceCategory category,
    String? address,
    String? memo,
  }) {
    return _run(
      () => _client.from('places').insert({
        'room_id': roomId,
        'name': name,
        'category': category.value,
        if (address != null && address.isNotEmpty) 'address': address,
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      }),
    );
  }

  /// 장소를 지우면 그 장소가 들어간 일정도 함께 지워진다.
  Future<void> deletePlace(String placeId) {
    return _run(() => _client.from('places').delete().eq('id', placeId));
  }

  Future<void> setLike({required String placeId, required bool liked}) {
    final userId = _client.auth.currentUser?.id;
    return _run(() async {
      if (liked) {
        await _client
            .from('place_votes')
            .upsert(
              {'place_id': placeId},
              onConflict: 'place_id,user_id',
              ignoreDuplicates: true,
            );
      } else {
        await _client
            .from('place_votes')
            .delete()
            .eq('place_id', placeId)
            .eq('user_id', userId ?? '');
      }
    });
  }

  Future<void> addDay({required String roomId, required int dayNumber}) {
    return _run(
      () => _client.from('itinerary_days').insert({
        'room_id': roomId,
        'day_number': dayNumber,
      }),
    );
  }

  /// 일차를 지우면 그날 일정도 함께 지워진다.
  Future<void> deleteDay(String dayId) {
    return _run(() => _client.from('itinerary_days').delete().eq('id', dayId));
  }

  /// 일차의 맨 뒤에 장소를 넣는다.
  Future<void> addItem({
    required String dayId,
    required String placeId,
    TimeOfDay? visitTime,
  }) {
    return _run(
      () => _client.from('itinerary_items').insert({
        'day_id': dayId,
        'place_id': placeId,
        if (visitTime != null) 'visit_time': formatVisitTime(visitTime),
      }),
    );
  }

  Future<void> updateItem({
    required String itemId,
    required TimeOfDay? visitTime,
    required String? memo,
  }) {
    return _run(
      () => _client
          .from('itinerary_items')
          .update({
            'visit_time': visitTime == null ? null : formatVisitTime(visitTime),
            'memo': memo == null || memo.isEmpty ? null : memo,
          })
          .eq('id', itemId),
    );
  }

  Future<void> deleteItem(String itemId) {
    return _run(
      () => _client.from('itinerary_items').delete().eq('id', itemId),
    );
  }

  /// 일차 안의 순서를 [orderedIds] 순서로 바꾼다.
  Future<void> reorder({
    required String dayId,
    required List<String> orderedIds,
  }) {
    return _run(
      () => _client.rpc(
        'reorder_itinerary',
        params: {'target_day': dayId, 'ordered_ids': orderedIds},
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on PostgrestException catch (error) {
      throw describeItineraryError(error.code, error.message);
    }
  }
}

ItineraryException describeItineraryError(String? code, String message) {
  if (message.contains('order_out_of_date')) {
    return const ItineraryException('다른 멤버가 일정을 바꿨어요. 바뀐 일정을 보고 다시 옮겨 주세요.');
  }
  if (message.contains('place_not_in_room')) {
    return const ItineraryException('이 여행방의 장소만 일정에 넣을 수 있어요.');
  }
  if (code == '23505') {
    return const ItineraryException('이미 있는 항목이에요.');
  }
  return const ItineraryException('요청을 처리하지 못했어요. 다시 시도해 주세요.');
}
