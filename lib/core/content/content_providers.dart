import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activities/domain/activities_catalog.dart';
import '../../features/exercises/domain/exercises_catalog.dart';
import '../../features/library/data/library_repository.dart';
import '../../features/library/domain/library_media_catalog.dart';
import 'age_hub_repository.dart';
import 'content_sync_notifier.dart';
import 'curriculum_slides_repository.dart';
import '../../features/quran/data/quran_session_resolver.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return const LibraryRepository();
});

final ageHubRepositoryProvider = Provider<AgeHubRepository>((ref) {
  return const AgeHubRepository();
});

final curriculumSlidesRepositoryProvider = Provider<CurriculumSlidesRepository>((ref) {
  return CurriculumSlidesRepository();
});

final quranSessionResolverProvider = Provider<QuranSessionResolver>((ref) {
  return const QuranSessionResolver();
});

/// فئات المكتبة (طبيعة / هدوء / تهويدات) — Supabase + fallback محلي.
final libraryCatalogProvider = FutureProvider<List<LibraryMediaCategory>>((ref) async {
  final result = await ref.read(libraryRepositoryProvider).loadCategoriesResult();
  ref.read(contentSyncProvider.notifier).reportFetch('المكتبة', result);
  return result.data;
});

final libraryCategoryProvider = FutureProvider.family<LibraryMediaCategory?, String>((
  ref,
  menuId,
) async {
  final result = await ref.read(libraryRepositoryProvider).loadCategoriesResult();
  ref.read(contentSyncProvider.notifier).reportFetch('المكتبة', result);
  final catId = libraryCategoryIdFromMenuId(menuId);
  if (catId == null) return null;
  for (final c in result.data) {
    if (c.id == catId) return c;
  }
  return null;
});

final exerciseAgeGroupsProvider = FutureProvider<List<ExerciseAgeGroup>>((ref) async {
  final result = await ref.read(ageHubRepositoryProvider).loadExerciseGroupsResult();
  ref.read(contentSyncProvider.notifier).reportFetch('التمارين', result);
  return result.data;
});

final activityAgeGroupsProvider = FutureProvider<List<ActivityAgeGroup>>((ref) async {
  final result = await ref.read(ageHubRepositoryProvider).loadActivityGroupsResult();
  ref.read(contentSyncProvider.notifier).reportFetch('الأنشطة', result);
  return result.data;
});

final exerciseAgeGroupProvider = FutureProvider.family<ExerciseAgeGroup?, String>((
  ref,
  ageGroupId,
) {
  return ref.watch(ageHubRepositoryProvider).exerciseGroupById(ageGroupId);
});

final activityAgeGroupProvider = FutureProvider.family<ActivityAgeGroup?, String>((
  ref,
  ageGroupId,
) {
  return ref.watch(ageHubRepositoryProvider).activityGroupById(ageGroupId);
});

/// عدد شرائح المنهج المنشورة على Supabase (حسب global_index).
final curriculumCloudSlideCountProvider = FutureProvider.family<int, String>((
  ref,
  trackId,
) async {
  final map = await ref.read(curriculumSlidesRepositoryProvider).slidesForTrack(trackId);
  return map.length;
});
