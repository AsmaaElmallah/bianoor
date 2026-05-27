import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/activities/domain/activities_catalog.dart';
import '../../features/exercises/domain/exercises_catalog.dart';
import '../supabase/supabase_bootstrap.dart';
import 'age_hub_remote_data_source.dart';
import 'content_fetch_result.dart';

/// دمج age hub من Supabase مع الكتالوج المحلي.
class AgeHubRepository {
  const AgeHubRepository({AgeHubRemoteDataSource? remote})
      : _remote = remote ?? const AgeHubRemoteDataSource();

  final AgeHubRemoteDataSource _remote;

  Future<List<ExerciseAgeGroup>> loadExerciseGroups() async {
    return (await loadExerciseGroupsResult()).data;
  }

  Future<ContentFetchResult<List<ExerciseAgeGroup>>> loadExerciseGroupsResult() async {
    return _loadGroupsResult(
      hubType: 'exercises',
      featureLabel: 'التمارين',
      local: exerciseAgeGroups,
      merge: _mergeExerciseGroups,
    );
  }

  Future<List<ActivityAgeGroup>> loadActivityGroups() async {
    return (await loadActivityGroupsResult()).data;
  }

  Future<ContentFetchResult<List<ActivityAgeGroup>>> loadActivityGroupsResult() async {
    return _loadGroupsResult(
      hubType: 'activities',
      featureLabel: 'الأنشطة',
      local: activityAgeGroups,
      merge: _mergeActivityGroups,
    );
  }

  Future<ContentFetchResult<List<T>>> _loadGroupsResult<T>({
    required String hubType,
    required String featureLabel,
    required List<T> local,
    required List<T> Function(AgeHubRemoteSnapshot) merge,
  }) async {
    if (!SupabaseBootstrap.isEnabled) {
      return ContentFetchResult(
        data: List<T>.from(local),
        source: ContentFetchSource.supabaseDisabled,
      );
    }

    try {
      final snapshot = await _remote.fetchPublished(hubType);
      if (snapshot == null) {
        return ContentFetchResult(
          data: List<T>.from(local),
          source: ContentFetchSource.remoteEmpty,
          remoteCount: 0,
        );
      }

      var itemCount = 0;
      for (final g in snapshot.groups) {
        final id = g['id'] as String?;
        if (id != null) itemCount += snapshot.itemsForGroup(id).length;
      }

      if (itemCount == 0 && snapshot.groups.isEmpty) {
        return ContentFetchResult(
          data: List<T>.from(local),
          source: ContentFetchSource.remoteEmpty,
          remoteCount: 0,
        );
      }

      return ContentFetchResult(
        data: merge(snapshot),
        source: ContentFetchSource.remote,
        remoteCount: itemCount,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AgeHubRepository] $hubType failed: $e\n$st');
      }
      return ContentFetchResult(
        data: List<T>.from(local),
        source: ContentFetchSource.errorFallback,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ExerciseAgeGroup?> exerciseGroupById(String id) async {
    final groups = await loadExerciseGroups();
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<ActivityAgeGroup?> activityGroupById(String id) async {
    final groups = await loadActivityGroups();
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<ExerciseAgeGroup> _mergeExerciseGroups(AgeHubRemoteSnapshot snapshot) {
    final result = <ExerciseAgeGroup>[];

    for (final local in exerciseAgeGroups) {
      final remoteItems = snapshot.itemsForGroup(local.id);
      final meta = _groupRow(snapshot, local.id);
      if (remoteItems.isNotEmpty) {
        result.add(
          ExerciseAgeGroup(
            id: local.id,
            title: meta?['title'] as String? ?? local.title,
            subtitle: meta?['subtitle'] as String? ?? local.subtitle,
            icon: local.icon,
            parentNote: meta?['parent_note'] as String? ?? local.parentNote,
            items: remoteItems,
          ),
        );
      } else {
        result.add(local);
      }
    }

    for (final row in snapshot.groups) {
      final id = row['id'] as String;
      if (exerciseAgeGroups.any((g) => g.id == id)) continue;
      final items = snapshot.itemsForGroup(id);
      if (items.isEmpty) continue;
      result.add(
        ExerciseAgeGroup(
          id: id,
          title: row['title'] as String? ?? id,
          subtitle: row['subtitle'] as String? ?? '',
          icon: _exerciseIcon(id),
          parentNote: row['parent_note'] as String?,
          items: items,
        ),
      );
    }

    return result.isEmpty ? List<ExerciseAgeGroup>.from(exerciseAgeGroups) : result;
  }

  List<ActivityAgeGroup> _mergeActivityGroups(AgeHubRemoteSnapshot snapshot) {
    final result = <ActivityAgeGroup>[];

    for (final local in activityAgeGroups) {
      final remoteItems = snapshot.itemsForGroup(local.id);
      final meta = _groupRow(snapshot, local.id);
      if (remoteItems.isNotEmpty) {
        result.add(
          ActivityAgeGroup(
            id: local.id,
            title: meta?['title'] as String? ?? local.title,
            subtitle: meta?['subtitle'] as String? ?? local.subtitle,
            icon: local.icon,
            parentNote: meta?['parent_note'] as String? ?? local.parentNote,
            items: remoteItems,
          ),
        );
      } else {
        result.add(local);
      }
    }

    for (final row in snapshot.groups) {
      final id = row['id'] as String;
      if (activityAgeGroups.any((g) => g.id == id)) continue;
      final items = snapshot.itemsForGroup(id);
      if (items.isEmpty) continue;
      result.add(
        ActivityAgeGroup(
          id: id,
          title: row['title'] as String? ?? id,
          subtitle: row['subtitle'] as String? ?? '',
          icon: _activityIcon(id),
          parentNote: row['parent_note'] as String?,
          items: items,
        ),
      );
    }

    return result.isEmpty ? List<ActivityAgeGroup>.from(activityAgeGroups) : result;
  }

  Map<String, dynamic>? _groupRow(AgeHubRemoteSnapshot snapshot, String id) {
    for (final g in snapshot.groups) {
      if (g['id'] == id) return g;
    }
    return null;
  }

  IconData _exerciseIcon(String id) {
    for (final g in exerciseAgeGroups) {
      if (g.id == id) return g.icon;
    }
    return Symbols.fitness_center;
  }

  IconData _activityIcon(String id) {
    for (final g in activityAgeGroups) {
      if (g.id == id) return g.icon;
    }
    return Symbols.toys;
  }
}
