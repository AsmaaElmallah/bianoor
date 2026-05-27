import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_providers.dart';
import '../../../shared/widgets/content_sync_banner.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/media_age/media_age_groups_screen.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../domain/activities_catalog.dart';

class ActivitiesAgeGroupsScreen extends ConsumerStatefulWidget {
  const ActivitiesAgeGroupsScreen({super.key});

  @override
  ConsumerState<ActivitiesAgeGroupsScreen> createState() =>
      _ActivitiesAgeGroupsScreenState();
}

class _ActivitiesAgeGroupsScreenState extends ConsumerState<ActivitiesAgeGroupsScreen> {
  bool _snackShown = false;

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(activityAgeGroupsProvider);

    return asyncGroups.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _GroupsBody(groups: activityAgeGroups),
      data: (groups) {
        if (!_snackShown) {
          _snackShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final result =
                await ref.read(ageHubRepositoryProvider).loadActivityGroupsResult();
            if (!mounted) return;
            showContentFetchSnackBar(context, result, 'الأنشطة');
          });
        }
        return _GroupsBody(groups: groups);
      },
    );
  }
}

class _GroupsBody extends StatelessWidget {
  const _GroupsBody({required this.groups});

  final List<ActivityAgeGroup> groups;

  @override
  Widget build(BuildContext context) {
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
