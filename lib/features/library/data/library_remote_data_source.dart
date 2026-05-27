import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_hub_theme.dart';
import '../domain/library_media_catalog.dart';

/// جلب عناصر المكتبة المنشورة من Supabase.
class LibraryRemoteDataSource {
  const LibraryRemoteDataSource();

  static const _table = 'library_items';

  static const _mediaCategories = {'nature', 'calm', 'lullabies'};

  Future<List<Map<String, dynamic>>> fetchPublishedRows() async {
    if (!SupabaseBootstrap.isEnabled) return [];

    final client = SupabaseBootstrap.isReady
        ? SupabaseBootstrap.client
        : await _clientAfterInit();

    final data = await client
        .from(_table)
        .select()
        .eq('publish_status', 'published')
        .order('category_id')
        .order('sort_order');

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<SupabaseClient> _clientAfterInit() async {
    await SupabaseBootstrap.init();
    return SupabaseBootstrap.client;
  }

  /// تجميع الصفوف إلى فئات جاهزة للواجهة.
  List<LibraryMediaCategory> mapRowsToCategories(List<Map<String, dynamic>> rows) {
    final byCategory = <String, List<LibraryMediaItem>>{};

    for (final row in rows) {
      final categoryId = row['category_id'] as String?;
      if (categoryId == null || !_mediaCategories.contains(categoryId)) continue;

      final item = _rowToItem(row, categoryId);
      if (item == null) continue;

      byCategory.putIfAbsent(categoryId, () => []).add(item);
    }

    final result = <LibraryMediaCategory>[];
    for (final meta in _categoryMeta) {
      final items = byCategory[meta.supabaseId];
      if (items == null || items.isEmpty) continue;

      result.add(
        LibraryMediaCategory(
          id: meta.flutterId,
          title: meta.title,
          icon: meta.icon,
          items: items,
        ),
      );
    }
    return result;
  }

  LibraryMediaItem? _rowToItem(Map<String, dynamic> row, String categoryId) {
    final id = row['id'] as String?;
    final title = row['title'] as String?;
    if (id == null || title == null) return null;

    final videoId = (row['video_id'] as String?)?.trim();
    final playlistId = (row['playlist_id'] as String?)?.trim();
    if ((videoId == null || videoId.isEmpty) && (playlistId == null || playlistId.isEmpty)) {
      return null;
    }

    return LibraryMediaItem(
      id: id,
      title: title,
      videoId: videoId?.isNotEmpty == true ? videoId : null,
      playlistId: playlistId?.isNotEmpty == true ? playlistId : null,
      durationLabel: row['duration_label'] as String? ?? '—',
      moodTag: row['mood_tag'] as String? ?? '—',
      natureChip: categoryId == 'nature' ? _parseNatureChip(row['nature_chip'] as String?) : null,
    );
  }

  NatureSoundChip? _parseNatureChip(String? raw) {
    switch (raw) {
      case 'rain':
        return NatureSoundChip.rain;
      case 'forest':
        return NatureSoundChip.forest;
      case 'ocean':
        return NatureSoundChip.ocean;
      case 'wind':
        return NatureSoundChip.wind;
      default:
        return NatureSoundChip.rain;
    }
  }
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.supabaseId,
    required this.flutterId,
    required this.title,
    required this.icon,
  });

  final String supabaseId;
  final LibraryMediaCategoryId flutterId;
  final String title;
  final IconData icon;
}

const _categoryMeta = [
  _CategoryMeta(
    supabaseId: 'nature',
    flutterId: LibraryMediaCategoryId.natureSounds,
    title: 'أصوات الطبيعة',
    icon: Symbols.park,
  ),
  _CategoryMeta(
    supabaseId: 'calm',
    flutterId: LibraryMediaCategoryId.calmMusic,
    title: 'الموسيقى الهادئة',
    icon: Symbols.music_note,
  ),
  _CategoryMeta(
    supabaseId: 'lullabies',
    flutterId: LibraryMediaCategoryId.lullabies,
    title: 'تهويدات النوم',
    icon: Symbols.bedtime,
  ),
];
