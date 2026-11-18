import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/travel_conditions.dart';

class TravelConditionsConflict implements Exception {
  const TravelConditionsConflict();
}

class TravelConditionsService {
  const TravelConditionsService(this._client);

  final SupabaseClient _client;

  Future<TravelConditions> fetch(String roomId) async {
    final row = await _client
        .from('travel_conditions')
        .select()
        .eq('room_id', roomId)
        .maybeSingle();
    return row == null
        ? const TravelConditions()
        : TravelConditions.fromJson(row);
  }

  Future<void> save(String roomId, TravelConditions conditions) async {
    final table = _client.from('travel_conditions');
    final values = conditions.toUpdate();
    final revision = conditions.revision;

    if (revision == null) {
      try {
        await table.insert({...values, 'room_id': roomId});
      } on PostgrestException catch (error) {
        if (error.code == '23505') throw const TravelConditionsConflict();
        rethrow;
      }
      return;
    }

    final updated = await table
        .update(values)
        .eq('room_id', roomId)
        .eq('revision', revision)
        .select('room_id')
        .maybeSingle();
    if (updated == null) throw const TravelConditionsConflict();
  }
}
