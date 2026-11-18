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
    this.manual = false,
    this.updatedBy,
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
      manual: json['manual'] as bool? ?? false,
      updatedBy: json['updated_by'] as String?,
    );
  }

  final ConditionField field;
  final String value;
  final int? sourceMessageId;

  /// AI가 대화로 미루어 짐작한 값이면 true.
  final bool inferred;

  /// 멤버가 직접 입력하거나 고친 값이면 true. AI가 다시 정리해도 덮어쓰지 않는다.
  final bool manual;

  final String? updatedBy;
}

/// AI 정리 결과. [kept]는 직접 고친 값이라 그대로 둔 항목 수.
typedef ExtractResult = ({int found, int kept});
