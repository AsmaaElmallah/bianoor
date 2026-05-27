import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import 'supabase_bootstrap.dart';

class SupabaseTableProbe {
  const SupabaseTableProbe({
    required this.table,
    required this.publishedCount,
    this.error,
  });

  final String table;
  final int publishedCount;
  final String? error;

  bool get ok => error == null;
}

class SupabaseHealthReport {
  const SupabaseHealthReport({
    required this.configured,
    required this.initialized,
    required this.probes,
    this.initError,
  });

  final bool configured;
  final bool initialized;
  final List<SupabaseTableProbe> probes;
  final String? initError;

  int get totalPublished =>
      probes.fold(0, (sum, probe) => sum + probe.publishedCount);

  bool get hasPublishedContent => probes.any((p) => p.publishedCount > 0);

  void logToConsole() {
    debugPrint('─── Supabase ───');
    debugPrint('configured: $configured');
    debugPrint('initialized: $initialized');
    if (initError != null) debugPrint('initError: $initError');
    for (final probe in probes) {
      if (probe.ok) {
        debugPrint('${probe.table}: ${probe.publishedCount} published');
      } else {
        debugPrint('${probe.table}: ERROR ${probe.error}');
      }
    }
    debugPrint('─────────────────');
  }
}

abstract final class SupabaseHealthCheck {
  static Future<SupabaseHealthReport> run() async {
    if (!SupabaseConfig.isConfigured) {
      return const SupabaseHealthReport(
        configured: false,
        initialized: false,
        probes: [],
        initError: 'أضيفي dart_defines.json أو --dart-define=SUPABASE_URL و SUPABASE_ANON_KEY',
      );
    }

    try {
      await SupabaseBootstrap.init();
    } catch (e) {
      return SupabaseHealthReport(
        configured: true,
        initialized: false,
        probes: const [],
        initError: e.toString(),
      );
    }

    final client = SupabaseBootstrap.client;
    final probes = <SupabaseTableProbe>[];

    for (final spec in _tableSpecs) {
      try {
        var query = client.from(spec.table).select(spec.idColumn);
        if (spec.publishedOnly) {
          query = query.eq('publish_status', 'published');
        }
        final rows = await query;
        final count = (rows as List).length;
        probes.add(SupabaseTableProbe(table: spec.label, publishedCount: count));
      } catch (e) {
        probes.add(
          SupabaseTableProbe(
            table: spec.label,
            publishedCount: 0,
            error: e.toString(),
          ),
        );
      }
    }

    return SupabaseHealthReport(
      configured: true,
      initialized: true,
      probes: probes,
    );
  }
}

class _TableSpec {
  const _TableSpec({
    required this.label,
    required this.table,
    required this.idColumn,
    this.publishedOnly = true,
  });

  final String label;
  final String table;
  final String idColumn;
  final bool publishedOnly;
}

const _tableSpecs = [
  _TableSpec(label: 'library_items', table: 'library_items', idColumn: 'id'),
  _TableSpec(label: 'age_hub (exercises)', table: 'age_hub_items', idColumn: 'id'),
  _TableSpec(label: 'quran_sessions', table: 'quran_sessions', idColumn: 'id'),
  _TableSpec(label: 'curriculum_slides', table: 'curriculum_slides', idColumn: 'id'),
  _TableSpec(label: 'mothers_club_posts', table: 'mothers_club_posts', idColumn: 'id'),
  _TableSpec(label: 'community_feedback', table: 'community_feedback', idColumn: 'id', publishedOnly: false),
  _TableSpec(label: 'community_faq_items', table: 'community_faq_items', idColumn: 'id'),
];
