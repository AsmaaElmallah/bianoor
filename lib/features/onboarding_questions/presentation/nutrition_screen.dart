import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../application/onboarding_controller.dart';
import '../domain/baby_profile_model.dart';
import 'widgets/onboarding_progress_dots.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _SetupBottomNav(activeIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Symbols.menu, color: AppColors.primary),
                  const Spacer(),
                  Text('المربي اللطيف', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const AppLogoAvatar(size: 40),
                ],
              ),
              const SizedBox(height: 20),
              const OnboardingProgressDots(currentStep: 1),
              const SizedBox(height: 26),
              Text(
                'التغذية والنشاط',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text('ساعدنا في تخصيص خطة طفلك من خلال تحديد عاداته اليومية.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Symbols.restaurant, size: 20, color: AppColors.primary, fill: 1),
                  const SizedBox(width: 6),
                  Text(
                    'نوع التغذية الحالية',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'الخطوة التالية',
                icon: Symbols.arrow_forward,
                iconLeading: true,
                height: 58,
                onPressed: () => context.go(AppRoutes.sleep),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'رجوع',
                onPressed: () => context.go(AppRoutes.onboardingQuestions),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
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
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.16)
          : AppColors.surfaceContainerLowest,
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
                child: selected
                    ? const Icon(Symbols.check, size: 12, color: AppColors.primary, fill: 1)
                    : null,
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

class _SetupBottomNav extends StatelessWidget {
  const _SetupBottomNav({required this.activeIndex});
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Symbols.home, 'الرئيسية'),
      (Symbols.menu_book, 'الدروس'),
      (Symbols.auto_graph, 'النمو'),
      (Symbols.settings, 'الإعدادات'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final active = index == activeIndex;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 20, color: active ? AppColors.primary : AppColors.onSurfaceVariant, fill: active ? 1 : 0),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
