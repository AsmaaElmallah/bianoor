import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../ai/presentation/widgets/ai_launcher.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../ai/presentation/widgets/ai_shared.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/timeline_providers.dart';
import '../application/timeline_reminders.dart';
import '../data/timeline_repository.dart';

/// «إمتى؟» — skills and feeding steps by the child's exact age.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(timelineDataProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'إمتى؟', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(timelineDataProvider),
                  child: const Text('حاولي تاني'),
                ),
              ),
              data: (d) {
                if (d.child == null) {
                  return const Center(child: Text('سجلي دخولك وكملي بيانات طفلك الأول.'));
                }
                if (d.ageDays == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Symbols.cake, size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          const Text(
                            'محتاجين تاريخ ميلاد طفلك عشان نعملك جدول مظبوط على سنه.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () async {
                              await context.push(AppRoutes.growth);
                              ref.invalidate(timelineDataProvider);
                            },
                            child: const Text('سجلي تاريخ الميلاد'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final current = d.current;
                final upcoming = d.upcoming.take(6).toList();
                final past = d.past;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      'الجدول ده متظبط على عمر ${d.child!.name} بالأيام — مهارات وأكل حسب سنه.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.stoolColors),
                      icon: const Icon(Symbols.palette),
                      label: const Text('كارت ألوان البراز'),
                    ),
                    _RemindersSwitch(data: d),
                    const SizedBox(height: 8),
                    _SectionTitle('دلوقتي'),
                    if (current.isEmpty)
                      Text(
                        'مفيش حاجة مستعجلة دلوقتي 💛',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    for (final i in current) _ItemCard(item: i, data: d),
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionTitle('الجاي'),
                      for (final i in upcoming) _ItemCard(item: i, data: d, compact: true),
                    ],
                    if (past.isNotEmpty)
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'اللي فات (${past.length})',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          children: [for (final i in past) _ItemCard(item: i, data: d, compact: true)],
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

class _RemindersSwitch extends ConsumerStatefulWidget {
  const _RemindersSwitch({required this.data});

  final TimelineData data;

  @override
  ConsumerState<_RemindersSwitch> createState() => _RemindersSwitchState();
}

class _RemindersSwitchState extends ConsumerState<_RemindersSwitch> {
  late bool _on = ref.read(prefsServiceProvider).getTimelineReminders();

  Future<void> _set(bool on) async {
    setState(() => _on = on);
    await ref.read(prefsServiceProvider).setTimelineReminders(on);
    if (on) {
      await TimelineReminders.instance.sync(widget.data, force: true);
    } else {
      await TimelineReminders.instance.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _on,
      onChanged: _set,
      secondary: const Icon(Symbols.notifications_active, color: AppColors.primary),
      title: const Text('فكّريني بالمواعيد'),
      subtitle: const Text('إشعار لكل مهارة أو أكلة جديدة حسب عمر طفلك'),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );
}

(IconData, Color, String) timelineKindStyle(TimelineKind kind) => switch (kind) {
      TimelineKind.development => (Symbols.child_care, AppColors.tertiaryDim, 'مهارة'),
      TimelineKind.feeding => (Symbols.restaurant, AppColors.primary, 'أكل'),
    };

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.data, this.compact = false});

  final TimelineItem item;
  final TimelineData data;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (icon, color, _) = timelineKindStyle(item.kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
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
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Text(
                timelineWhen(item.ageDays, data.ageDays!),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(item.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ],
          if (!compact && item.tips.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final t in item.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $t', style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
              ),
          ],
          if (!compact)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  final q = item.kind == TimelineKind.feeding
                      ? 'عايزة أعرف أكتر عن: ${item.title}'
                      : 'إزاي أساعد طفلي في: ${item.title}؟';
                  showAiChatPopup(context, initialQuestion: q);
                },
                icon: const Icon(Symbols.chat, size: 18),
                label: const Text('اسألي مساعدة بيانور'),
              ),
            ),
          if (!compact && item.sourceName.isNotEmpty)
            InkWell(
              onTap: item.sourceUrl == null ? null : () => openAiLink(context, item.sourceUrl!),
              child: Text(
                'المصدر: ${item.sourceName}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: item.sourceUrl == null ? AppColors.onSurfaceVariant : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
