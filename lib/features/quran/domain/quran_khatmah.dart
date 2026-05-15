import 'package:flutter/foundation.dart';

import 'quran_reciter.dart';

@immutable
class QuranKhatmah {
  const QuranKhatmah({
    required this.index,
    required this.reciter,
    this.qiraat,
  });

  /// 1-based khatmah number (1..50).
  final int index;
  final QuranReciter reciter;

  /// Optional recitation style for later khatmahs.
  final String? qiraat;

  String get id => 'khatmah_${index.toString().padLeft(2, '0')}';
}
