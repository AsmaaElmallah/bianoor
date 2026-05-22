import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../../../shared/widgets/media_age/media_age_hub_screen.dart';
import '../domain/exercises_catalog.dart';

class ExercisesHubScreen extends StatelessWidget {
  const ExercisesHubScreen({super.key, required this.ageGroupId});

  final String ageGroupId;

  @override
  Widget build(BuildContext context) {
    final group = exerciseAgeGroupById(ageGroupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الرياضة')),
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('الفئة غير متوفرة — رجوع'),
          ),
        ),
      );
    }

    return MediaAgeHubScreen(
      config: MediaAgeHubConfig.exercises,
      ageTitle: group.title,
      ageSubtitle: group.subtitle,
      items: group.items,
      parentNote: group.parentNote,
      onOpenExternal: (item) async {
        if (item == null) return;
        final uri = item.isPlaylist
            ? Uri.parse('https://www.youtube.com/playlist?list=${item.playlistId}')
            : Uri.parse('https://www.youtube.com/watch?v=${item.videoId}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
