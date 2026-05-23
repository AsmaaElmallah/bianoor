import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/onboarding_controller.dart';
import '../domain/baby_profile_model.dart';
import 'widgets/onboarding_progress_dots.dart';

class ChildInfoScreen extends ConsumerStatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  ConsumerState<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends ConsumerState<ChildInfoScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = ref.read(onboardingControllerProvider).name;
    _nameCtrl.addListener(() {
      ref.read(onboardingControllerProvider.notifier).setName(_nameCtrl.text);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Symbols.menu, size: 24),
                  const Spacer(),
                  Text(
                    'المربي اللطيف',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const AppLogoAvatar(size: 40),
                ],
              ),
              const SizedBox(height: 20),
              const OnboardingProgressDots(currentStep: 0, totalSteps: 2),
              const SizedBox(height: 26),
              Text(
                'معلومات الطفل',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لنبدأ بتخصيص تجربة طفلك التعليمية',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              AppTextField(
                label: 'اسم الطفل',
                hint: 'أدخل اسم طفلك هنا',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 12),
              Text(
                'الجنس',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow.withValues(alpha: 0.92),
                  borderRadius: AppRadius.brFull,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _GenderChip(
                        label: 'ذكر',
                        selected: profile.gender == BabyGender.male,
                        onTap: () => ctrl.setGender(BabyGender.male),
                      ),
                    ),
                    Expanded(
                      child: _GenderChip(
                        label: 'أنثى',
                        selected: profile.gender == BabyGender.female,
                        onTap: () => ctrl.setGender(BabyGender.female),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الفئة العمرية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...BabyAgeRange.values.map((range) {
                final selected = profile.ageRange == range;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AgeCard(
                    label: range.label,
                    selected: selected,
                    icon: _ageIcon(range),
                    onTap: () => ctrl.setAgeRange(range),
                    fullWidth: true,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _ageIcon(BabyAgeRange range) {
    switch (range) {
      case BabyAgeRange.age0to3:
        return Symbols.sentiment_satisfied;
      case BabyAgeRange.age3to6:
        return Symbols.bedtime;
      case BabyAgeRange.age6to12:
        return Symbols.directions_car;
      case BabyAgeRange.age1to1_5:
        return Symbols.directions_walk;
      case BabyAgeRange.age1_5to2:
        return Symbols.medical_services;
    }
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
      borderRadius: AppRadius.brFull,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  const _AgeCard({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Material(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.22)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                    fill: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
