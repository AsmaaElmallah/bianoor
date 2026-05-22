import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../domain/exercises_catalog.dart';

class ExercisesAgeGroupsScreen extends StatelessWidget {
  const ExercisesAgeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaAgeGroupsScreen(
      config: MediaAgeHubConfig.exercises,
      heroTitle: 'تمارين الأطفال حسب العمر',
      heroSubtitle: 'اختاري عمر طفلكِ لمشاهدة التمارين والمساج المناسب.',
      hubPathBuilder: AppRoutes.exercisesHubPath,
      groups: [
        for (final g in exerciseAgeGroups)
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
