import 'trip_condition.dart';

/// 추천 여행지가 조건 하나에 맞는 정도.
enum MatchStatus {
  match('match', '맞음'),
  partial('partial', '조정 필요'),
  unknown('unknown', '확인 필요');

  const MatchStatus(this.value, this.label);

  final String value;
  final String label;

  static MatchStatus? fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

class ConditionMatch {
  const ConditionMatch({
    required this.field,
    required this.status,
    this.note = '',
  });

  final ConditionField field;
  final MatchStatus status;
  final String note;
}

class Recommendation {
  const Recommendation({
    required this.id,
    required this.batchId,
    required this.rank,
    required this.name,
    required this.reason,
    required this.createdAt,
    this.region,
    this.matches = const [],
    this.caution,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    final matches = <ConditionMatch>[];
    if (rawMatches is List) {
      for (final item in rawMatches) {
        if (item is! Map) continue;
        final field = ConditionField.fromValue(item['field'] as String? ?? '');
        final status = MatchStatus.fromValue(item['status'] as String?);
        if (field == null || status == null) continue;
        matches.add(
          ConditionMatch(
            field: field,
            status: status,
            note: item['note'] as String? ?? '',
          ),
        );
      }
    }
    return Recommendation(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      rank: json['rank'] as int,
      name: json['name'] as String,
      region: json['region'] as String?,
      reason: json['reason'] as String,
      matches: matches,
      caution: json['caution'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String batchId;
  final int rank;
  final String name;
  final String? region;
  final String reason;
  final List<ConditionMatch> matches;
  final String? caution;
  final DateTime createdAt;
}

/// 가장 최근에 받은 추천 묶음만 순위대로 돌려준다.
List<Recommendation> latestBatch(List<Recommendation> all) {
  if (all.isEmpty) return const [];
  var latest = all.first;
  for (final item in all) {
    if (item.createdAt.isAfter(latest.createdAt)) latest = item;
  }
  return all.where((item) => item.batchId == latest.batchId).toList()
    ..sort((a, b) => a.rank.compareTo(b.rank));
}
