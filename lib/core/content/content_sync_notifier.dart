import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_bootstrap.dart';
import '../supabase/supabase_health_check.dart';
import 'content_fetch_result.dart';

enum ContentSyncSeverity { ok, info, warning, error }

class ContentSyncState {
  const ContentSyncState({
    this.severity = ContentSyncSeverity.ok,
    this.bannerMessage,
    this.details = const [],
    this.lastCheckedAt,
  });

  final ContentSyncSeverity severity;
  final String? bannerMessage;
  final List<String> details;
  final DateTime? lastCheckedAt;

  bool get showBanner => bannerMessage != null && bannerMessage!.isNotEmpty;
}

class ContentSyncNotifier extends AsyncNotifier<ContentSyncState> {
  ContentSyncState? _healthBaseline;
  final _reports = <String, ContentFetchResult<dynamic>>{};

  @override
  Future<ContentSyncState> build() async {
    _reports.clear();
    _healthBaseline = await _healthState();
    return _mergeState();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _reports.clear();
    _healthBaseline = await _healthState();
    state = AsyncData(_mergeState());
  }

  void reportFetch(String key, ContentFetchResult<dynamic> result) {
    _reports[key] = result;
    final merged = _mergeState();
    state = AsyncData(merged);
  }

  Future<ContentSyncState> _healthState() async {
    if (!SupabaseBootstrap.isEnabled) {
      return ContentSyncState(
        severity: ContentSyncSeverity.warning,
        bannerMessage:
            'المحتوى السحابي غير مفعّل. شغّلي: flutter run --dart-define-from-file=dart_defines.json',
        details: const ['Supabase: غير مُكوَّن في هذا البناء'],
        lastCheckedAt: DateTime.now(),
      );
    }

    final health = await SupabaseHealthCheck.run();
    health.logToConsole();

    if (!health.initialized) {
      return ContentSyncState(
        severity: ContentSyncSeverity.error,
        bannerMessage: 'تعذر الاتصال بـ Supabase. تحققي من المفتاح والإنترنت.',
        details: [
          if (health.initError != null) health.initError!,
        ],
        lastCheckedAt: DateTime.now(),
      );
    }

    if (!health.hasPublishedContent) {
      return ContentSyncState(
        severity: ContentSyncSeverity.warning,
        bannerMessage:
            'متصل بـ Supabase — لا يوجد محتوى منشور (published) بعد. انشري من لوحة الأدمن.',
        details: [
          for (final p in health.probes) '${p.table}: ${p.publishedCount}',
        ],
        lastCheckedAt: DateTime.now(),
      );
    }

    return ContentSyncState(
      severity: ContentSyncSeverity.ok,
      details: [
        for (final p in health.probes)
          if (p.ok) '${p.table}: ${p.publishedCount} منشور',
      ],
      lastCheckedAt: DateTime.now(),
    );
  }

  ContentSyncState _mergeState() {
    final baseline = _healthBaseline ?? const ContentSyncState();
    if (baseline.severity == ContentSyncSeverity.error) return baseline;

    ContentSyncSeverity severity = baseline.severity;
    String? banner = baseline.bannerMessage;
    final details = List<String>.from(baseline.details);

    for (final entry in _reports.entries) {
      final r = entry.value;
      if (!r.shouldWarnUser) continue;

      final msg = r.userMessageAr(entry.key);
      if (!details.contains(msg)) details.add(msg);

      if (r.source == ContentFetchSource.errorFallback) {
        severity = ContentSyncSeverity.error;
        banner = msg;
      } else if (r.source == ContentFetchSource.supabaseDisabled) {
        if (severity != ContentSyncSeverity.error) {
          severity = ContentSyncSeverity.warning;
          banner ??= msg;
        }
      } else if (severity == ContentSyncSeverity.ok) {
        severity = ContentSyncSeverity.warning;
        banner ??= msg;
      }
    }

    if (severity == ContentSyncSeverity.ok) {
      return ContentSyncState(
        severity: severity,
        details: details,
        lastCheckedAt: DateTime.now(),
      );
    }

    return ContentSyncState(
      severity: severity,
      bannerMessage: banner,
      details: details,
      lastCheckedAt: DateTime.now(),
    );
  }
}

final contentSyncProvider =
    AsyncNotifierProvider<ContentSyncNotifier, ContentSyncState>(
  ContentSyncNotifier.new,
);
