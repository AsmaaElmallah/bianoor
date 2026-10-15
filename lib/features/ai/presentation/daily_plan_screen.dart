import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/ai_providers.dart';
import '../data/ai_models.dart';
import 'widgets/ai_launcher.dart';
import 'widgets/ai_shared.dart';

/// تفاصيل «خطة النهارده» الذكية.
class DailyPlanScreen extends ConsumerWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final babyName = ref.watch(prefsServiceProvider).getBabyName();
    final async = ref.watch(aiDailyPlanProvider);
    String t(String s) => withBabyName(s, babyName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'خطة النهارده', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Retry(onRetry: () => ref.invalidate(aiDailyPlanProvider)),
              data: (result) {
                final plan = result.plan;
                if (plan == null) {
                  return _Retry(
                    message: aiStatusText(result.status, result.detail),
                    onRetry: () => ref.invalidate(aiDailyPlanProvider),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (plan.tip.isNotEmpty)
                      _Section(
                        color: AppColors.primaryContainer,
                        icon: Symbols.lightbulb,
                        title: 'نصيحة النهارده',
                        child: Text(t(plan.tip), style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
                      ),
                    for (final a in plan.activities)
                      _Section(
                        color: AppColors.surfaceContainerLowest,
                        icon: Symbols.toys,
                        title: '${t(a.title)} • ${a.minutes} دقايق',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (a.why.isNotEmpty)
                              Text(
                                t(a.why),
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < a.steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('${i + 1}. ${t(a.steps[i])}', style: theme.textTheme.bodyMedium),
                              ),
                          ],
                        ),
                      ),
                    if (plan.quranMoment.isNotEmpty)
                      _Section(
                        color: AppColors.trackQuranLight,
                        icon: Symbols.menu_book,
                        title: 'لحظة قرآن',
                        child: Text(t(plan.quranMoment), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                      ),
                    const SizedBox(height: 4),
                    AiSourcesRow(sources: plan.sources),
                    const SizedBox(height: 16),
                    const AiDisclaimer(),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showAiChatPopup(context),
                      icon: const Icon(Symbols.chat),
                      label: const Text('عندك سؤال؟ اسألي مساعدة بيانور'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.color, required this.icon, required this.title, required this.child});

  final Color color;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.brLg,
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'تعذّر تحميل الخطة', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('جربي تاني')),
          ],
        ),
      ),
    );
  }
}
