import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../curriculum/domain/curriculum_journey_config.dart';
import '../../curriculum/presentation/curriculum_lesson_journey_screen.dart';
import '../application/visual_curriculum_provider.dart';

class VisualJourneyScreen extends ConsumerWidget {
  const VisualJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(visualCurriculumProvider);
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (state) => CurriculumLessonJourneyScreen(
        config: visualJourneyConfig(),
        curriculumDay: state.curriculumDay,
      ),
    );
  }
}
