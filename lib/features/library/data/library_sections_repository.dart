import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_section_items.dart';

final librarySectionsRepositoryProvider = Provider<LibrarySectionsRepository>((ref) {
  return const LibrarySectionsRepository();
});

final libraryPaidBooksProvider = FutureProvider<List<LibraryPaidBook>>((ref) {
  return ref.watch(librarySectionsRepositoryProvider).fetchPaidBooks();
});

final libraryVisualVideosProvider = FutureProvider<List<LibraryVisualVideo>>((ref) {
  return ref.watch(librarySectionsRepositoryProvider).fetchVisualVideos();
});

/// International digits only (e.g. 967779785385), or empty when not set.
final libraryWhatsappNumberProvider = FutureProvider<String>((ref) {
  return ref.watch(librarySectionsRepositoryProvider).fetchWhatsappNumber();
});

class LibrarySectionsRepository {
  const LibrarySectionsRepository();

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<Map<String, dynamic>>> _published(String table) async {
    if (!await _ready()) return const [];
    final rows = await SupabaseBootstrap.client
        .from(table)
        .select()
        .eq('publish_status', 'published')
        .order('sort_order')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<LibraryPaidBook>> fetchPaidBooks() async {
    final rows = await _published('library_paid_books');
    return rows.map(LibraryPaidBook.fromRow).toList();
  }

  Future<List<LibraryVisualVideo>> fetchVisualVideos() async {
    final rows = await _published('library_visual_videos');
    return rows.map(LibraryVisualVideo.fromRow).where((v) => v.isPlayable).toList();
  }

  Future<String> fetchWhatsappNumber() async {
    if (!await _ready()) return '';
    try {
      final row = await SupabaseBootstrap.client
          .from('app_settings')
          .select('value')
          .eq('key', 'library_whatsapp')
          .maybeSingle();
      return ((row?['value'] as String?) ?? '').replaceAll(RegExp(r'\D'), '');
    } catch (e) {
      if (kDebugMode) debugPrint('[LibrarySections] whatsapp fetch failed: $e');
      return '';
    }
  }
}
