import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/baby_profile_model.dart';
import '../widgets/section_header.dart';

class SleepSection extends ConsumerStatefulWidget {
  const SleepSection({super.key});

  @override
  ConsumerState<SleepSection> createState() => _SleepSectionState();
}

class _SleepSectionState extends ConsumerState<SleepSection> {
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = ref.read(onboardingControllerProvider).behaviorNotes;
    _notesCtrl.addListener(() => ref
        .read(onboardingControllerProvider.notifier)
        .setBehaviorNotes(_notesCtrl.text));
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'النوم والسلوك',
          subtitle: 'ساعدنا في فهم الأنماط اليومية لطفلك لنقدّم الرعاية الأنسب',
          icon: Symbols.bedtime,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('نمط النوم اليومي', style: theme.textTheme.titleMedium),
        ),
        Row(
          children: [
            Expanded(
              child: _PatternCard(
                label: 'منتظم',
                icon: Symbols.bedtime,
                isSelected: profile.sleepPattern == SleepPattern.regular,
                onTap: () => ctrl.setSleepPattern(SleepPattern.regular),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PatternCard(
                label: 'غير منتظم',
                icon: Symbols.nightlight,
                isSelected: profile.sleepPattern == SleepPattern.irregular,
                onTap: () => ctrl.setSleepPattern(SleepPattern.irregular),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.brLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('هل يواجه الطفل أياً مما يلي؟', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ...SleepIssue.values.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IssueTile(
                    title: issue.title,
                    subtitle: issue.subtitle,
                    isSelected: profile.sleepIssues.contains(issue),
                    onTap: () => ctrl.toggleSleepIssue(issue),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: AppRadius.brFull,
              ),
              child: Text(
                'اختياري',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('ملاحظات سلوكية إضافية', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: '',
          hint: 'اكتب هنا أي تفاصيل تلاحظها في سلوك طفلك (مثل: عادات معينة قبل النوم، ردود فعل تجاه أشخاص جدد...)',
          controller: _notesCtrl,
          minLines: 3,
          maxLines: 5,
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected ? AppShadows.primaryGlow : AppShadows.soft,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurface, size: 32, fill: 1),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.onPrimary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
