import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../bebo_shell_background.dart';
import '../floating_decoration.dart';
import '../tactile/tactile_clay_card.dart';
import 'media_age_hub_config.dart';
import 'media_age_tactile_header.dart';

class MediaAgeGroupCardData {
  const MediaAgeGroupCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.itemCount,
    required this.hasContent,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final int itemCount;
  final bool hasContent;
}

/// شاشة اختيار العمر — tamareen-ansheta.
class MediaAgeGroupsScreen extends StatelessWidget {
  const MediaAgeGroupsScreen({
    super.key,
    required this.config,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.groups,
    required this.hubPathBuilder,
  });

  final MediaAgeHubConfig config;
  final String heroTitle;
  final String heroSubtitle;
  final List<MediaAgeGroupCardData> groups;
  final String Function(String groupId) hubPathBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MediaAgeHubConfig.exercises.scaffoldBackground,
      body: Column(
        children: [
          MediaAgeTactileHeader(
            title: config.kindLabel,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Stack(
              children: [
                const BeboShellBackground(showBottomCurve: false),
                SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      TactileClayCard(
                        color: config.accentColor.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: FloatingDecoration(
                                child: Icon(
                                  config.kindLabel == 'تمارين'
                                      ? Symbols.fitness_center
                                      : Symbols.sports_esports,
                                  color: config.accentColor,
                                  size: 40,
                                  fill: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    heroTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    heroSubtitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'اختاري عمر الطفل',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...groups.map((group) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TactileClayCard(
                            onTap: () => context.push(hubPathBuilder(group.id)),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: group.hasContent
                                        ? AppColors.primaryContainer.withValues(alpha: 0.45)
                                        : AppColors.surfaceContainerHigh,
                                    borderRadius: AppRadius.brMd,
                                    boxShadow: AppShadows.clayLift,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    group.icon,
                                    color: group.hasContent
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    size: 28,
                                    fill: 1,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.title,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        group.hasContent
                                            ? '${group.subtitle} • ${group.itemCount} مقطع'
                                            : '${group.subtitle} • قريباً',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  group.hasContent
                                      ? Symbols.chevron_left
                                      : Symbols.schedule,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
