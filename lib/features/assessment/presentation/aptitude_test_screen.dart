import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/floating_decoration.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../../shared/widgets/tactile/tactile_clay_progress.dart';
import '../../../shared/widgets/tactile/tactile_clay_toggle.dart';
import '../domain/aptitude_test_0_2_data.dart';

class AptitudeTestScreen extends ConsumerStatefulWidget {
  const AptitudeTestScreen({super.key});

  @override
  ConsumerState<AptitudeTestScreen> createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends ConsumerState<AptitudeTestScreen> {
  final Map<String, bool?> _answers = {};
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _loaded = false;

  static const _stepCount = 4;

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadAnswers() {
    final stored = ref.read(prefsServiceProvider).getAptitudeTestAnswers();
    if (stored != null) {
      for (final entry in stored.entries) {
        _answers[entry.key] = entry.value;
      }
    }
    setState(() => _loaded = true);
  }

  Future<void> _setAnswer(String questionId, bool value) async {
    setState(() => _answers[questionId] = value);
    await ref.read(prefsServiceProvider).setAptitudeTestAnswers(_answers);
  }

  AptitudeTestCategory get _category => aptitudeTest0to2Categories[_currentStep];

  int _answeredInCategory(AptitudeTestCategory category) {
    var count = 0;
    for (final q in category.questions) {
      if (_answers[q.id] != null) count++;
    }
    return count;
  }

  bool get _currentStepComplete =>
      _answeredInCategory(_category) == _category.questions.length;

  int get _totalYesCount => _answers.values.where((v) => v == true).length;

  void _goNext() {
    if (_currentStep < _stepCount - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _showCompletionDialog();
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        title: Text(
          'أحسنتِ!',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'تم حفظ إجاباتك. إجابات «نعم»: $_totalYesCount من $aptitudeTest0to2QuestionCount.\n\nاستشيري طبيب الأطفال إذا كان لديكِ قلق.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
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
    final babyName = ref.watch(prefsServiceProvider).getBabyName() ?? 'طفلك';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _AptitudeTactileHeader(onBack: () => context.pop()),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stepCount,
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    itemBuilder: (context, index) {
                      final category = aptitudeTest0to2Categories[index];
                      return _StepPage(
                        stepIndex: index,
                        category: category,
                        babyName: babyName,
                        answers: _answers,
                        onAnswer: _setAnswer,
                        showInstructions: index == 0,
                      );
                    },
                  ),
                ),
                _BottomActions(
                  currentStep: _currentStep,
                  stepCount: _stepCount,
                  canGoNext: _currentStepComplete,
                  onBack: _goBack,
                  onNext: _goNext,
                ),
              ],
            ),
    );
  }
}

class _AptitudeTactileHeader extends StatelessWidget {
  const _AptitudeTactileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLow,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: AppShadows.clayLift,
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                color: AppColors.primary,
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  aptitudeTest0to2ScreenTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppLogoAvatar(
                size: 40,
                imageAsset: AppAssets.logoBaby,
                backgroundColor: AppColors.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.stepIndex,
    required this.category,
    required this.babyName,
    required this.answers,
    required this.onAnswer,
    required this.showInstructions,
  });

  final int stepIndex;
  final AptitudeTestCategory category;
  final String babyName;
  final Map<String, bool?> answers;
  final Future<void> Function(String questionId, bool value) onAnswer;
  final bool showInstructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = category.questions
        .where((q) => answers[q.id] != null)
        .length;
    final stepProgress = (stepIndex + 1) / aptitudeTest0to2Categories.length;
    final categoryProgress =
        category.questions.isEmpty ? 0.0 : answered / category.questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: AppRadius.brFull,
                      boxShadow: AppShadows.soft,
                    ),
                    child: Text(
                      aptitudeStageLabel(stepIndex),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${stepIndex + 1} / ${aptitudeTest0to2Categories.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TactileClayProgress(value: stepProgress, height: 16),
        const SizedBox(height: 8),
        Text(
          'هذه المرحلة: $answered / ${category.questions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TactileClayCard(
          color: AppColors.primaryContainer.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: FloatingDecoration(
                  amplitude: 8,
                  child: Image.asset(
                    AppAssets.mascotGirlStanding,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      AppAssets.logoBaby,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aptitudeEncouragementMessage(babyName, stepIndex),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أجيبي بـ «نعم» أو «لا» بناءً على ملاحظاتك.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showInstructions) ...[
          const SizedBox(height: 14),
          TactileClayCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كيف تستخدمين الاختبار',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...aptitudeTest0to2Instructions.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $line', style: theme.textTheme.bodyMedium),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...category.questions.map(
          (question) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _QuestionClayCard(
              question: question,
              categoryIcon: category.icon,
              answer: answers[question.id],
              onAnswer: (v) => onAnswer(question.id, v),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _MedicalInfoBox(showFullNote: stepIndex == aptitudeTest0to2Categories.length - 1),
        if (categoryProgress < 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'أجيبي على كل الأسئلة في هذه المرحلة للمتابعة.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuestionClayCard extends StatelessWidget {
  const _QuestionClayCard({
    required this.question,
    required this.categoryIcon,
    required this.answer,
    required this.onAnswer,
  });

  final AptitudeTestQuestion question;
  final IconData categoryIcon;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(categoryIcon, color: AppColors.tertiary, size: 24, fill: 1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '(${question.ageRange})',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TactileClayToggle(
            value: answer,
            onChanged: onAnswer,
          ),
        ],
      ),
    );
  }
}

class _MedicalInfoBox extends StatelessWidget {
  const _MedicalInfoBox({required this.showFullNote});

  final bool showFullNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadius.brLg,
        border: Border(
          right: BorderSide(color: AppColors.primary, width: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.info, color: AppColors.primary, size: 22, fill: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showFullNote
                  ? 'استشيري طبيب الأطفال إذا كان لديكِ قلق حول وتيرة نمو طفلك. هذا الاختبار أداة ملاحظة وليست تشخيصاً طبياً.'
                  : 'استشيري طبيب الأطفال إذا كان لديكِ قلق حول وتيرة نمو طفلك.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.currentStep,
    required this.stepCount,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final int stepCount;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == stepCount - 1;
    final nextLabel = isLast ? 'إنهاء' : 'التالي';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.92),
            AppColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('السابق'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          TactileClayButton(
            label: nextLabel,
            icon: isLast ? Symbols.check_circle : Symbols.chevron_left,
            onPressed: canGoNext ? onNext : null,
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            depthColor: AppColors.primaryDim,
            height: 58,
          ),
        ],
      ),
    );
  }
}
