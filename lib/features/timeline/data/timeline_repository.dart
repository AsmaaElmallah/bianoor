import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

enum TimelineKind { development, feeding }

class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.kind,
    required this.ageDays,
    required this.title,
    required this.body,
    required this.tips,
    required this.sourceName,
    this.sourceUrl,
  });

  factory TimelineItem.fromRow(Map<String, dynamic> row) => TimelineItem(
        id: row['id'] as String,
        kind: row['kind'] == 'feeding' ? TimelineKind.feeding : TimelineKind.development,
        ageDays: (row['age_days'] as num).toInt(),
        title: row['title'] as String? ?? '',
        body: row['body'] as String? ?? '',
        tips: [for (final t in (row['tips'] as List? ?? const [])) t.toString()],
        sourceName: row['source_name'] as String? ?? '',
        sourceUrl: row['source_url'] as String?,
      );

  final String id;
  final TimelineKind kind;
  final int ageDays;
  final String title;
  final String body;
  final List<String> tips;
  final String sourceName;
  final String? sourceUrl;
}

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) => TimelineRepository());

class TimelineRepository {
  /// Skills and feeding milestones only — vaccines are not shown in the app.
  Future<List<TimelineItem>> fetchItems() async {
    final rows = await SupabaseBootstrap.client
        .from('baby_timeline')
        .select('id, kind, age_days, title, body, tips, source_name, source_url')
        .eq('publish_status', 'published')
        .neq('kind', 'vaccine')
        .order('age_days');
    return [for (final r in List<Map<String, dynamic>>.from(rows as List)) TimelineItem.fromRow(r)];
  }

  Future<Set<String>> fetchDone(String childId) async {
    final rows = await SupabaseBootstrap.client.from('baby_timeline_done').select('item_id').eq('child_id', childId);
    return {for (final r in List<Map<String, dynamic>>.from(rows as List)) r['item_id'] as String};
  }

  Future<void> setDone(String childId, String itemId, bool done) async {
    final table = SupabaseBootstrap.client.from('baby_timeline_done');
    if (done) {
      await table.upsert({'child_id': childId, 'item_id': itemId}, onConflict: 'child_id,item_id');
    } else {
      await table.delete().eq('child_id', childId).eq('item_id', itemId);
    }
  }
}
