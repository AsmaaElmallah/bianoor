import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/parenting_article.dart';

final cmsCloudRepositoryProvider = Provider<CmsCloudRepository>((ref) {
  return CmsCloudRepository();
});

/// Published CMS articles for a section (e.g. parent_culture, parent_health, how_to_teach).
final cmsArticlesBySectionProvider =
    FutureProvider.family<List<ParentingArticle>, String>((ref, section) {
  return ref.watch(cmsCloudRepositoryProvider).fetchPublishedBySection(section);
});

class CmsCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<ParentingArticle>> fetchPublishedBySection(String section) async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('cms_articles')
          .select()
          .eq('section', section)
          .eq('publish_status', 'published')
          .order('sort_order');

      return [
        for (final row in List<Map<String, dynamic>>.from(rows as List))
          ParentingArticle(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            subtitle: row['slug'] as String? ?? '',
            body: row['body'] as String? ?? '',
          ),
      ];
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CMS] $section failed: $e\n$st');
      return [];
    }
  }
}
