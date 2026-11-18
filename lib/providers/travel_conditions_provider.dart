import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/travel_conditions.dart';
import '../services/supabase_client.dart';
import '../services/travel_conditions_service.dart';

final travelConditionsServiceProvider = Provider<TravelConditionsService>((
  ref,
) {
  return TravelConditionsService(supabase);
});

final travelConditionsProvider = FutureProvider.autoDispose
    .family<TravelConditions, String>((ref, roomId) {
      return ref.watch(travelConditionsServiceProvider).fetch(roomId);
    });
