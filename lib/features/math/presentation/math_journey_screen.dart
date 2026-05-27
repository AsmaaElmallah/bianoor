import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../../core/storage/prefs_service.dart';
import '../../curriculum/domain/curriculum_journey_config.dart';
import '../../curriculum/presentation/curriculum_lesson_journey_screen.dart';
import '../application/math_curriculum_provider.dart';

class MathJourneyScreen extends ConsumerWidget {
  const MathJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mathCurriculumProvider);
    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('تعذر التحميل: $e'))),
      data: (state) {
        final unlockAll = ref.watch(prefsServiceProvider).isDevUnlockAllLessons();
        final cloudCount =
            ref.watch(curriculumCloudSlideCountProvider('math')).valueOrNull ?? 0;
        return CurriculumLessonJourneyScreen(
          config: mathJourneyConfig(),
          curriculumDay: state.curriculumDay,
          unlockAllLessons: unlockAll,
          supabaseNote: cloudCount > 0
              ? '☁️ $cloudCount شريحة منشورة على Supabase — تُستبدل عند التشغيل حسب رقم الشريحة العالمي'
              : 'المحتوى محلي — لا شرائح منشورة لرياضيات على Supabase (انشري من الأدمن)',
        );
      },
    );
  }
}
