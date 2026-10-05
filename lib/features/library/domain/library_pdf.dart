import 'library_age_band.dart';

class LibraryPdf {
  const LibraryPdf({
    required this.id,
    required this.title,
    required this.ageBand,
    required this.tagLabel,
    this.description = '',
    this.pageCount,
    this.pageLabel = 'صفحة',
    this.fileSizeBytes,
    this.coverUrl,
    this.filePath,
  });

  final String id;
  final String title;
  final LibraryAgeBand ageBand;

  /// النص الملوّن الصغير فوق العنوان (مثل «دليل إرشادي شامل»).
  final String tagLabel;
  final String description;
  final int? pageCount;

  /// الكلمة بعد عدد الصفحات (مثل «صفحة مصورة»).
  final String pageLabel;
  final int? fileSizeBytes;
  final String? coverUrl;

  /// المسار داخل bucket «library-pdfs» الخاص.
  final String? filePath;

  bool get hasFile => filePath != null && filePath!.isNotEmpty;

  String? get pagesText => pageCount == null ? null : '$pageCount $pageLabel';

  String? get sizeText {
    final bytes = fileSizeBytes;
    if (bytes == null || bytes <= 0) return null;
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} م.ب';
    return '${(bytes / 1024).ceil()} ك.ب';
  }

  factory LibraryPdf.fromRow(Map<String, dynamic> row) {
    return LibraryPdf(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'ملف PDF',
      ageBand: LibraryAgeBand.fromDb(row['age_band'] as String?),
      tagLabel: row['tag_label'] as String? ?? '',
      description: row['description'] as String? ?? '',
      pageCount: (row['page_count'] as num?)?.toInt(),
      pageLabel: row['page_label'] as String? ?? 'صفحة',
      fileSizeBytes: (row['file_size_bytes'] as num?)?.toInt(),
      coverUrl: row['cover_url'] as String?,
      filePath: row['file_path'] as String?,
    );
  }
}
