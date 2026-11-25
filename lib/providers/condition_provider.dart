import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_condition.dart';
import '../services/condition_service.dart';
import '../services/supabase_client.dart';

final conditionServiceProvider = Provider<ConditionService>((ref) {
  return ConditionService(supabase);
});

final roomConditionsProvider =
    StreamProvider.family<List<TripCondition>, String>((ref, roomId) {
  return ref.watch(conditionServiceProvider).watchConditions(roomId);
});
