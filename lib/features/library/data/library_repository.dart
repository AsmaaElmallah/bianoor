import 'package:flutter/foundation.dart';

import '../../../core/content/content_fetch_result.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_media_catalog.dart';
import 'library_remote_data_source.dart';

/// مكتبة الوسائط: Supabase أولاً ثم fallback للكتالوج المحلي.
class LibraryRepository {
  const LibraryRepository({LibraryRemoteDataSource? remote})
      : _remote = remote ?? const LibraryRemoteDataSource();

  final LibraryRemoteDataSource _remote;

  Future<List<LibraryMediaCategory>> loadCategories() async {
    final result = await loadCategoriesResult();
    return result.data;
  }

  Future<ContentFetchResult<List<LibraryMediaCategory>>> loadCategoriesResult() async {
    if (!SupabaseBootstrap.isEnabled) {
      return ContentFetchResult(
        data: List<LibraryMediaCategory>.from(localLibraryMediaCategories),
        source: ContentFetchSource.supabaseDisabled,
      );
    }

    try {
      final rows = await _remote.fetchPublishedRows();
      if (kDebugMode) {
        debugPrint('[LibraryRepository] Supabase rows: ${rows.length}');
      }

      final remoteCategories = _remote.mapRowsToCategories(rows);

      if (remoteCategories.isEmpty) {
        return ContentFetchResult(
          data: List<LibraryMediaCategory>.from(localLibraryMediaCategories),
          source: ContentFetchSource.remoteEmpty,
          remoteCount: 0,
        );
      }

      return ContentFetchResult(
        data: _mergeWithLocal(remoteCategories),
        source: ContentFetchSource.remote,
        remoteCount: rows.length,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LibraryRepository] fetch failed: $e\n$st');
      }
      return ContentFetchResult(
        data: List<LibraryMediaCategory>.from(localLibraryMediaCategories),
        source: ContentFetchSource.errorFallback,
        errorMessage: e.toString(),
      );
    }
  }

  Future<LibraryMediaCategory?> categoryByMenuId(String menuId) async {
    final catId = libraryCategoryIdFromMenuId(menuId);
    if (catId == null) return null;

    final categories = await loadCategories();
    for (final c in categories) {
      if (c.id == catId) return c;
    }
    return null;
  }

  List<LibraryMediaCategory> _mergeWithLocal(List<LibraryMediaCategory> remote) {
    final remoteById = {for (final c in remote) c.id: c};

    return [
      for (final local in localLibraryMediaCategories)
        if (remoteById.containsKey(local.id) && remoteById[local.id]!.items.isNotEmpty)
          remoteById[local.id]!
        else
          local,
    ];
  }
}
