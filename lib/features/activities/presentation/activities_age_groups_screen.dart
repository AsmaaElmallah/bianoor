import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../../exercises/data/age_hub_repository.dart';
import '../domain/activities_catalog.dart';

class ActivitiesAgeGroupsScreen extends ConsumerWidget {
  const ActivitiesAgeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroups = ref.watch(activityAgeGroupsProvider);

    return asyncGroups.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _build(activityAgeGroups),
      data: (groups) => _build(groups),
    );
  }

  Widget _build(List<ActivityAgeGroup> groups) {
    return MediaAgeGroupsScreen(
      config: MediaAgeHubConfig.activities,
      heroTitle: 'أنشطة حسب عمر الطفل',
      heroSubtitle: 'لعب إبداعي ومشاركة — اختاري عمر طفلكِ.',
      hubPathBuilder: AppRoutes.activitiesHubPath,
      groups: [
        for (final g in groups)
          MediaAgeGroupCardData(
            id: g.id,
            title: g.title,
            subtitle: g.subtitle,
            icon: g.icon,
            itemCount: g.items.length,
            hasContent: g.items.isNotEmpty,
          ),
      ],
    );
  }
}
