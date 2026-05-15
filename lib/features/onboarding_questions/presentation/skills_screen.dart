import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_progress_dots.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
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
    _strengthsCtrl.dispose();
    _challengesCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final profile = ref.read(onboardingControllerProvider);
    if (profile.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخلي اسم الطفل أولًا')),
      );
      return;
    }
    final prefs = ref.read(prefsServiceProvider);
    await prefs.setBabyName(profile.name.trim());
    await prefs.setOnboardingComplete(true);
    if (mounted) context.go(AppRoutes.home);
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
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.sleep),
                    icon: const Icon(Symbols.close, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'المهارات والقدرات',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 8),
              const OnboardingProgressDots(currentStep: 3),
              const SizedBox(height: 24),
              Text(
                'رحلة طفلك التعليمية',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ساعدنا في تخصيص المحتوى المناسب لطفلك من خلال فهم مهاراته الحالية.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 12),
              Container(
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(12),
                child: Text(
                  '"كل طفل يتعلم بطريقته الخاصة ويسير عند الخاصة"',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0x99FFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'إنهاء وإرسال',
                height: 58,
                onPressed: _submit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'السابق',
                onPressed: () => context.go(AppRoutes.sleep),
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
