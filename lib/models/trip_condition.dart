enum ConditionField {
  people('people', '인원'),
  dates('dates', '날짜'),
  departure('departure', '출발지'),
  transport('transport', '이동수단'),
  budget('budget', '예산'),
  activity('activity', '활동');

  const ConditionField(this.value, this.label);

  final String value;
  final String label;

  static ConditionField? fromValue(String value) {
    for (final field in values) {
      if (field.value == value) return field;
    }
    return null;
  }
}

class TripCondition {
  const TripCondition({
    required this.field,
    required this.value,
    this.sourceMessageId,
    this.inferred = false,
  });

  /// DB에 없는 항목 값이면 null을 돌려준다.
  static TripCondition? fromJson(Map<String, dynamic> json) {
    final field = ConditionField.fromValue(json['field'] as String);
    if (field == null) return null;
    return TripCondition(
      field: field,
      value: json['value'] as String,
      sourceMessageId: json['source_message_id'] as int?,
      inferred: json['inferred'] as bool? ?? false,
    );
  }

  final ConditionField field;
  final String value;
  final int? sourceMessageId;

  /// AI가 대화로 미루어 짐작한 값이면 true.
  final bool inferred;
}
