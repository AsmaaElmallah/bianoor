import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../library/domain/library_age_band.dart';
import '../data/community_cloud_repository.dart';

@immutable
class ClubFeedQuery {
  const ClubFeedQuery({this.ageId, this.sort = ClubSort.newest, this.search = '', this.savedOnly = false});

  final String? ageId;
  final ClubSort sort;
  final String search;
  final bool savedOnly;

  ClubFeedQuery copyWith({Object? ageId = _keep, ClubSort? sort, String? search, bool? savedOnly}) => ClubFeedQuery(
        ageId: identical(ageId, _keep) ? this.ageId : ageId as String?,
        sort: sort ?? this.sort,
        search: search ?? this.search,
        savedOnly: savedOnly ?? this.savedOnly,
      );

  static const _keep = Object();

  @override
  bool operator ==(Object other) =>
      other is ClubFeedQuery &&
      other.ageId == ageId &&
      other.sort == sort &&
      other.search == search &&
      other.savedOnly == savedOnly;

  @override
  int get hashCode => Object.hash(ageId, sort, search, savedOnly);
}

/// The baby's age band from onboarding, or null if the mother never picked one.
LibraryAgeBand? babyAgeBandFromPrefs(PrefsService prefs) {
  if (!prefs.hasBabyAgeRange()) return null;
  final i = prefs.getBabyAgeRangeIndex();
  return i >= 0 && i < LibraryAgeBand.values.length ? LibraryAgeBand.values[i] : null;
}

/// Opens on the baby's own age so the first thing a mother sees is relevant.
final clubFeedQueryProvider = StateProvider.autoDispose<ClubFeedQuery>((ref) {
  return ClubFeedQuery(ageId: babyAgeBandFromPrefs(ref.read(prefsServiceProvider))?.dbValue);
});

@immutable
class ClubFeed {
  const ClubFeed({required this.posts, required this.hasMore, this.loadingMore = false});

  final List<MothersClubPost> posts;
  final bool hasMore;
  final bool loadingMore;
}

final mothersClubPostsProvider =
    AsyncNotifierProvider.autoDispose<ClubFeedNotifier, ClubFeed>(ClubFeedNotifier.new);

class ClubFeedNotifier extends AutoDisposeAsyncNotifier<ClubFeed> {
  static const pageSize = 15;

  Set<String>? _onlyIds;

  @override
  Future<ClubFeed> build() async {
    final q = ref.watch(clubFeedQueryProvider);
    final repo = ref.read(communityCloudRepositoryProvider);
    _onlyIds = q.savedOnly ? await repo.fetchMySavedPostIds() : null;
    final page = await _fetch(q, 0);
    return ClubFeed(posts: page, hasMore: page.length == pageSize);
  }

  Future<List<MothersClubPost>> _fetch(ClubFeedQuery q, int offset) {
    return ref.read(communityCloudRepositoryProvider).fetchFeed(
          ageId: q.ageId,
          sort: q.sort,
          search: q.search,
          onlyIds: _onlyIds,
          offset: offset,
          limit: pageSize,
        );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore || state.isLoading) return;
    state = AsyncData(ClubFeed(posts: current.posts, hasMore: true, loadingMore: true));
    try {
      final next = await _fetch(ref.read(clubFeedQueryProvider), current.posts.length);
      final seen = {for (final p in current.posts) p.id};
      state = AsyncData(ClubFeed(
        posts: [...current.posts, ...next.where((p) => !seen.contains(p.id))],
        hasMore: next.length == pageSize,
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('[Community] load more failed: $e');
      state = AsyncData(ClubFeed(posts: current.posts, hasMore: current.hasMore));
    }
  }
}

/// Posts I saved, updated optimistically like the likes.
final mothersClubSavesProvider =
    AsyncNotifierProvider<MothersClubSavesNotifier, Set<String>>(MothersClubSavesNotifier.new);

class MothersClubSavesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(communityCloudRepositoryProvider).fetchMySavedPostIds();

  bool isSaved(String postId) => state.valueOrNull?.contains(postId) ?? false;

  /// Returns the new saved state.
  Future<bool> toggle(String postId) async {
    final current = {...?state.valueOrNull};
    final save = !current.contains(postId);
    state = AsyncData(save ? ({...current, postId}) : ({...current}..remove(postId)));
    try {
      await ref.read(communityCloudRepositoryProvider).setSaved(postId, save);
      return save;
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
