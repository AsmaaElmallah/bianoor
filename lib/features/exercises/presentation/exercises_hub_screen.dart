import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/media_age/media_age_hub_config.dart';
import '../../../shared/widgets/media_age/media_age_hub_screen.dart';
import '../data/age_hub_repository.dart';

class ExercisesHubScreen extends ConsumerWidget {
  const ExercisesHubScreen({super.key, required this.ageGroupId});

  final String ageGroupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroup = ref.watch(exerciseAgeGroupProvider(ageGroupId));

    return asyncGroup.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _missing(context),
      data: (group) {
        if (group == null) return _missing(context);
        return MediaAgeHubScreen(
          config: MediaAgeHubConfig.exercises,
          ageTitle: group.title,
          ageSubtitle: group.subtitle,
          items: group.items,
          parentNote: group.parentNote,
          onOpenExternal: (item) async {
            if (item == null) return;
            final uri = item.isPlaylist
                ? Uri.parse(
                    'https://www.youtube.com/playlist?list=${item.playlistId}',
                  )
                : Uri.parse('https://www.youtube.com/watch?v=${item.videoId}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        );
      },
    );
  }

  Widget _missing(BuildContext context) {
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
}
