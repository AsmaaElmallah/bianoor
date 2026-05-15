import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../application/onboarding_controller.dart';
import '../domain/baby_profile_model.dart';
import 'widgets/onboarding_progress_dots.dart';

/// تغذية + نوم وسلوك + مهارات في صفحة واحدة مع تمرير وزر إرسال واحد في النهاية.
class OnboardingSurveyScreen extends ConsumerStatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  ConsumerState<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends ConsumerState<OnboardingSurveyScreen> {
  final _notesCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = ref.read(onboardingControllerProvider);
    _notesCtrl.text = p.behaviorNotes;
    _strengthsCtrl.text = p.strengths;
    _challengesCtrl.text = p.challenges;
    _detailsCtrl.text = p.specialNeedsDetails;
    _notesCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setBehaviorNotes(_notesCtrl.text);
    });
    _strengthsCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setStrengths(_strengthsCtrl.text);
    });
    _challengesCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setChallenges(_challengesCtrl.text);
    });
    _detailsCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setSpecialNeedsDetails(_detailsCtrl.text);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profile = ref.read(onboardingControllerProvider);
    if (profile.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخلي اسم الطفل من صفحة المعلومات أولًا')),
      );
      return;
    }
    final prefs = ref.read(prefsServiceProvider);
    await prefs.setBabyName(profile.name.trim());
    await prefs.setBabyAgeRangeIndex(BabyAgeRange.values.indexOf(profile.ageRange));
    await prefs.setOnboardingComplete(true);
    if (mounted) context.go(AppRoutes.home);
  }

  static IconData _nutritionIcon(NutritionType type) {
    switch (type) {
      case NutritionType.breastfeeding:
        return Symbols.favorite;
      case NutritionType.formula:
        return Symbols.vaccines;
      case NutritionType.balanced:
        return Symbols.balance;
      case NutritionType.irregular:
        return Symbols.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.onboardingQuestions),
                    icon: const Icon(Symbols.arrow_forward, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'المربي اللطيف',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const AppLogoAvatar(size: 40),
                ],
              ),
              const SizedBox(height: 16),
              const OnboardingProgressDots(currentStep: 1, totalSteps: 2),
              const SizedBox(height: 8),
              Text(
                'استبيان الطفل',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'أجيبي عن كل الأقسام التالية، ثم اضغطي «إرسال» في آخر الصفحة.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              _SectionTitle(icon: Symbols.restaurant, title: 'التغذية والنشاط'),
              const SizedBox(height: 8),
              Text(
                'ساعدنا في تخصيص خطة طفلك من خلال تحديد عاداته اليومية.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Symbols.restaurant, size: 20, color: AppColors.primary, fill: 1),
                  const SizedBox(width: 6),
                  Text('نوع التغذية الحالية', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...NutritionType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NutritionRow(
                    label: type.label,
                    icon: _nutritionIcon(type),
                    selected: profile.nutrition == type,
                    onTap: () => ctrl.setNutrition(type),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('النشاط البدني اليومي', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'هل يمارس طفلك نشاطًا يوميًا لمدة لا تقل عن 30 دقيقة؟',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: AppRadius.brFull,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _YesNoChip(
                              text: 'نعم',
                              selected: profile.hasPhysicalActivity,
                              onTap: () => ctrl.setHasPhysicalActivity(true),
                            ),
                          ),
                          Expanded(
                            child: _YesNoChip(
                              text: 'لا',
                              selected: !profile.hasPhysicalActivity,
                              onTap: () => ctrl.setHasPhysicalActivity(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _SectionTitle(icon: Symbols.bedtime, title: 'النوم والسلوك'),
              const SizedBox(height: 8),
              Text(
                'ساعدنا في فهم الأنماط اليومية لطفلك لنقدّم الرعاية الأنسب.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text('نمط النوم اليومي', style: theme.textTheme.titleLarge),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SleepPatternCard(
                      title: 'منتظم',
                      icon: Symbols.bedtime,
                      selected: profile.sleepPattern == SleepPattern.regular,
                      onTap: () => ctrl.setSleepPattern(SleepPattern.regular),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SleepPatternCard(
                      title: 'غير منتظم',
                      icon: Symbols.nightlight,
                      selected: profile.sleepPattern == SleepPattern.irregular,
                      onTap: () => ctrl.setSleepPattern(SleepPattern.irregular),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('هل يواجه الطفل أيًا مما يلي؟', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 14),
                    ...SleepIssue.values.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _IssueRow(
                          title: issue.title,
                          subtitle: issue.subtitle,
                          selected: profile.sleepIssues.contains(issue),
                          onTap: () => ctrl.toggleSleepIssue(issue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('ملاحظات سلوكية إضافية', style: theme.textTheme.titleLarge)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: AppRadius.brFull,
                    ),
                    child: Text(
                      'اختياري',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: '',
                hint: 'اكتب هنا أي تفاصيل تلاحظها في سلوك طفلك...',
                controller: _notesCtrl,
                minLines: 4,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              _SectionTitle(icon: Symbols.psychology, title: 'المهارات والقدرات'),
              const SizedBox(height: 8),
              Text(
                'ساعدنا في تخصيص المحتوى المناسب لطفلك من خلال فهم مهاراته الحالية.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'نقاط القوة لدى الطفل',
                hint: 'ما هي الأشياء التي يتميز بها طفلك؟',
                controller: _strengthsCtrl,
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'التحديات التي يواجهها',
                hint: 'ما هي المهارات التي يحتاج طفلك لتطويرها؟',
                controller: _challengesCtrl,
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Symbols.support_agent, color: AppColors.onSecondaryContainer, fill: 1),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('احتياجات خاصة', style: theme.textTheme.titleMedium),
                              Text(
                                'هل يحتاج الطفل إلى دعم إضافي أو أدوات مساعدة؟',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: profile.hasSpecialNeeds,
                            onChanged: ctrl.setHasSpecialNeeds,
                          ),
                        ),
                      ],
                    ),
                    if (profile.hasSpecialNeeds) ...[
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'تفاصيل إضافية',
                        hint: 'يرجى توضيح نوع الدعم المطلوب...',
                        controller: _detailsCtrl,
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '"كل طفل يتعلم بطريقته الخاصة ويسير عند الخاصة"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'إرسال وحفظ',
                icon: Symbols.send,
                height: 60,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'تعديل معلومات الطفل',
                onPressed: () => context.go(AppRoutes.onboardingQuestions),
                fullWidth: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 26, fill: 1),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryContainer.withValues(alpha: 0.16) : AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: 1.8,
                  ),
                  color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Symbols.check, size: 12, color: AppColors.primary, fill: 1) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ),
              Icon(icon, color: AppColors.primary, size: 20, fill: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _YesNoChip extends StatelessWidget {
  const _YesNoChip({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brFull,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepPatternCard extends StatelessWidget {
  const _SleepPatternCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            color: AppColors.surfaceContainerLowest,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.onSurfaceVariant, size: 34, fill: 1),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                    width: 2,
                  ),
                  color: Colors.transparent,
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Symbols.check, size: 14, color: AppColors.primary, fill: 1) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
