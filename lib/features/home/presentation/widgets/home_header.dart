import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/storage/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/arena_identity.dart';
import '../../../auth/application/auth_session_provider.dart';
import '../../../notifications/presentation/notifications_screen.dart';
import '../../../onboarding_questions/data/children_cloud_repository.dart';
import '../../application/home_avatar.dart';
import 'home_side_drawer.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  int _streakDays(PrefsService prefs) {
    final today = DateTime.now();
    final todayIso = today.toIso8601String().split('T').first;
    final yesterdayIso = today.subtract(const Duration(days: 1)).toIso8601String().split('T').first;
    final lasts = [
      prefs.getQuranLastListenDate(),
      prefs.getMathLastSessionDate(),
      prefs.getVisualLastSessionDate(),
      prefs.getEmotionalLastSessionDate(),
    ].whereType<String>().toList();
    if (lasts.isEmpty) return 0;
    final active = lasts.contains(todayIso) || lasts.contains(yesterdayIso);
    if (!active) return 0;
    final starts = [
      prefs.getMathProgramStartDate(),
      prefs.getVisualProgramStartDate(),
      prefs.getEmotionalProgramStartDate(),
    ].whereType<String>().map(DateTime.tryParse).whereType<DateTime>().toList();
    if (starts.isEmpty) return lasts.contains(todayIso) ? 1 : 0;
    starts.sort();
    return today.difference(starts.first).inDays.clamp(1, 99);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(prefsServiceProvider);
    final babyName = ref.watch(activeChildProvider).valueOrNull?.name ?? prefs.getBabyName();
    final greetingName = ref.watch(authSessionProvider).valueOrNull?.displayName;
    final streak = _streakDays(prefs);
    final ageLabel = babyName == null || babyName.isEmpty ? null : 'رحلة $babyName';

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const HomeLogoAvatar(size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      greetingName == null || greetingName.isEmpty
                          ? 'يا ماما'
                          : greetingName.startsWith('أم')
                              ? greetingName
                              : 'أم $greetingName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (ageLabel != null)
                      Text(
                        ageLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (streak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ArenaIdentity.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.local_fire_department, size: 18, color: ArenaIdentity.orange, fill: 1),
                const SizedBox(width: 4),
                Text(
                  '$streak أيام',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ArenaIdentity.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        _RoundIconButton(
          tooltip: 'الإشعارات',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
            );
          },
          child: const Icon(Symbols.notifications, color: AppColors.onSurface, weight: 600, size: 22),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          tooltip: 'القائمة',
          onPressed: () => HomeSideDrawer.open(context),
          child: const Icon(Symbols.menu, color: AppColors.onSurface, weight: 700, size: 22),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
