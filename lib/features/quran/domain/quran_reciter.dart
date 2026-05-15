import 'package:flutter/foundation.dart';

@immutable
class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.name,
    this.voiceNote = 'صوت واضح وهادئ ومريح',
  });

  final String id;
  final String name;
  final String voiceNote;
}
