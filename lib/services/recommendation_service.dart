import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recommendation.dart';

/// 사용자에게 그대로 보여줄 수 있는 여행지 추천 오류.
class RecommendationException implements Exception {
  const RecommendationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RecommendationService {
  const RecommendationService(this._client);

  final SupabaseClient _client;

  Stream<List<Recommendation>> watchRecommendations(String roomId) {
    return _client
        .from('destination_recommendations')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Recommendation.fromJson).toList());
  }

  /// 저장된 조건과 투표 현황으로 AI 추천을 받는다. 결과는 [watchRecommendations]로 들어온다.
  /// 받은 추천 개수를 돌려준다.
  Future<int> request(String roomId) async {
    try {
      final response = await _client.functions.invoke(
        'recommend-destinations',
        body: {'room_id': roomId},
      );
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on FunctionException catch (error) {
      throw describeRecommendationError(error.details);
    }
  }
}

RecommendationException describeRecommendationError(Object? details) {
  final code = details is Map ? details['error'] : null;
  final reason = details is Map ? details['reason'] : null;
  return RecommendationException(switch (code) {
    'no_conditions' => '먼저 여행 조건을 하나 이상 정리하거나 직접 입력해 주세요.',
    'cooldown' => '방금 추천을 받았어요. 30초 뒤에 다시 시도해 주세요.',
    'daily_limit' => '오늘은 이 여행방에서 추천을 더 받을 수 없어요.',
    'not_room_member' => '이 여행방의 멤버만 추천을 받을 수 있어요.',
    'not_signed_in' => '다시 로그인해 주세요.',
    'ai_failed' when reason == 'ai_key_missing' || reason == 'ai_no_credit' =>
      'AI 추천이 아직 준비되지 않았어요. 관리자에게 알려 주세요.',
    'ai_failed' => 'AI가 응답하지 않았어요. 잠시 뒤 다시 시도해 주세요.',
    _ => '추천을 받지 못했어요. 잠시 뒤 다시 시도해 주세요.',
  });
}
