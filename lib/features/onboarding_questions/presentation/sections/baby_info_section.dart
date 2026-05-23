import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/baby_profile_model.dart';
import '../widgets/section_header.dart';
import '../widgets/selectable_card.dart';

class BabyInfoSection extends ConsumerStatefulWidget {
  const BabyInfoSection({super.key});

  @override
  ConsumerState<BabyInfoSection> createState() => _BabyInfoSectionState();
}

class _BabyInfoSectionState extends ConsumerState<BabyInfoSection> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = ref.read(onboardingControllerProvider).name;
    _nameCtrl.addListener(_handleNameChanged);
  }

  void _handleNameChanged() {
    ref.read(onboardingControllerProvider.notifier).setName(_nameCtrl.text);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_handleNameChanged);
    _nameCtrl.dispose();
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
          title: 'معلومات الطفل',
          subtitle: 'لنبدأ بتخصيص تجربة طفلك التعليمية',
          icon: Symbols.child_care,
          iconBg: AppColors.primaryContainer,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 24),

        AppTextField(
          label: 'اسم الطفل',
          hint: 'أدخل اسم طفلك هنا',
          icon: Symbols.badge,
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'الجنس',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.brFull,
          ),
          child: Row(
            children: [
              Expanded(
                child: _GenderToggle(
                  label: 'ذكر',
                  isSelected: profile.gender == BabyGender.male,
                  onTap: () => ctrl.setGender(BabyGender.male),
                ),
              ),
              Expanded(
                child: _GenderToggle(
                  label: 'أنثى',
                  isSelected: profile.gender == BabyGender.female,
                  onTap: () => ctrl.setGender(BabyGender.female),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'الفئة العمرية',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...BabyAgeRange.values.map((age) {
          final isSelected = profile.ageRange == age;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableCard(
              label: age.label,
              icon: _ageIcon(age),
              isSelected: isSelected,
              onTap: () => ctrl.setAgeRange(age),
              iconBg: _ageBg(age),
              iconColor: _ageColor(age),
            ),
          );
        }),
      ],
    );
  }

  IconData _ageIcon(BabyAgeRange a) {
    switch (a) {
      case BabyAgeRange.age0to3:
        return Symbols.sentiment_satisfied;
      case BabyAgeRange.age3to6:
        return Symbols.stroller;
      case BabyAgeRange.age6to12:
        return Symbols.directions_car;
      case BabyAgeRange.age1to1_5:
        return Symbols.directions_walk;
      case BabyAgeRange.age1_5to2:
        return Symbols.smart_toy;
    }
  }

  Color _ageBg(BabyAgeRange a) {
    switch (a) {
      case BabyAgeRange.age0to3:
        return AppColors.ageWarmBg;
      case BabyAgeRange.age3to6:
        return AppColors.primaryContainer;
      case BabyAgeRange.age6to12:
        return AppColors.tertiaryContainer;
      case BabyAgeRange.age1to1_5:
        return AppColors.ageOrangeBg;
      case BabyAgeRange.age1_5to2:
        return AppColors.primaryContainer;
    }
  }

  Color _ageColor(BabyAgeRange a) {
    switch (a) {
      case BabyAgeRange.age0to3:
        return AppColors.ageWarmText;
      case BabyAgeRange.age3to6:
        return AppColors.primary;
      case BabyAgeRange.age6to12:
        return AppColors.tertiary;
      case BabyAgeRange.age1to1_5:
        return AppColors.ageOrangeText;
      case BabyAgeRange.age1_5to2:
        return AppColors.primary;
    }
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
      borderRadius: AppRadius.brFull,
      elevation: isSelected ? 1 : 0,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
