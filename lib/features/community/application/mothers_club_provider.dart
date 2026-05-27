import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/content_fetch_result.dart';
import '../../auth/application/auth_session_provider.dart';
import '../data/mothers_club_repository.dart';
import '../domain/mothers_club_models.dart';

final mothersClubRepositoryProvider = Provider<MothersClubRepository>((ref) {
  return const MothersClubRepository();
});

final mothersClubCategoriesProvider =
    FutureProvider<ContentFetchResult<List<MothersClubCategory>>>((ref) {
  return ref.watch(mothersClubRepositoryProvider).loadCategories();
});

class MothersClubFeedFilter {
  const MothersClubFeedFilter({this.categoryId, this.searchQuery = ''});

  final String? categoryId;
  final String searchQuery;

  MothersClubFeedFilter copyWith({String? categoryId, String? searchQuery}) {
    return MothersClubFeedFilter(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final mothersClubFeedFilterProvider =
    StateProvider<MothersClubFeedFilter>((ref) => const MothersClubFeedFilter());

class MothersClubFeedState {
  const MothersClubFeedState({
    required this.allPosts,
    required this.source,
    this.hasMore = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final List<MothersClubPost> allPosts;
  final ContentFetchSource source;
  final bool hasMore;
  final bool loadingMore;
  final String? errorMessage;

  List<MothersClubPost> postsForQuery(String query) =>
      _filterPostsByQuery(allPosts, query);

  MothersClubFeedState copyWith({
    List<MothersClubPost>? allPosts,
    ContentFetchSource? source,
    bool? hasMore,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return MothersClubFeedState(
      allPosts: allPosts ?? this.allPosts,
      source: source ?? this.source,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

List<MothersClubPost> _filterPostsByQuery(List<MothersClubPost> posts, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return posts;
  return posts
      .where(
        (p) =>
            p.title.toLowerCase().contains(q) ||
            p.body.toLowerCase().contains(q) ||
            p.tag.toLowerCase().contains(q) ||
            p.authorDisplayName.toLowerCase().contains(q),
      )
      .toList();
}

class MothersClubFeedNotifier extends AsyncNotifier<MothersClubFeedState> {
  @override
  Future<MothersClubFeedState> build() async {
    ref.listen(mothersClubFeedFilterProvider, (prev, next) {
      if (prev?.categoryId != next.categoryId) {
        ref.invalidateSelf();
      }
    });

    final filter = ref.read(mothersClubFeedFilterProvider);
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    final page = await ref.read(mothersClubRepositoryProvider).loadPostsPage(
          categoryId: filter.categoryId,
          userId: user?.id,
        );

    return MothersClubFeedState(
      allPosts: page.posts,
      source: page.source,
      hasMore: page.hasMore,
      errorMessage: page.errorMessage,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    final filter = ref.read(mothersClubFeedFilterProvider);
    if (filter.searchQuery.trim().isNotEmpty) return;

    state = AsyncData(current.copyWith(loadingMore: true));

    try {
      final user = ref.read(authSessionProvider).valueOrNull?.user;
      final page = await ref.read(mothersClubRepositoryProvider).loadPostsPage(
            categoryId: filter.categoryId,
            userId: user?.id,
            offset: current.allPosts.length,
          );

      state = AsyncData(
        MothersClubFeedState(
          allPosts: [...current.allPosts, ...page.posts],
          source: page.source,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  void applySearch(String query) {
    ref.read(mothersClubFeedFilterProvider.notifier).update(
          (f) => f.copyWith(searchQuery: query),
        );
  }
}

final mothersClubFeedProvider =
    AsyncNotifierProvider<MothersClubFeedNotifier, MothersClubFeedState>(
  MothersClubFeedNotifier.new,
);

/// للتوافق مع الشاشات التي تستخدم invalidate بعد تعليق/إعجاب
final mothersClubPostsProvider = Provider<AsyncValue<MothersClubFeedState>>((ref) {
  return ref.watch(mothersClubFeedProvider);
});

final mothersClubPostProvider =
    FutureProvider.family<MothersClubPost?, String>((ref, postId) async {
  final user = ref.watch(authSessionProvider).valueOrNull?.user;
  return ref.read(mothersClubRepositoryProvider).loadPostById(
        postId,
        userId: user?.id,
      );
});

final mothersClubCommentsProvider =
    FutureProvider.family<List<MothersClubComment>, String>((ref, postId) {
  return ref.watch(mothersClubRepositoryProvider).loadComments(postId);
});
