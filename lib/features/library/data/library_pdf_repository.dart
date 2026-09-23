import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_pdf.dart';

final libraryPdfRepositoryProvider = Provider<LibraryPdfRepository>((ref) {
  return const LibraryPdfRepository();
});

/// Published rows only — RLS hides drafts from app users.
final libraryPdfsProvider = FutureProvider<List<LibraryPdf>>((ref) {
  return ref.watch(libraryPdfRepositoryProvider).fetchPublished();
});

class LibraryPdfRepository {
  const LibraryPdfRepository();

  static const _table = 'library_pdfs';
  static const _bucket = 'library-pdfs';

  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<List<LibraryPdf>> fetchPublished() async {
    if (!await _ready()) return const [];
    final rows = await SupabaseBootstrap.client
        .from(_table)
        .select()
        .eq('publish_status', 'published')
        .order('sort_order')
        .order('created_at');
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (kDebugMode && list.isEmpty) debugPrint('[LibraryPdf] no published rows');
    return list.map(LibraryPdf.fromRow).toList();
  }

  Future<Uint8List> downloadBytes(LibraryPdf pdf) async {
    final path = pdf.filePath;
    if (path == null || path.isEmpty) throw StateError('PDF has no file');
    if (!await _ready()) throw StateError('Supabase not ready');
    return SupabaseBootstrap.client.storage.from(_bucket).download(path);
  }

  /// Short-lived link; the bucket is private and needs a signed-in user.
  Future<Uri?> signedUrl(LibraryPdf pdf, {bool download = false}) async {
    final path = pdf.filePath;
    if (path == null || path.isEmpty || !await _ready()) return null;
    try {
      final url = await SupabaseBootstrap.client.storage
          .from(_bucket)
          .createSignedUrl(path, 600);
      if (!download) return Uri.parse(url);
      final fileName = path.split('/').last;
      return Uri.parse('$url&download=${Uri.encodeQueryComponent(fileName)}');
    } catch (e) {
      if (kDebugMode) debugPrint('[LibraryPdf] signed url failed: $e');
      return null;
    }
  }
}
