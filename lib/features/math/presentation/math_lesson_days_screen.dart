import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/domain/curriculum_journey_config.dart';
import '../../curriculum/presentation/curriculum_lesson_days_screen.dart';
import '../application/math_curriculum_provider.dart';
import '../domain/math_curriculum_schedule.dart';

class MathLessonDaysScreen extends ConsumerWidget {
  const MathLessonDaysScreen({super.key, required this.lessonNumber});

  final int lessonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mathCurriculumProvider);
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (state) {
        final range = mathLessonSlideRange(lessonNumber);
        return CurriculumLessonDaysScreen(
          config: mathJourneyConfig(),
          lessonNumber: lessonNumber,
          curriculumDay: state.curriculumDay,
          slideInfo:
              '${range.slideCount} شرائح (${range.globalStart}–${range.globalEnd})',
        );
      },
    );
  }
}
