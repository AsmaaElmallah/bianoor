// ignore_for_file: avoid_print

import 'dart:io';

import 'package:bayanour/features/curriculum/domain/curriculum_day_rules.dart';
import 'package:bayanour/features/curriculum/domain/curriculum_shared_schedule.dart';
import 'package:bayanour/features/emotional/domain/emotional_curriculum_schedule.dart';

void main() {
  final buf = StringBuffer(
    'day,lesson,slide_count,global_from,global_to,'
    'sessions,training_day,focus_min,focus_max,focus_unit,phase\n',
  );

  for (var day = 1; day <= curriculumProgramTotalDays; day++) {
    final lesson = emotionalLessonNumberForDay(day);
    final range = emotionalLessonSlideRange(lesson);
    final rules = curriculumRulesForDay(day, lastNewContentDay: emotionalLastNewContentDay);
    final phase = emotionalPhaseCodeForDay(day);

    buf.writeln(
      '$day,$lesson,${range.slideCount},${range.globalStart},${range.globalEnd},'
      '${rules.repetitionsPerDay},${rules.isTrainingDay ? 'yes' : 'no'},'
      '${rules.focusMinSec},${rules.focusMaxSec},sec,$phase',
    );
  }

  final out = File('docs/emotional_curriculum_730_days.csv');
  out.writeAsStringSync(buf.toString());
  print('Wrote ${out.path} ($curriculumProgramTotalDays rows)');
}
