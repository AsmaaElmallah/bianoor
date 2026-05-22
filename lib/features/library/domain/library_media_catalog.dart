import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'library_hub_theme.dart';

/// فئة مكتبة الصوت/الفيديو من الرئيسية.
enum LibraryMediaCategoryId {
  natureSounds,
  calmMusic,
  lullabies,
}

class LibraryMediaItem {
  const LibraryMediaItem({
    required this.id,
    required this.title,
    this.videoId,
    this.playlistId,
    this.durationLabel,
    this.moodTag,
    this.natureChip,
  });

  final String id;
  final String title;
  final String? videoId;
  final String? playlistId;
  final String? durationLabel;
  final String? moodTag;
  final NatureSoundChip? natureChip;

  bool get isPlaylist => playlistId != null && playlistId!.isNotEmpty;

  String? get youtubeThumbnailUrl {
    if (videoId != null && videoId!.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }
}

class LibraryMediaCategory {
  const LibraryMediaCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });

  final LibraryMediaCategoryId id;
  final String title;
  final IconData icon;
  final List<LibraryMediaItem> items;
}

const _natureVideos = <({String id, String title, NatureSoundChip chip, String duration, String mood})>[
  (id: 'eKFTSSKCzWA', title: 'قطرات المطر', chip: NatureSoundChip.rain, duration: '10:00', mood: 'مطر'),
  (id: 'UZ9uyQI3pF0', title: 'مطر على النافذة', chip: NatureSoundChip.rain, duration: '08:30', mood: 'هادئ'),
  (id: 'eyez3u8rG54', title: 'غابة الصباح', chip: NatureSoundChip.forest, duration: '12:00', mood: 'غابة'),
  (id: 'R34j1kse4VU', title: 'طيور الغابة', chip: NatureSoundChip.forest, duration: '09:15', mood: 'طبيعة'),
  (id: 'wiJLU60r4gk', title: 'أمواج المحيط', chip: NatureSoundChip.ocean, duration: '11:20', mood: 'محيط'),
  (id: '0iirgixp85Y', title: 'شاطئ هادئ', chip: NatureSoundChip.ocean, duration: '07:45', mood: 'مريح'),
  (id: 'iBXHFjno9r0', title: 'نسيم عليل', chip: NatureSoundChip.wind, duration: '06:00', mood: 'رياح'),
];

const _calmVideos = <({String id, String title, String duration, String mood})>[
  (id: 'XXIRWAEVs8o', title: 'موسيقى نوم هادئة', duration: '04:20', mood: 'مريح'),
  (id: '6lEwV7hk1hk', title: 'بيانو للرضع', duration: '05:10', mood: 'نوم'),
  (id: 'flDO0Sgmvas', title: 'ألحان استرخاء', duration: '06:30', mood: 'هادئ'),
  (id: 'qVEXupgEP4Y', title: 'موجات دلتا', duration: '08:00', mood: 'عميق'),
  (id: 'flJo10TDHcU', title: 'ليل هادئ', duration: '04:50', mood: 'نوم'),
  (id: 'tDVyPiRnAEw', title: 'نجوم الليل', duration: '07:15', mood: 'مريح'),
];

final libraryMediaCategories = <LibraryMediaCategory>[
  LibraryMediaCategory(
    id: LibraryMediaCategoryId.natureSounds,
    title: 'أصوات الطبيعة',
    icon: Symbols.park,
    items: [
      for (final v in _natureVideos)
        LibraryMediaItem(
          id: 'nature_${v.id}',
          title: v.title,
          videoId: v.id,
          durationLabel: v.duration,
          moodTag: v.mood,
          natureChip: v.chip,
        ),
    ],
  ),
  LibraryMediaCategory(
    id: LibraryMediaCategoryId.calmMusic,
    title: 'الموسيقى الهادئة',
    icon: Symbols.music_note,
    items: [
      for (final v in _calmVideos)
        LibraryMediaItem(
          id: 'calm_${v.id}',
          title: v.title,
          videoId: v.id,
          durationLabel: v.duration,
          moodTag: v.mood,
        ),
    ],
  ),
  LibraryMediaCategory(
    id: LibraryMediaCategoryId.lullabies,
    title: 'تهويدات النوم',
    icon: Symbols.bedtime,
    items: const [
      LibraryMediaItem(
        id: 'lullaby_1',
        title: 'أغنية الخروف الصغير',
        videoId: 'UHVcRjfufic',
        durationLabel: '03:45',
        moodTag: 'هادئة جداً',
      ),
      LibraryMediaItem(
        id: 'lullaby_playlist',
        title: 'تهويدات من أنحاء العالم',
        playlistId: 'PLVdBsyVAy4VRfI-rG7LvjNSalxOdcSv-e',
        durationLabel: 'قائمة',
        moodTag: 'كلاسيك',
      ),
      LibraryMediaItem(
        id: 'lullaby_2',
        title: 'يا نجوم الليل',
        videoId: 'de30kR5jFJ4',
        durationLabel: '05:12',
        moodTag: 'كلاسيك',
      ),
      LibraryMediaItem(
        id: 'lullaby_3',
        title: 'حلم الحوت الأزرق',
        videoId: 'EsMGye9r8eg',
        durationLabel: '04:20',
        moodTag: 'أصوات الطبيعة',
      ),
      LibraryMediaItem(
        id: 'lullaby_4',
        title: 'تهويدة القمر',
        videoId: '6u8VP_X371c',
        durationLabel: '04:00',
        moodTag: 'نوم',
      ),
    ],
  ),
];

List<LibraryMediaItem> libraryItemsForNatureChip(
  List<LibraryMediaItem> items,
  NatureSoundChip chip,
) {
  return items.where((i) => i.natureChip == chip).toList();
}

LibraryMediaCategoryId? libraryCategoryIdFromMenuId(String menuId) {
  switch (menuId) {
    case 'nature_sounds':
      return LibraryMediaCategoryId.natureSounds;
    case 'calm_music':
      return LibraryMediaCategoryId.calmMusic;
    case 'lullabies':
      return LibraryMediaCategoryId.lullabies;
    default:
      return null;
  }
}

LibraryMediaCategory? libraryCategoryByMenuId(String menuId) {
  final catId = libraryCategoryIdFromMenuId(menuId);
  if (catId == null) return null;
  for (final c in libraryMediaCategories) {
    if (c.id == catId) return c;
  }
  return null;
}

/// رابط تضمين YouTube للعرض داخل التطبيق.
String libraryYoutubeEmbedUrl({String? videoId, String? playlistId}) {
  if (playlistId != null && playlistId.isNotEmpty) {
    return 'https://www.youtube.com/embed/videoseries?list=$playlistId&autoplay=1&rel=0';
  }
  return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
}
