import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip_condition.dart';

/// 사용자에게 그대로 보여줄 수 있는 조건 정리 오류.
class ConditionException implements Exception {
  const ConditionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ConditionService {
  const ConditionService(this._client);

  final SupabaseClient _client;

  Stream<List<TripCondition>> watchConditions(String roomId) {
    return _client
        .from('trip_conditions')
        .stream(primaryKey: ['room_id', 'field'])
        .eq('room_id', roomId)
        .map((rows) => rows.map(TripCondition.fromJson).nonNulls.toList());
  }

  /// 채팅을 AI로 읽어 조건을 저장하고, 이번에 찾은 조건 수를 돌려준다.
  /// AI 호출이 실패하면 조건은 바뀌지 않는다.
  Future<int> extractFromChat(String roomId) async {
    try {
      final response = await _client.functions.invoke(
        'extract-conditions',
        body: {'room_id': roomId},
      );
      final conditions = (response.data as Map<String, dynamic>)['conditions'];
      return conditions is List ? conditions.length : 0;
    } on FunctionException catch (error) {
      throw _describe(error);
    }
  }
}

ConditionException _describe(FunctionException error) {
  final details = error.details;
  final code = details is Map ? details['error'] : null;
  return ConditionException(switch (code) {
    'cooldown' => '방금 정리했어요. 10초 뒤에 다시 시도해 주세요.',
    'daily_limit' => '오늘은 이 여행방에서 조건 정리를 더 할 수 없어요.',
    'not_room_member' => '이 여행방의 멤버만 조건을 정리할 수 있어요.',
    'not_signed_in' => '다시 로그인해 주세요.',
    'ai_failed' => 'AI가 응답하지 않았어요. 조건은 바뀌지 않았으니 잠시 뒤 다시 시도하거나 직접 입력해 주세요.',
    _ => '조건을 정리하지 못했어요. 잠시 뒤 다시 시도해 주세요.',
  });
}
