import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../content/data/content_remote_data_source.dart';
import '../domain/library_hub_theme.dart';
import '../domain/library_media_catalog.dart';

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((ref) {
  return const ContentRemoteDataSource();
});

final libraryContentRepositoryProvider = Provider<LibraryContentRepository>((ref) {
  return LibraryContentRepository(ref.watch(contentRemoteDataSourceProvider));
});

/// Published Supabase rows only — empty when admin has not published.
final libraryCategoryProvider =
    FutureProvider.family<LibraryMediaCategory?, String>((ref, menuId) async {
  return ref.watch(libraryContentRepositoryProvider).loadCategory(menuId);
});

class LibraryContentRepository {
  LibraryContentRepository(this._remote);

  final ContentRemoteDataSource _remote;

  static const _dbCategoryByMenu = {
    'nature_sounds': 'nature',
    'calm_music': 'calm',
    'lullabies': 'lullabies',
    'library_books': 'library_books',
  };

  static const _metaByMenu = {
    'nature_sounds': (title: 'أصوات الطبيعة', icon: Symbols.park),
    'calm_music': (title: 'الموسيقى الهادئة', icon: Symbols.music_note),
    'lullabies': (title: 'تهويدات النوم', icon: Symbols.bedtime),
    'library_books': (title: 'المكتبة', icon: Symbols.menu_book),
  };

  Future<LibraryMediaCategory?> loadCategory(String menuId) async {
    final catId = libraryCategoryIdFromMenuId(menuId);
    final dbCategory = _dbCategoryByMenu[menuId];
    final meta = _metaByMenu[menuId];
    if (catId == null || dbCategory == null || meta == null) return null;

    final rows = await _remote.fetchPublishedLibraryItems();
    final filtered = rows.where((r) => r['category_id'] == dbCategory).toList();

    if (kDebugMode && filtered.isEmpty) {
      debugPrint('[Library] no published rows for $dbCategory');
    }

    return LibraryMediaCategory(
      id: catId,
      title: meta.title,
      icon: meta.icon,
      items: filtered.map(_itemFromRow).toList(),
    );
  }

  LibraryMediaItem _itemFromRow(Map<String, dynamic> row) {
    final chipRaw = row['nature_chip'] as String?;
    NatureSoundChip? chip;
    if (chipRaw != null) {
      for (final c in NatureSoundChip.values) {
        if (c.name == chipRaw) {
          chip = c;
          break;
        }
      }
    }

    return LibraryMediaItem(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'مقطع',
      videoId: row['video_id'] as String?,
      playlistId: row['playlist_id'] as String?,
      durationLabel: row['duration_label'] as String?,
      moodTag: row['mood_tag'] as String?,
      natureChip: chip,
    );
  }
}
