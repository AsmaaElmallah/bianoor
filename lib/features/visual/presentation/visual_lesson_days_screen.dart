import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../curriculum/domain/curriculum_journey_config.dart';
import '../../curriculum/presentation/curriculum_lesson_days_screen.dart';
import '../application/visual_curriculum_provider.dart';
import '../domain/visual_curriculum_schedule.dart';

class VisualLessonDaysScreen extends ConsumerWidget {
  const VisualLessonDaysScreen({super.key, required this.lessonNumber});

  final int lessonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(visualCurriculumProvider);
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (state) {
        final range = visualLessonSlideRange(lessonNumber);
        final unlockAll = ref.watch(prefsServiceProvider).isDevUnlockAllLessons();
        return CurriculumLessonDaysScreen(
          config: visualJourneyConfig(),
          lessonNumber: lessonNumber,
          curriculumDay: state.curriculumDay,
          unlockAllLessons: unlockAll,
          slideInfo:
              '${range.slideCount} شرائح (${range.globalStart}–${range.globalEnd})',
        );
      },
    );
  }
}
