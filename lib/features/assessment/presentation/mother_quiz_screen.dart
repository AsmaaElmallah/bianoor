import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../../shared/widgets/tactile/tactile_clay_progress.dart';
import '../../../shared/widgets/tactile/tactile_clay_toggle.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../data/assessments_cloud_repository.dart';

class MotherQuizQuestion {
  const MotherQuizQuestion({required this.id, required this.text});

  final String id;
  final String text;
}

class MotherQuizDefinition {
  const MotherQuizDefinition({
    required this.title,
    required this.intro,
    required this.icon,
    required this.questions,
    required this.prefsKey,
  });

  final String title;
  final String intro;
  final IconData icon;
  final List<MotherQuizQuestion> questions;
  final String prefsKey;
}

/// Shell metadata — questions come from published Supabase `assessments`.
final motherQuizShell = <String, MotherQuizDefinition>{
  'skills_test': MotherQuizDefinition(
    title: 'اختبار المهارات',
    intro: 'سجّلي ملاحظاتك عن مهارات طفلك اليومية.',
    icon: Symbols.fact_check,
    prefsKey: 'skills_test_v1',
    questions: const [],
  ),
  'interests_test': MotherQuizDefinition(
    title: 'فحص ميول الطفل وشغفه',
    intro: 'لاحظي ما يجذب انتباه طفلك — يساعدك في اختيار الأنشطة المناسبة.',
    icon: Symbols.interests,
    prefsKey: 'interests_test_v1',
    questions: const [],
  ),
  'child_tests': MotherQuizDefinition(
    title: 'اختبارات الطفل',
    intro:
        'مؤشرات نمو مبكرة لطفلك — ليست تشخيصاً طبياً، بل ملاحظة أمومية تُناقش مع الطبيب عند الحاجة.',
    icon: Symbols.assignment,
    prefsKey: 'child_tests_v1',
    questions: const [],
  ),
};

class MotherQuizScreen extends ConsumerStatefulWidget {
  const MotherQuizScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<MotherQuizScreen> createState() => _MotherQuizScreenState();
}

class _MotherQuizScreenState extends ConsumerState<MotherQuizScreen> {
  final Map<String, bool?> _answers = {};
  int _index = 0;
  bool _prefsLoaded = false;

  MotherQuizDefinition? get _shell => motherQuizShell[widget.quizId];

  void _ensurePrefsLoaded(String prefsKey) {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    final stored = ref.read(prefsServiceProvider).getMotherQuizAnswers(prefsKey);
    if (stored != null) {
      for (final e in stored.entries) {
        _answers[e.key] = e.value;
      }
    }
  }

  Future<void> _setAnswer(String prefsKey, String id, bool value) async {
    setState(() => _answers[id] = value);
    await ref.read(prefsServiceProvider).setMotherQuizAnswers(prefsKey, _answers);
  }

  void _next(int questionCount) {
    if (_index < questionCount - 1) {
      setState(() => _index++);
      return;
    }
    _showDone(questionCount);
  }

  void _showDone(int questionCount) {
    final yes = _answers.values.where((v) => v == true).length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: Text(
          'تم الحفظ',
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'أجبتِ «نعم» على $yes من $questionCount أسئلة.\n\nراجعي النتائج مع طبيب أو مختص عند الحاجة.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = _shell;
    if (shell == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير متوفر')),
        body: const Center(child: Text('الاختبار غير متوفر')),
      );
    }

    final asyncCloud = ref.watch(cloudAssessmentProvider(widget.quizId));

    return asyncCloud.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: QuranTactileAppBar(title: shell.title, onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Scaffold(
        appBar: QuranTactileAppBar(title: shell.title, onBack: () => context.pop()),
        body: const Center(child: Text('تعذّر تحميل الاختبار من السحابة')),
      ),
      data: (cloud) {
        if (cloud == null || cloud.questions.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: QuranTactileAppBar(title: shell.title, onBack: () => context.pop()),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد أسئلة منشورة لهذا الاختبار من الإدارة بعد.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        _ensurePrefsLoaded(shell.prefsKey);

        final questions = [
          for (final q in cloud.questions)
            MotherQuizQuestion(id: q.id, text: q.prompt),
        ];
        final safeIndex = _index.clamp(0, questions.length - 1);
        final q = questions[safeIndex];
        final progress = (safeIndex + 1) / questions.length;
        final babyName = ref.watch(prefsServiceProvider).getBabyName() ?? 'طفلك';
        final theme = Theme.of(context);
        final answer = _answers[q.id];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: QuranTactileAppBar(
            title: cloud.title.isNotEmpty ? cloud.title : shell.title,
            onBack: () => context.pop(),
          ),
          body: Stack(
            children: [
              const BeboShellBackground(showBottomCurve: false),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        shell.intro,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TactileClayProgress(value: progress),
                      const SizedBox(height: 8),
                      Text(
                        'سؤال ${safeIndex + 1} من ${questions.length} — $babyName',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TactileClayCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(shell.icon, color: AppColors.primary, size: 36, fill: 1),
                              const SizedBox(height: 16),
                              Text(
                                q.text,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.4,
                                ),
                              ),
                              const Spacer(),
                              TactileClayToggle(
                                value: answer,
                                onChanged: (v) =>
                                    _setAnswer(shell.prefsKey, q.id, v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TactileClayButton(
                        label: safeIndex < questions.length - 1 ? 'التالي' : 'إنهاء',
                        icon: Symbols.arrow_back,
                        onPressed: answer == null
                            ? null
                            : () => _next(questions.length),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
