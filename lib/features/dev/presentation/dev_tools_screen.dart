import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/content/content_providers.dart';
import '../../../core/content/content_sync_notifier.dart';
import '../../library/data/library_repository.dart';
import '../../../core/dev/dev_journey_service.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/supabase/supabase_health_check.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../emotional/application/emotional_curriculum_provider.dart';
import '../../math/application/math_curriculum_provider.dart';
import '../../quran/application/quran_curriculum_provider.dart';
import '../../visual/application/visual_curriculum_provider.dart';

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  SupabaseHealthReport? _report;
  bool _loadingHealth = false;
  String? _libraryProbe;
  Map<String, int> _slideCounts = const {};

  @override
  void initState() {
    super.initState();
    _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    setState(() => _loadingHealth = true);
    final report = await SupabaseHealthCheck.run();
    report.logToConsole();

    String? libraryMsg;
    var slideCounts = <String, int>{};
    if (report.initialized) {
      try {
        final cats = await const LibraryRepository().loadCategories();
        final remoteCount = cats.fold<int>(0, (n, c) => n + c.items.length);
        libraryMsg = 'المكتبة: $remoteCount عنصراً بعد الدمج';
      } catch (e) {
        libraryMsg = 'المكتبة: خطأ $e';
      }

      final repo = ref.read(curriculumSlidesRepositoryProvider);
      for (final track in ['math', 'visual', 'emotional']) {
        try {
          slideCounts[track] = (await repo.slidesForTrack(track)).length;
        } catch (e) {
          slideCounts[track] = -1;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _report = report;
      _libraryProbe = libraryMsg;
      _slideCounts = slideCounts;
      _loadingHealth = false;
    });
  }

  Future<void> _unlockJourney() async {
    final prefs = ref.read(prefsServiceProvider);
    await DevJourneyService(prefs).unlockFullTwoYearJourney();
    await ref.read(userProgressSyncProvider).pushIfLoggedIn();
    ref.invalidate(mathCurriculumProvider);
    ref.invalidate(visualCurriculumProvider);
    ref.invalidate(emotionalCurriculumProvider);
    ref.invalidate(quranCurriculumProvider);
    ref.read(curriculumSlidesRepositoryProvider).clearCache();
    ref.invalidate(curriculumCloudSlideCountProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم فتح رحلة السنتين (يوم 730) — ارجعي للدروس')),
    );
  }

  Future<void> _resetJourney() async {
    final prefs = ref.read(prefsServiceProvider);
    await DevJourneyService(prefs).resetJourneyToDayOne();
    ref.invalidate(mathCurriculumProvider);
    ref.invalidate(visualCurriculumProvider);
    ref.invalidate(emotionalCurriculumProvider);
    ref.invalidate(quranCurriculumProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إعادة الرحلة لليوم 1')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsServiceProvider);
    final contentSync = ref.watch(contentSyncProvider).valueOrNull;
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات المطوّر'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (contentSync != null && contentSync.showBanner) ...[
            _InfoTile('تنبيه المحتوى', contentSync.bannerMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          _SectionTitle('Supabase'),
          _InfoTile(
            'مُفعَّل في البناء',
            SupabaseBootstrap.isEnabled ? 'نعم' : 'لا — شغّلي بـ dart_defines.json',
          ),
          if (SupabaseConfig.isConfigured)
            _InfoTile('الرابط', SupabaseConfig.url, maxLines: 2),
          if (_loadingHealth)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (report != null) ...[
            _InfoTile('تهيئة العميل', report.initialized ? 'نجحت' : 'فشلت'),
            if (report.initError != null)
              _InfoTile('خطأ التهيئة', report.initError!, isError: true),
            for (final probe in report.probes)
              _InfoTile(
                probe.table,
                probe.ok ? '${probe.publishedCount} منشور' : probe.error!,
                isError: !probe.ok,
              ),
            if (_libraryProbe != null) _InfoTile('اختبار المكتبة', _libraryProbe!),
            for (final entry in _slideCounts.entries)
              _InfoTile(
                'شرائح ${entry.key}',
                entry.value < 0 ? 'خطأ في الجلب' : '${entry.value} منشورة (playable)',
              ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loadingHealth ? null : _refreshHealth,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة فحص Supabase'),
          ),
          const SizedBox(height: 28),
          _SectionTitle('رحلة السنتين (محلي)'),
          _InfoTile('اليوم الرياضيات', '${prefs.getMathCurriculumDay()}'),
          _InfoTile('اليوم البصري', '${prefs.getVisualCurriculumDay()}'),
          _InfoTile('اليوم العاطفي', '${prefs.getEmotionalCurriculumDay()}'),
          _InfoTile(
            'تجاوز التقويم',
            prefs.isDevBypassProgramCalendar() ? 'مفعّل' : 'معطّل',
          ),
          _InfoTile(
            'فتح كل الدروس',
            prefs.isDevUnlockAllLessons() ? 'مفعّل' : 'معطّل',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _unlockJourney,
            icon: const Icon(Icons.lock_open),
            label: const Text('فتح السنتين: ٥٠ ختمة + ٧٣٠ يوم + كل الدروس مفتوحة'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _resetJourney,
            icon: const Icon(Icons.restart_alt),
            label: const Text('إعادة الرحلة للبداية'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'للتشغيل من الطرفية:\nflutter run --dart-define-from-file=dart_defines.json',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value, {this.isError = false, this.maxLines = 3});

  final String label;
  final String value;
  final bool isError;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isError ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
