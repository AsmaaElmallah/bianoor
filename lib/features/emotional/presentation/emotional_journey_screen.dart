import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../../core/storage/prefs_service.dart';
import '../../curriculum/domain/curriculum_journey_config.dart';
import '../../curriculum/presentation/curriculum_lesson_journey_screen.dart';
import '../application/emotional_curriculum_provider.dart';

class EmotionalJourneyScreen extends ConsumerWidget {
  const EmotionalJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(emotionalCurriculumProvider);
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (state) {
        final unlockAll = ref.watch(prefsServiceProvider).isDevUnlockAllLessons();
        final cloudCount =
            ref.watch(curriculumCloudSlideCountProvider('emotional')).valueOrNull ?? 0;
        return CurriculumLessonJourneyScreen(
          config: emotionalJourneyConfig(),
          curriculumDay: state.curriculumDay,
          unlockAllLessons: unlockAll,
          supabaseNote: cloudCount > 0
              ? '☁️ $cloudCount شريحة منشورة على Supabase'
              : 'محلي — لا شرائح عاطفي منشورة على Supabase',
        );
      },
    );
  }
}
