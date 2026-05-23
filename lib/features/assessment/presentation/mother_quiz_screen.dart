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

final motherQuizDefinitions = <String, MotherQuizDefinition>{
  'skills_test': MotherQuizDefinition(
    title: 'اختبار المهارات',
    intro: 'سجّلي ملاحظاتك عن مهارات طفلك اليومية — الإجابات تُحفظ على جهازك.',
    icon: Symbols.fact_check,
    prefsKey: 'skills_test_v1',
    questions: const [
      MotherQuizQuestion(
        id: 's1',
        text: 'هل يمسك الطفل الأشياء الصغيرة بين الإبهام والسبابة؟',
      ),
      MotherQuizQuestion(
        id: 's2',
        text: 'هل يحاول تقليد حركات اليدين (تصفيق، تلويح)؟',
      ),
      MotherQuizQuestion(
        id: 's3',
        text: 'هل يتبع نظرةك إلى جسم متحرك؟',
      ),
      MotherQuizQuestion(
        id: 's4',
        text: 'هل ينتج أصواتاً متنوعة غير البكاء؟',
      ),
      MotherQuizQuestion(
        id: 's5',
        text: 'هل يستجيب لاسمه أو صوتك القريب؟',
      ),
      MotherQuizQuestion(
        id: 's6',
        text: 'هل يجلس بثبات لبضع ثوانٍ دون دعم؟',
      ),
    ],
  ),
  'interests_test': MotherQuizDefinition(
    title: 'فحص ميول الطفل وشغفه',
    intro: 'لاحظي ما يجذب انتباه طفلك — يساعدك في اختيار الأنشطة المناسبة.',
    icon: Symbols.interests,
    prefsKey: 'interests_test_v1',
    questions: const [
      MotherQuizQuestion(
        id: 'i1',
        text: 'هل يهتم بالألوان والأضواء المتحركة؟',
      ),
      MotherQuizQuestion(
        id: 'i2',
        text: 'هل يستمتع بالأصوات الإيقاعية أو الموسيقى الهادئة؟',
      ),
      MotherQuizQuestion(
        id: 'i3',
        text: 'هل يفضّل اللعب بالماء أو الرمل؟',
      ),
      MotherQuizQuestion(
        id: 'i4',
        text: 'هل يتابع وجهك أثناء القراءة أو الغناء؟',
      ),
      MotherQuizQuestion(
        id: 'i5',
        text: 'هل يبدي فرحاً عند رؤية حيوانات أو صور طبيعة؟',
      ),
      MotherQuizQuestion(
        id: 'i6',
        text: 'هل يحب التفاعل مع أطفال آخرين أو مرآة؟',
      ),
    ],
  ),
  'child_tests': MotherQuizDefinition(
    title: 'اختبارات الطفل',
    intro: 'مؤشرات نمو مبكرة لطفلك — ليست تشخيصاً طبياً، بل ملاحظة أمومية تُناقش مع الطبيب عند الحاجة.',
    icon: Symbols.assignment,
    prefsKey: 'child_tests_v1',
    questions: const [
      MotherQuizQuestion(
        id: 'c1',
        text: 'هل يبتسم طفلك استجابة لوجهك أو صوتك؟',
      ),
      MotherQuizQuestion(
        id: 'c2',
        text: 'هل يحاول الدحرجة أو الزحف للأمام؟',
      ),
      MotherQuizQuestion(
        id: 'c3',
        text: 'هل يميّز بين صوتك وصوت غريب؟',
      ),
      MotherQuizQuestion(
        id: 'c4',
        text: 'هل يمسك لعبة ويهزّها أو يضعها في فمه بفضول؟',
      ),
      MotherQuizQuestion(
        id: 'c5',
        text: 'هل يظهر قلقاً عند غيابك لفترة قصيرة؟',
      ),
      MotherQuizQuestion(
        id: 'c6',
        text: 'هل ينام نوماً منتظماً نسبياً ليلاً؟',
      ),
    ],
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

  MotherQuizDefinition? get _def => motherQuizDefinitions[widget.quizId];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final def = _def;
    if (def == null) return;
    final stored = ref.read(prefsServiceProvider).getMotherQuizAnswers(def.prefsKey);
    if (stored != null) {
      for (final e in stored.entries) {
        _answers[e.key] = e.value;
      }
    }
    setState(() {});
  }

  Future<void> _setAnswer(String id, bool value) async {
    final def = _def;
    if (def == null) return;
    setState(() => _answers[id] = value);
    await ref.read(prefsServiceProvider).setMotherQuizAnswers(def.prefsKey, _answers);
  }

  void _next() {
    final def = _def;
    if (def == null) return;
    if (_index < def.questions.length - 1) {
      setState(() => _index++);
      return;
    }
    _showDone();
  }

  void _showDone() {
    final def = _def!;
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
          'أجبتِ «نعم» على $yes من ${def.questions.length} أسئلة.\n\nراجعي النتائج مع طبيب أو مختص عند الحاجة.',
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
    final def = _def;
    if (def == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير متوفر')),
        body: const Center(child: Text('الاختبار غير متوفر')),
      );
    }

    final q = def.questions[_index];
    final progress = (_index + 1) / def.questions.length;
    final babyName = ref.watch(prefsServiceProvider).getBabyName() ?? 'طفلك';
    final theme = Theme.of(context);
    final answer = _answers[q.id];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: def.title, onBack: () => context.pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TactileClayProgress(value: progress, height: 10),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_index == 0) ...[
                            TactileClayCard(
                              child: Row(
                                children: [
                                  Icon(def.icon, color: AppColors.primary, size: 32, fill: 1),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      def.intro,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'السؤال ${_index + 1} من ${def.questions.length}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TactileClayCard(
                            child: Text(
                              q.text.replaceAll('طفلك', babyName),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TactileClayToggle(
                            value: answer,
                            onChanged: (v) => _setAnswer(q.id, v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TactileClayButton(
                    label: _index < def.questions.length - 1 ? 'التالي' : 'إنهاء',
                    icon: Symbols.arrow_back,
                    onPressed: answer == null ? null : _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
