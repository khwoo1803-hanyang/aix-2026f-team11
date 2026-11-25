import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation.dart';
import '../services/recommendation_service.dart';
import '../services/supabase_client.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(supabase);
});

/// 가장 최근에 받은 추천 묶음.
final roomRecommendationsProvider =
    StreamProvider.family<List<Recommendation>, String>((ref, roomId) {
      return ref
          .watch(recommendationServiceProvider)
          .watchRecommendations(roomId)
          .map(latestBatch);
    });
