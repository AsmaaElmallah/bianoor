import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/content_providers.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../../../shared/widgets/media_age/media_age_hub_screen.dart';
import '../domain/activities_catalog.dart';

class ActivitiesHubScreen extends ConsumerWidget {
  const ActivitiesHubScreen({super.key, required this.ageGroupId});

  final String ageGroupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroup = ref.watch(activityAgeGroupProvider(ageGroupId));

    return asyncGroup.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildHub(context, activityAgeGroupById(ageGroupId)),
      data: (group) => _buildHub(context, group),
    );
  }

  Widget _buildHub(BuildContext context, ActivityAgeGroup? group) {
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الأنشطة')),
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('الفئة غير متوفرة — رجوع'),
          ),
        ),
      );
    }

    return MediaAgeHubScreen(
      config: MediaAgeHubConfig.activities,
      ageTitle: group.title,
      ageSubtitle: group.subtitle,
      items: group.items,
      parentNote: group.parentNote,
      onOpenExternal: (item) async {
        if (item != null) {
          final uri = item.isPlaylist
              ? Uri.parse('https://www.youtube.com/playlist?list=${item.playlistId}')
              : Uri.parse('https://www.youtube.com/watch?v=${item.videoId}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          return;
        }
        final uri = Uri.parse(
          'https://www.youtube.com/playlist?list=$creativePlayPlaylistId',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
