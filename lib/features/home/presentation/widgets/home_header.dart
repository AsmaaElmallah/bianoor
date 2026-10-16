import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_art.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_session_provider.dart';
import '../../../auth/presentation/settings_screen.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../application/home_avatar.dart';
import '../../../notifications/presentation/notifications_screen.dart';
import '../../../onboarding_questions/data/children_cloud_repository.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final babyName = ref.watch(activeChildProvider).valueOrNull?.name ??
        ref.watch(prefsServiceProvider).getBabyName();
    final greetingName = ref.watch(authSessionProvider).valueOrNull?.displayName;

    return Row(
      children: [
        const HomeLogoAvatar(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingName == null ? 'أهلاً يا ماما' : 'أهلاً، $greetingName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              if (babyName != null && babyName.isNotEmpty)
                Text(
                  'رحلة $babyName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.brFull,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: AppShadows.clayLift,
          ),
          child: IconButton(
            icon: Image.asset(AppArt.gear, width: 28, height: 28),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.brFull,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: AppShadows.clayLift,
          ),
          child: IconButton(
            icon: Image.asset(AppArt.bell, width: 28, height: 28),
            tooltip: 'الإشعارات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
