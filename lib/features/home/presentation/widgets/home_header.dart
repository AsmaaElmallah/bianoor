import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/app_logo_avatar.dart';

class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key, this.motherName = 'سارة'});

  final String motherName;

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  int _devTapCount = 0;

  void _onLogoTap() {
    if (!kDebugMode) return;
    _devTapCount += 1;
    if (_devTapCount >= 5) {
      _devTapCount = 0;
      context.push(AppRoutes.devTools);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final babyName = ref.watch(prefsServiceProvider).getBabyName();
    final greetingName = widget.motherName;

    return Row(
      children: [
        GestureDetector(
          onTap: _onLogoTap,
          child: const AppLogoAvatar(size: 48),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلاً، $greetingName',
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
            icon: const Icon(Icons.notifications_outlined, color: AppColors.tertiary, size: 24),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
