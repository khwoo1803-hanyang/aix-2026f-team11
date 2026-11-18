class TravelRoom {
  const TravelRoom({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.createdAt,
    this.expectedMembers,
    this.confirmedDestinationId,
  });

  factory TravelRoom.fromJson(Map<String, dynamic> json) {
    return TravelRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      ownerId: json['owner_id'] as String,
      expectedMembers: json['expected_members'] as int?,
      confirmedDestinationId: json['confirmed_destination_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final int? expectedMembers;
  final String? confirmedDestinationId;
  final DateTime createdAt;
}

class RoomMember {
  const RoomMember({
    required this.userId,
    required this.nickname,
    required this.isOwner,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return RoomMember(
      userId: json['user_id'] as String,
      nickname: profile?['nickname'] as String? ?? '알 수 없음',
      isOwner: json['role'] == 'owner',
    );
  }

  final String userId;
  final String nickname;
  final bool isOwner;
}
