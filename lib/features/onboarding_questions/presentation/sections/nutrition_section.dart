import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/baby_profile_model.dart';
import '../widgets/section_header.dart';

class NutritionSection extends ConsumerWidget {
  const NutritionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'التغذية والنشاط',
          subtitle: 'ساعدنا في تخصيص خطة طفلك من خلال تحديد عاداته اليومية',
          icon: Symbols.restaurant,
          iconBg: AppColors.tertiaryContainer,
          iconColor: AppColors.onTertiaryContainer,
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(Symbols.lunch_dining, size: 18, color: AppColors.tertiary, fill: 1),
              const SizedBox(width: 8),
              Text(
                'نوع التغذية الحالية',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        ...NutritionType.values.map((type) {
          final isSelected = profile.nutrition == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NutritionTile(
              type: type,
              isSelected: isSelected,
              onTap: () => ctrl.setNutrition(type),
            ),
          );
        }),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.brLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('النشاط البدني اليومي', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'هل يمارس طفلك أنشطة حركية منظمة أو لعباً حراً لمدة لا تقل عن 30 دقيقة يومياً؟',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadius.brFull,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _YesNoToggle(
                        label: 'نعم',
                        isSelected: profile.hasPhysicalActivity,
                        onTap: () => ctrl.setHasPhysicalActivity(true),
                      ),
                    ),
                    Expanded(
                      child: _YesNoToggle(
                        label: 'لا',
                        isSelected: !profile.hasPhysicalActivity,
                        onTap: () => ctrl.setHasPhysicalActivity(false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  const _NutritionTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final NutritionType type;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case NutritionType.breastfeeding:
        return Symbols.favorite;
      case NutritionType.formula:
        return Symbols.water_drop;
      case NutritionType.balanced:
        return Symbols.balance;
      case NutritionType.irregular:
        return Symbols.error;
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              _RadioDot(isSelected: isSelected),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(_icon, color: isSelected ? AppColors.primary : AppColors.tertiary, size: 22, fill: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
    );
  }
}

class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
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
                    color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
