class TravelConditions {
  const TravelConditions({
    this.departure,
    this.startDate,
    this.endDate,
    this.travelerCount,
    this.budgetPerPersonKrw,
    this.transport,
    this.preferredActivities,
    this.revision,
  });

  factory TravelConditions.fromJson(Map<String, dynamic> json) {
    return TravelConditions(
      departure: json['departure'] as String?,
      startDate: _readDate(json['start_date'] as String?),
      endDate: _readDate(json['end_date'] as String?),
      travelerCount: json['traveler_count'] as int?,
      budgetPerPersonKrw: json['budget_per_person_krw'] as int?,
      transport: json['transport'] as String?,
      preferredActivities: json['preferred_activities'] as String?,
      revision: json['revision'] as int,
    );
  }

  final String? departure;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? travelerCount;
  final int? budgetPerPersonKrw;
  final String? transport;
  final String? preferredActivities;
  final int? revision;

  static DateTime? _readDate(String? value) =>
      value == null ? null : DateTime.parse(value);

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toUpdate() => {
    'departure': departure,
    'start_date': startDate == null ? null : formatDate(startDate!),
    'end_date': endDate == null ? null : formatDate(endDate!),
    'traveler_count': travelerCount,
    'budget_per_person_krw': budgetPerPersonKrw,
    'transport': transport,
    'preferred_activities': preferredActivities,
  };
}
