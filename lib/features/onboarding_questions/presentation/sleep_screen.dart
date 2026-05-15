import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../application/onboarding_controller.dart';
import '../domain/baby_profile_model.dart';
import 'widgets/onboarding_progress_dots.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = ref.read(onboardingControllerProvider).behaviorNotes;
    _notesCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setBehaviorNotes(_notesCtrl.text);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.nutrition),
                    icon: const Icon(Symbols.close, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'المربي اللطيف',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const AppLogoAvatar(size: 38),
                ],
              ),
              const SizedBox(height: 14),
              const OnboardingProgressDots(currentStep: 2),
              const SizedBox(height: 30),
              Text(
                'النوم والسلوك',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'ساعدنا في فهم الأنماط اليومية لطفلك لنقدّم الرعاية الأنسب.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ملاحظات سلوكية إضافية', style: theme.textTheme.titleLarge),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00FBF9F5), Color(0xCCFBF9F5), Color(0xFFFBF9F5)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;
            final primary = PrimaryButton(
              label: 'الخطوة التالية',
              icon: Symbols.arrow_forward,
              iconLeading: true,
              height: 62,
              onPressed: () => context.go(AppRoutes.skills),
            );
            final secondary = SecondaryButton(
              label: 'رجوع',
              icon: Symbols.arrow_forward,
              onPressed: () => context.go(AppRoutes.nutrition),
              fullWidth: true,
            );
            if (narrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  primary,
                  const SizedBox(height: 10),
                  secondary,
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: secondary,
                ),
              ],
            );
          },
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
                child: selected
                    ? const Icon(Symbols.check, size: 14, color: AppColors.primary, fill: 1)
                    : null,
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.9)),
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
