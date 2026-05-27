import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../../shared/widgets/content_sync_banner.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../domain/exercises_catalog.dart';

class ExercisesAgeGroupsScreen extends ConsumerStatefulWidget {
  const ExercisesAgeGroupsScreen({super.key});

  @override
  ConsumerState<ExercisesAgeGroupsScreen> createState() =>
      _ExercisesAgeGroupsScreenState();
}

class _ExercisesAgeGroupsScreenState extends ConsumerState<ExercisesAgeGroupsScreen> {
  bool _snackShown = false;

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(exerciseAgeGroupsProvider);

    return asyncGroups.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _GroupsBody(groups: exerciseAgeGroups),
      data: (groups) {
        if (!_snackShown) {
          _snackShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final result =
                await ref.read(ageHubRepositoryProvider).loadExerciseGroupsResult();
            if (!mounted) return;
            showContentFetchSnackBar(context, result, 'التمارين');
          });
        }
        return _GroupsBody(groups: groups);
      },
    );
  }
}

class _GroupsBody extends StatelessWidget {
  const _GroupsBody({required this.groups});

  final List<ExerciseAgeGroup> groups;

  @override
  Widget build(BuildContext context) {
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
