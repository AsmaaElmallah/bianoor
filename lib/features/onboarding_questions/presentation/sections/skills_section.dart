import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/onboarding_controller.dart';
import '../widgets/section_header.dart';

class SkillsSection extends ConsumerStatefulWidget {
  const SkillsSection({super.key});

  @override
  ConsumerState<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<SkillsSection> {
  final _strengthsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingControllerProvider);
    _strengthsCtrl.text = profile.strengths;
    _challengesCtrl.text = profile.challenges;
    _detailsCtrl.text = profile.specialNeedsDetails;
    _strengthsCtrl.addListener(() => ref
        .read(onboardingControllerProvider.notifier)
        .setStrengths(_strengthsCtrl.text));
    _challengesCtrl.addListener(() => ref
        .read(onboardingControllerProvider.notifier)
        .setChallenges(_challengesCtrl.text));
    _detailsCtrl.addListener(() => ref
        .read(onboardingControllerProvider.notifier)
        .setSpecialNeedsDetails(_detailsCtrl.text));
  }

  @override
  void dispose() {
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    _detailsCtrl.dispose();
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
          title: 'رحلة طفلك التعليمية',
          subtitle: 'ساعدنا في تخصيص المحتوى المناسب لطفلك من خلال فهم مهاراته الحالية',
          icon: Symbols.flag,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
        ),
        const SizedBox(height: 24),

        AppTextField(
          label: 'نقاط القوة لدى الطفل',
          hint: 'ما الأشياء التي يتميز بها طفلك؟ (مثل: الرسم، حل الألغاز، الخيال الواسع...)',
          controller: _strengthsCtrl,
          minLines: 3,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'التحديات التي يواجهها',
          hint: 'ما المهارات التي يحتاج طفلك لتطويرها؟ (مثل: التركيز، المهارات الحركية، التفاعل الاجتماعي...)',
          controller: _challengesCtrl,
          minLines: 3,
          maxLines: 5,
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: AppRadius.brLg,
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Symbols.support_agent, color: AppColors.onSecondaryContainer, fill: 1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('احتياجات خاصة', style: theme.textTheme.titleMedium),
                        Text(
                          'هل يحتاج الطفل إلى دعم إضافي أو أدوات مساعدة؟',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: profile.hasSpecialNeeds,
                    onChanged: ctrl.setHasSpecialNeeds,
                  ),
                ],
              ),
              if (profile.hasSpecialNeeds) ...[
                const SizedBox(height: 12),
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
      ],
    );
  }
}
