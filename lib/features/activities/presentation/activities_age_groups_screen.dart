import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../domain/activities_catalog.dart';

class ActivitiesAgeGroupsScreen extends StatelessWidget {
  const ActivitiesAgeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaAgeGroupsScreen(
      config: MediaAgeHubConfig.activities,
      heroTitle: 'أنشطة حسب عمر الطفل',
      heroSubtitle: 'لعب إبداعي ومشاركة — اختاري عمر طفلكِ.',
      hubPathBuilder: AppRoutes.activitiesHubPath,
      groups: [
        for (final g in activityAgeGroups)
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
