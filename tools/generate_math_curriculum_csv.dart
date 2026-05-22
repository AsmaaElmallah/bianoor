// ignore_for_file: avoid_print

import 'dart:io';

import 'package:bayanour/features/math/domain/math_curriculum_schedule.dart';
import 'package:bayanour/features/math/domain/math_day_schedule.dart';

void main() {
  final buf = StringBuffer(
    'day,lesson,slide_count,global_from,global_to,'
    'ppt_129_132,ppt_133_136,ppt_beads,'
    'sessions,training_day,focus_min,focus_max,focus_unit,phase\n',
  );

  for (var day = 1; day <= mathCurriculumTotalDays; day++) {
    final lesson = mathLessonNumberForDay(day);
    final range = mathLessonSlideRange(lesson);
    final ppt = mathPptColumnsForLesson(lesson);
    final rules = mathRulesForDay(day);
    final phase = mathPhaseCodeForDay(day);

    buf.writeln(
      '$day,$lesson,${range.slideCount},${range.globalStart},${range.globalEnd},'
      '${ppt.ppt129_132},${ppt.ppt133_136},${ppt.pptBeads},'
      '${rules.repetitionsPerDay},${rules.isTrainingDay ? 'yes' : 'no'},'
      '${rules.focusMinSec},${rules.focusMaxSec},sec,$phase',
    );
  }

  final out = File('docs/math_curriculum_730_days.csv');
  out.writeAsStringSync(buf.toString());
  print('Wrote ${out.path} (${mathCurriculumTotalDays} rows)');
}
