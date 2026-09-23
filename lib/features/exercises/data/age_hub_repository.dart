import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../content/data/content_remote_data_source.dart';
import '../../library/data/library_content_repository.dart';
import '../../library/domain/library_media_catalog.dart';
import '../domain/exercises_catalog.dart';
import '../../activities/domain/activities_catalog.dart';

final ageHubRepositoryProvider = Provider<AgeHubRepository>((ref) {
  return AgeHubRepository(ref.watch(contentRemoteDataSourceProvider));
});

final exerciseAgeGroupsProvider = FutureProvider<List<ExerciseAgeGroup>>((ref) {
  return ref.watch(ageHubRepositoryProvider).loadExercises();
});

final activityAgeGroupsProvider = FutureProvider<List<ActivityAgeGroup>>((ref) {
  return ref.watch(ageHubRepositoryProvider).loadActivities();
});

final exerciseAgeGroupProvider =
    FutureProvider.family<ExerciseAgeGroup?, String>((ref, id) async {
  final groups = await ref.watch(exerciseAgeGroupsProvider.future);
  for (final g in groups) {
    if (g.id == id) return g;
  }
  return null;
});

final activityAgeGroupProvider =
    FutureProvider.family<ActivityAgeGroup?, String>((ref, id) async {
  final groups = await ref.watch(activityAgeGroupsProvider.future);
  for (final g in groups) {
    if (g.id == id) return g;
  }
  return null;
});

class AgeHubRepository {
  AgeHubRepository(this._remote);

  final ContentRemoteDataSource _remote;

  Future<List<ExerciseAgeGroup>> loadExercises() async {
    final remote = await _loadRemote('exercises');
    if (remote == null || remote.isEmpty) {
      if (kDebugMode) debugPrint('[AgeHub] exercises — no published cloud content');
      return [];
    }

    return [
      for (final g in remote)
        ExerciseAgeGroup(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          icon: _iconFor(g.id),
          items: g.items,
          parentNote: g.parentNote,
        ),
    ];
  }

  Future<List<ActivityAgeGroup>> loadActivities() async {
    final remote = await _loadRemote('activities');
    if (remote == null || remote.isEmpty) {
      if (kDebugMode) debugPrint('[AgeHub] activities — no published cloud content');
      return [];
    }

    return [
      for (final g in remote)
        ActivityAgeGroup(
          id: g.id,
          title: g.title,
          subtitle: g.subtitle,
          icon: _iconFor(g.id),
          items: g.items,
          parentNote: g.parentNote,
        ),
    ];
  }

  Future<List<_RemoteGroup>?> _loadRemote(String hubType) async {
    final groupRows = await _remote.fetchPublishedAgeHubGroups(hubType);
    if (groupRows.isEmpty) return null;

    final ids = groupRows.map((g) => g['id'] as String).toList();
    final itemRows = await _remote.fetchPublishedAgeHubItems(ids);

    final byGroup = <String, List<LibraryMediaItem>>{};
    for (final row in itemRows) {
      final gid = row['group_id'] as String;
      byGroup.putIfAbsent(gid, () => []).add(
            LibraryMediaItem(
              id: row['id'] as String,
              title: row['title'] as String? ?? 'مقطع',
              videoId: row['video_id'] as String?,
              playlistId: row['playlist_id'] as String?,
              moodTag: row['mood_tag'] as String?,
            ),
          );
    }

    return [
      for (final g in groupRows)
        _RemoteGroup(
          id: g['id'] as String,
          title: g['title'] as String? ?? g['id'] as String,
          subtitle: g['subtitle'] as String? ?? '',
          parentNote: g['parent_note'] as String?,
          items: byGroup[g['id'] as String] ?? const [],
        ),
    ];
  }

  IconData _iconFor(String id) {
    final localEx = exerciseAgeGroupById(id);
    if (localEx != null) return localEx.icon;
    final localAct = activityAgeGroupById(id);
    if (localAct != null) return localAct.icon;
    return Symbols.child_care;
  }
}

class _RemoteGroup {
  const _RemoteGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    this.parentNote,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? parentNote;
  final List<LibraryMediaItem> items;
}
