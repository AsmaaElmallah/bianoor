import '../../payments/domain/payment_item.dart';
import 'library_age_band.dart';

/// كتاب مدفوع — صورة ونص من الإدارة. الشراء بواتساب أو PayPal لو السعر بالدولار مضبوط.
class LibraryPaidBook {
  const LibraryPaidBook({
    required this.id,
    required this.ageBand,
    required this.title,
    this.description = '',
    this.coverUrl,
    this.priceUsd,
  });

  final String id;
  final LibraryAgeBand ageBand;
  final String title;
  final String description;
  final String? coverUrl;
  final double? priceUsd;

  factory LibraryPaidBook.fromRow(Map<String, dynamic> row) {
    return LibraryPaidBook(
      id: row['id'] as String,
      ageBand: LibraryAgeBand.fromDb(row['age_band'] as String?),
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      coverUrl: row['cover_url'] as String?,
      priceUsd: parseUsd(row['price_usd']),
    );
  }
}

/// فيديو تحفيز بصري — رابط YouTube أو ملف مرفوع.
class LibraryVisualVideo {
  const LibraryVisualVideo({
    required this.id,
    required this.ageBand,
    required this.title,
    this.description = '',
    this.youtubeVideoId,
    this.videoUrl,
    this.coverUrl,
  });

  final String id;
  final LibraryAgeBand ageBand;
  final String title;
  final String description;
  final String? youtubeVideoId;
  final String? videoUrl;
  final String? coverUrl;

  bool get isPlayable =>
      (youtubeVideoId?.trim().isNotEmpty ?? false) || (videoUrl?.trim().isNotEmpty ?? false);

  factory LibraryVisualVideo.fromRow(Map<String, dynamic> row) {
    return LibraryVisualVideo(
      id: row['id'] as String,
      ageBand: LibraryAgeBand.fromDb(row['age_band'] as String?),
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      youtubeVideoId: row['youtube_video_id'] as String?,
      videoUrl: row['video_url'] as String?,
      coverUrl: row['cover_url'] as String?,
    );
  }
}
