import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

/// Raw rows from Supabase content tables (Phase 3).
class ContentRemoteDataSource {
  const ContentRemoteDataSource();

  Future<List<Map<String, dynamic>>> fetchPublishedLibraryItems() async {
    if (!await _ready()) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('library_items')
          .select()
          .eq('publish_status', 'published')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Content] library fetch failed: $e\n$st');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublishedAgeHubGroups(
    String hubType,
  ) async {
    if (!await _ready()) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('age_hub_groups')
          .select()
          .eq('hub_type', hubType)
          .eq('publish_status', 'published')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Content] age_hub_groups ($hubType) failed: $e\n$st');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublishedAgeHubItems(
    List<String> groupIds,
  ) async {
    if (!await _ready() || groupIds.isEmpty) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('age_hub_items')
          .select()
          .inFilter('group_id', groupIds)
          .eq('publish_status', 'published')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Content] age_hub_items failed: $e\n$st');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchPublishedQuranSession({
    required int khatmah,
    required int sessionNumber,
  }) async {
    if (!await _ready()) return null;

    try {
      final row = await SupabaseBootstrap.client
          .from('quran_sessions')
          .select()
          .eq('khatmah', khatmah)
          .eq('session_number', sessionNumber)
          .eq('publish_status', 'published')
          .maybeSingle();

      return row;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Content] quran session failed: $e\n$st');
      return null;
    }
  }

  /// All published sessions for a khatmah (ordered by session_number).
  Future<List<Map<String, dynamic>>> fetchPublishedQuranSessionsForKhatmah(
    int khatmah,
  ) async {
    if (!await _ready()) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('quran_sessions')
          .select()
          .eq('khatmah', khatmah)
          .eq('publish_status', 'published')
          .order('session_number');

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Content] quran sessions list failed: $e\n$st');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublishedOnboardingVideos() async {
    if (!await _ready()) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('onboarding_videos')
          .select()
          .eq('publish_status', 'published')
          .order('slot');

      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Content] onboarding videos fetch failed: $e\n$st');
      }
      return [];
    }
  }

  Future<String?> signedQuranAudioUrl(String storagePath) async {
    if (!await _ready() || storagePath.isEmpty) return null;

    try {
      return await SupabaseBootstrap.client.storage
          .from('quran-audio')
          .createSignedUrl(storagePath, 3600 * 6);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Content] signed URL failed: $e\n$st');
      return null;
    }
  }

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }
    return SupabaseBootstrap.isReady;
  }
}
