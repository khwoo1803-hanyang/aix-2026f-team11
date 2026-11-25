import 'package:flutter/material.dart';

enum PlaceCategory {
  food('food', '맛집', Icons.restaurant),
  cafe('cafe', '카페', Icons.local_cafe),
  sight('sight', '관광지', Icons.photo_camera),
  stay('stay', '숙소', Icons.hotel),
  etc('etc', '기타', Icons.place);

  const PlaceCategory(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static PlaceCategory fromValue(String? value) {
    for (final category in values) {
      if (category.value == value) return category;
    }
    return etc;
  }
}

/// 장소 후보함에 올라온 장소.
class Place {
  const Place({
    required this.id,
    required this.roomId,
    required this.addedBy,
    required this.name,
    required this.createdAt,
    this.category = PlaceCategory.etc,
    this.address,
    this.memo,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      addedBy: json['added_by'] as String,
      name: json['name'] as String,
      category: PlaceCategory.fromValue(json['category'] as String?),
      address: json['address'] as String?,
      memo: json['memo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String roomId;
  final String addedBy;
  final String name;
  final PlaceCategory category;
  final String? address;
  final String? memo;
  final DateTime createdAt;
}

class PlaceVote {
  const PlaceVote({required this.placeId, required this.userId});

  factory PlaceVote.fromJson(Map<String, dynamic> json) {
    return PlaceVote(
      placeId: json['place_id'] as String,
      userId: json['user_id'] as String,
    );
  }

  final String placeId;
  final String userId;
}

class ItineraryDay {
  const ItineraryDay({required this.id, required this.dayNumber});

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
    );
  }

  final String id;
  final int dayNumber;
}

class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.dayId,
    required this.placeId,
    required this.position,
    this.visitTime,
    this.memo,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      dayId: json['day_id'] as String,
      placeId: json['place_id'] as String,
      position: json['position'] as int,
      visitTime: parseVisitTime(json['visit_time'] as String?),
      memo: json['memo'] as String?,
    );
  }

  final String id;
  final String dayId;
  final String placeId;
  final int position;
  final TimeOfDay? visitTime;
  final String? memo;
}

/// DB의 time 값("09:30:00")을 읽는다.
TimeOfDay? parseVisitTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// DB에 저장할 time 값("09:30")과 화면 표시에 쓴다.
String formatVisitTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// 좋아요 수와 내가 눌렀는지.
typedef PlaceLikes = ({int count, bool mine});

Map<String, PlaceLikes> tallyPlaceVotes(List<PlaceVote> votes, String? myId) {
  final result = <String, PlaceLikes>{};
  for (final vote in votes) {
    final current = result[vote.placeId] ?? (count: 0, mine: false);
    result[vote.placeId] = (
      count: current.count + 1,
      mine: current.mine || vote.userId == myId,
    );
  }
  return result;
}

/// 좋아요가 많은 순, 같으면 먼저 올린 순.
List<Place> sortPlacesByLikes(
  List<Place> places,
  Map<String, PlaceLikes> likes,
) {
  return [...places]..sort((a, b) {
    final diff = (likes[b.id]?.count ?? 0) - (likes[a.id]?.count ?? 0);
    return diff != 0 ? diff : a.createdAt.compareTo(b.createdAt);
  });
}

/// 일차별 항목을 순서대로 묶는다.
Map<String, List<ItineraryItem>> groupItemsByDay(List<ItineraryItem> items) {
  final result = <String, List<ItineraryItem>>{};
  for (final item in items) {
    result.putIfAbsent(item.dayId, () => []).add(item);
  }
  for (final list in result.values) {
    list.sort((a, b) => a.position.compareTo(b.position));
  }
  return result;
}
