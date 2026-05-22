class VisualProgress {
  const VisualProgress({
    required this.curriculumDay,
    required this.roundsCompletedToday,
    required this.lastSessionDateIso,
    required this.programStartDateIso,
  });

  final int curriculumDay;
  final int roundsCompletedToday;
  final String? lastSessionDateIso;
  final String? programStartDateIso;

  VisualProgress copyWith({
    int? curriculumDay,
    int? roundsCompletedToday,
    String? lastSessionDateIso,
    String? programStartDateIso,
  }) {
    return VisualProgress(
      curriculumDay: curriculumDay ?? this.curriculumDay,
      roundsCompletedToday: roundsCompletedToday ?? this.roundsCompletedToday,
      lastSessionDateIso: lastSessionDateIso ?? this.lastSessionDateIso,
      programStartDateIso: programStartDateIso ?? this.programStartDateIso,
    );
  }
}
