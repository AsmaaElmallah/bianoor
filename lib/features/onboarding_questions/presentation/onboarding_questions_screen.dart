import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/onboarding_controller.dart';
import 'sections/baby_info_section.dart';
import 'sections/nutrition_section.dart';
import 'sections/skills_section.dart';
import 'sections/sleep_section.dart';

class OnboardingQuestionsScreen extends ConsumerStatefulWidget {
  const OnboardingQuestionsScreen({super.key});

  @override
  ConsumerState<OnboardingQuestionsScreen> createState() =>
      _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState
    extends ConsumerState<OnboardingQuestionsScreen> {
  Future<void> _onSubmit() async {
    final profile = ref.read(onboardingControllerProvider);
    final prefs = ref.read(prefsServiceProvider);

    if (profile.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخلي اسم الطفل')),
      );
      return;
    }

    await prefs.setBabyName(profile.name.trim());
    await prefs.setOnboardingComplete(true);

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.close, color: AppColors.primary),
          onPressed: () => context.go(AppRoutes.subscription),
        ),
        title: Text(
          'رحلة طفلك التعليمية',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Banner(),
              const SizedBox(height: 24),

              const BabyInfoSection(),
              const _SectionDivider(),

              const SkillsSection(),
              const _SectionDivider(),

              const NutritionSection(),
              const _SectionDivider(),

              const SleepSection(),

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'إنهاء وإرسال',
                icon: Symbols.send,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '"كل طفل يتعلم بطريقته الخاصة ويسير عبر الخاصة"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.6),
            AppColors.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: AppRadius.brXl,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Symbols.psychology, color: AppColors.primary, size: 30, fill: 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قبل أن نبدأ', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'الإجابة على هذه الأسئلة تساعدنا في تقديم خطة تعليمية تناسب طفلك تماماً.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
