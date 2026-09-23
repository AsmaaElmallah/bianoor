import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../data/age_hub_repository.dart';
import '../domain/exercises_catalog.dart';

class ExercisesAgeGroupsScreen extends ConsumerWidget {
  const ExercisesAgeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroups = ref.watch(exerciseAgeGroupsProvider);

    return asyncGroups.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _build(exerciseAgeGroups),
      data: (groups) => _build(groups),
    );
  }

  Widget _build(List<ExerciseAgeGroup> groups) {
    return MediaAgeGroupsScreen(
      config: MediaAgeHubConfig.exercises,
      heroTitle: 'تمارين الأطفال حسب العمر',
      heroSubtitle: 'اختاري عمر طفلكِ لمشاهدة التمارين والمساج المناسب.',
      hubPathBuilder: AppRoutes.exercisesHubPath,
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
