enum VoteChoice {
  agree('agree', '찬성'),
  neutral('neutral', '보통'),
  disagree('disagree', '반대');

  const VoteChoice(this.value, this.label);

  final String value;
  final String label;

  static VoteChoice fromValue(String value) {
    return values.firstWhere((choice) => choice.value == value);
  }
}

class Destination {
  const Destination({
    required this.id,
    required this.roomId,
    required this.proposedBy,
    required this.name,
    required this.createdAt,
    this.reason,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      proposedBy: json['proposed_by'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String roomId;
  final String proposedBy;
  final String name;
  final String? reason;
  final DateTime createdAt;
}

class DestinationVote {
  const DestinationVote({
    required this.destinationId,
    required this.userId,
    required this.choice,
  });

  factory DestinationVote.fromJson(Map<String, dynamic> json) {
    return DestinationVote(
      destinationId: json['destination_id'] as String,
      userId: json['user_id'] as String,
      choice: VoteChoice.fromValue(json['choice'] as String),
    );
  }

  final String destinationId;
  final String userId;
  final VoteChoice choice;
}

class VoteTally {
  const VoteTally({
    this.agree = 0,
    this.neutral = 0,
    this.disagree = 0,
    this.mine,
  });

  final int agree;
  final int neutral;
  final int disagree;
  final VoteChoice? mine;

  /// 찬성이 전체 멤버의 절반을 넘으면 방장이 확정할 수 있다.
  bool hasMajority(int memberCount) => memberCount > 0 && agree * 2 > memberCount;
}

/// 투표 목록을 후보별 찬성·보통·반대 수와 내 선택으로 묶는다.
Map<String, VoteTally> tallyVotes(List<DestinationVote> votes, String? myId) {
  final result = <String, VoteTally>{};
  for (final vote in votes) {
    final current = result[vote.destinationId] ?? const VoteTally();
    result[vote.destinationId] = VoteTally(
      agree: current.agree + (vote.choice == VoteChoice.agree ? 1 : 0),
      neutral: current.neutral + (vote.choice == VoteChoice.neutral ? 1 : 0),
      disagree: current.disagree + (vote.choice == VoteChoice.disagree ? 1 : 0),
      mine: vote.userId == myId ? vote.choice : current.mine,
    );
  }
  return result;
}
