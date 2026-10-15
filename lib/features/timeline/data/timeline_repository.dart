import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

enum TimelineKind { vaccine, development, feeding }

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
        kind: switch (row['kind']) {
          'vaccine' => TimelineKind.vaccine,
          'feeding' => TimelineKind.feeding,
          _ => TimelineKind.development,
        },
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

/// Countries with a vaccine schedule (codes match `baby_timeline.country`).
const vaccineCountries = <String, String>{
  'EG': 'مصر',
  'YE': 'اليمن',
  'SA': 'السعودية',
  'AE': 'الإمارات',
  'KW': 'الكويت',
  'QA': 'قطر',
  'BH': 'البحرين',
  'OM': 'عُمان',
  'JO': 'الأردن',
  'IQ': 'العراق',
  'SY': 'سوريا',
  'LB': 'لبنان',
  'PS': 'فلسطين',
  'LY': 'ليبيا',
  'SD': 'السودان',
  'MA': 'المغرب',
  'DZ': 'الجزائر',
  'TN': 'تونس',
};

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) => TimelineRepository());

class TimelineRepository {
  /// The dashboard default, used until the mother picks her own country.
  Future<String> fetchDefaultCountry() async {
    final setting = await SupabaseBootstrap.client
        .from('app_settings')
        .select('value')
        .eq('key', 'vaccine_country')
        .maybeSingle();
    final code = (setting?['value'] as String?)?.trim() ?? '';
    return vaccineCountries.containsKey(code) ? code : 'EG';
  }

  /// Vaccines of [country] only; skills and feeding items are shared by all countries.
  Future<List<TimelineItem>> fetchItems(String country) async {
    final rows = await SupabaseBootstrap.client
        .from('baby_timeline')
        .select('id, kind, age_days, title, body, tips, source_name, source_url')
        .eq('publish_status', 'published')
        .or('country.is.null,country.eq.$country')
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
