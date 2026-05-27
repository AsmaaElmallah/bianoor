import '../../features/library/domain/library_media_catalog.dart';
import '../supabase/supabase_bootstrap.dart';

/// جلب مجموعات الرياضة / الأنشطة وعناصرها من Supabase.
class AgeHubRemoteDataSource {
  const AgeHubRemoteDataSource();

  Future<AgeHubRemoteSnapshot?> fetchPublished(String hubType) async {
    if (!SupabaseBootstrap.isEnabled) return null;

    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }
    final client = SupabaseBootstrap.client;

    final groupsRes = await client
        .from('age_hub_groups')
        .select()
        .eq('hub_type', hubType)
        .eq('publish_status', 'published')
        .order('sort_order');

    final itemsRes = await client
        .from('age_hub_items')
        .select()
        .eq('publish_status', 'published')
        .order('sort_order');

    final groups = List<Map<String, dynamic>>.from(groupsRes as List);
    final items = List<Map<String, dynamic>>.from(itemsRes as List);

    if (groups.isEmpty && items.isEmpty) return null;

    return AgeHubRemoteSnapshot(groups: groups, items: items);
  }
}

class AgeHubRemoteSnapshot {
  const AgeHubRemoteSnapshot({required this.groups, required this.items});

  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> items;

  List<LibraryMediaItem> itemsForGroup(String groupId) {
    final groupItems = items.where((row) => row['group_id'] == groupId);
    final mapped = <LibraryMediaItem>[];

    for (final row in groupItems) {
      final item = _rowToItem(row);
      if (item != null) mapped.add(item);
    }
    return mapped;
  }

  LibraryMediaItem? _rowToItem(Map<String, dynamic> row) {
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
      moodTag: row['mood_tag'] as String? ?? '—',
    );
  }
}
