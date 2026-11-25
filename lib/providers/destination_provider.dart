import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/destination.dart';
import '../services/destination_service.dart';
import '../services/supabase_client.dart';

final destinationServiceProvider = Provider<DestinationService>((ref) {
  return DestinationService(supabase);
});

final roomDestinationsProvider =
    StreamProvider.family<List<Destination>, String>((ref, roomId) {
  return ref.watch(destinationServiceProvider).watchDestinations(roomId);
});

final roomVotesProvider =
    StreamProvider.family<List<DestinationVote>, String>((ref, roomId) {
  return ref.watch(destinationServiceProvider).watchVotes(roomId);
});
