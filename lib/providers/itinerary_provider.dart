import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/itinerary.dart';
import '../services/itinerary_service.dart';
import '../services/supabase_client.dart';

final itineraryServiceProvider = Provider<ItineraryService>((ref) {
  return ItineraryService(supabase);
});

final roomPlacesProvider = StreamProvider.family<List<Place>, String>((
  ref,
  roomId,
) {
  return ref.watch(itineraryServiceProvider).watchPlaces(roomId);
});

final roomPlaceVotesProvider = StreamProvider.family<List<PlaceVote>, String>((
  ref,
  roomId,
) {
  return ref.watch(itineraryServiceProvider).watchPlaceVotes(roomId);
});

final roomDaysProvider = StreamProvider.family<List<ItineraryDay>, String>((
  ref,
  roomId,
) {
  return ref.watch(itineraryServiceProvider).watchDays(roomId);
});

final roomItineraryItemsProvider =
    StreamProvider.family<List<ItineraryItem>, String>((ref, roomId) {
      return ref.watch(itineraryServiceProvider).watchItems(roomId);
    });
