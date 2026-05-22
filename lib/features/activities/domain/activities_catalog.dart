import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../library/domain/library_media_catalog.dart';

/// فئة عمرية لأنشطة الطفل (لعب إبداعي وغيره).
class ActivityAgeGroup {
  const ActivityAgeGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    this.parentNote,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<LibraryMediaItem> items;
  final String? parentNote;
}

LibraryMediaItem _playlist(
  String id,
  String title,
  String playlistId, {
  String? moodTag,
}) {
  return LibraryMediaItem(
    id: id,
    title: title,
    playlistId: playlistId,
    moodTag: moodTag ?? 'قائمة',
  );
}

/// قائمة اللعب الإبداعي 9–36 شهر.
const creativePlayPlaylistId = 'PLFYChdcFDqm1WqBec1DNB2VIOLRD_Mdgs';

final activityAgeGroups = <ActivityAgeGroup>[
  ActivityAgeGroup(
    id: 'age_0_3',
    title: '0 – 3 أشهر',
    subtitle: 'أنشطة حسية مبكرة',
    icon: Symbols.child_care,
    items: const [],
    parentNote: 'محتوى هذا العمر قيد الإضافة قريباً.',
  ),
  ActivityAgeGroup(
    id: 'age_4_6',
    title: '4 – 6 أشهر',
    subtitle: 'استكشاف وتحفيز',
    icon: Symbols.baby_changing_station,
    items: const [],
    parentNote: 'محتوى هذا العمر قيد الإضافة قريباً.',
  ),
  ActivityAgeGroup(
    id: 'age_6_9',
    title: '6 – 9 أشهر',
    subtitle: 'لعب تفاعلي',
    icon: Symbols.toys,
    items: const [],
    parentNote: 'محتوى هذا العمر قيد الإضافة قريباً.',
  ),
  ActivityAgeGroup(
    id: 'age_9_12',
    title: '9 – 12 شهر',
    subtitle: 'لعب إبداعي',
    icon: Symbols.palette,
    items: [
      _playlist(
        'act_9_12',
        'لعب إبداعي (9–36 شهر)',
        creativePlayPlaylistId,
        moodTag: 'لعب مشترك',
      ),
    ],
    parentNote:
        'أنشطة اللعب الإبداعي للرضيع والطفل الصغير — ذكريات ممتعة لكِ ولطفلك.',
  ),
  ActivityAgeGroup(
    id: 'age_12_18',
    title: 'سنة – سنة ونصف',
    subtitle: 'لعب إبداعي',
    icon: Symbols.brush,
    items: [
      _playlist(
        'act_12_18',
        'لعب إبداعي (9–36 شهر)',
        creativePlayPlaylistId,
        moodTag: 'إبداع',
      ),
    ],
  ),
  ActivityAgeGroup(
    id: 'age_18_24',
    title: 'سنة ونصف – سنتين',
    subtitle: 'لعب إبداعي',
    icon: Symbols.extension,
    items: [
      _playlist(
        'act_18_24',
        'لعب إبداعي (9–36 شهر)',
        creativePlayPlaylistId,
        moodTag: 'إبداع',
      ),
    ],
  ),
  ActivityAgeGroup(
    id: 'age_9_36',
    title: '9 – 36 شهر',
    subtitle: 'لعب إبداعي — كامل',
    icon: Symbols.sports_esports,
    items: [
      _playlist(
        'act_9_36',
        'لعب إبداعي للرضيع والطفل',
        creativePlayPlaylistId,
        moodTag: 'قائمة كاملة',
      ),
    ],
    parentNote:
        'قائمة #9-36 months — Creative Play: أنشطة للأطفال والصغار للعب المشترك مع الأم.',
  ),
];

ActivityAgeGroup? activityAgeGroupById(String id) {
  for (final group in activityAgeGroups) {
    if (group.id == id) return group;
  }
  return null;
}
