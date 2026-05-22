import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../library/domain/library_media_catalog.dart';

/// فئة عمرية لتمارين ومساج الأطفال.
class ExerciseAgeGroup {
  const ExerciseAgeGroup({
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

/// استخراج معرّف فيديو أو قائمة من رابط يوتيوب.
({String? videoId, String? playlistId}) parseYoutubeLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return (videoId: null, playlistId: null);

  final list = uri.queryParameters['list'];
  if (list != null && list.isNotEmpty) {
    return (videoId: null, playlistId: list);
  }

  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return (videoId: uri.pathSegments.first, playlistId: null);
  }

  if (uri.pathSegments.contains('shorts') && uri.pathSegments.length >= 2) {
    final i = uri.pathSegments.indexOf('shorts');
    return (videoId: uri.pathSegments[i + 1], playlistId: null);
  }

  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) {
    return (videoId: v, playlistId: null);
  }

  return (videoId: null, playlistId: null);
}

LibraryMediaItem _item(
  String id,
  String title,
  String url, {
  String? moodTag,
}) {
  final parsed = parseYoutubeLink(url);
  return LibraryMediaItem(
    id: id,
    title: title,
    videoId: parsed.videoId,
    playlistId: parsed.playlistId,
    moodTag: moodTag,
  );
}

const _noteChineseGradual =
    'ملاحظة: التمارين الصينية تُمارس بالتدريج البطيء حتى يصل الطفل للشهر الثالث لهذه المرونة.';

final exerciseAgeGroups = <ExerciseAgeGroup>[
  ExerciseAgeGroup(
    id: 'age_0_3',
    title: '0 – 3 أشهر',
    subtitle: 'تمارين ومساج الرضيع',
    icon: Symbols.child_care,
    parentNote: _noteChineseGradual,
    items: [
      _item('0_3_1', 'تمرين ومساج ١', 'https://youtu.be/i1qtB9TzdGA'),
      _item('0_3_2', 'تمرين ومساج ٢', 'https://youtu.be/OAe1C-kAliU'),
      _item('0_3_3', 'تمرين قصير ١', 'https://youtube.com/shorts/Zu8jIRD4xTI'),
      _item('0_3_4', 'تمرين قصير ٢', 'https://youtube.com/shorts/r-w2RkQXzjM'),
      _item('0_3_5', 'للتنويم', 'https://youtube.com/shorts/qF83rdkkKSA', moodTag: 'تنويم'),
      _item('0_3_6', 'تمرين ٦', 'https://youtu.be/GfGxJX6KJjw'),
      _item('0_3_7', 'تمرين ٧', 'https://youtu.be/nLzVts5j0SI'),
      _item('0_3_8', 'تمرين ٨', 'https://youtu.be/RfI4l9zLGc4'),
    ],
  ),
  ExerciseAgeGroup(
    id: 'age_4_6',
    title: '4 – 6 أشهر',
    subtitle: 'تنشيط وحركة مبكرة',
    icon: Symbols.baby_changing_station,
    items: [
      _item('4_6_1', 'تمرين قصير ١', 'https://youtube.com/shorts/puUzPozUdP0'),
      _item('4_6_2', 'تمرين قصير ٢', 'https://youtube.com/shorts/sc8JClYxlZQ'),
      _item('4_6_3', 'تمرين قصير ٣', 'https://youtube.com/shorts/snf5mD8MLuQ'),
      _item('4_6_4', 'تمرين قصير ٤', 'https://youtube.com/shorts/FHuLEsbdMOE'),
      _item('4_6_5', 'تمرين ٥', 'https://youtu.be/euyou2eaLOA'),
      _item('4_6_6', 'تمرين ٦', 'https://youtu.be/8bAGeE4sjfk'),
      _item(
        '4_6_pl_1',
        'تمارين 3–6 أشهر (قائمة)',
        'https://youtube.com/playlist?list=PLFYChdcFDqm1OvmAgkeCIrZ-Rzevai8km',
        moodTag: 'قائمة',
      ),
      _item(
        '4_6_pl_2',
        'سباحة الأطفال (قائمة)',
        'https://youtube.com/playlist?list=PLFYChdcFDqm1c8ih6v0PK_yLK0s6S8nRY',
        moodTag: 'قائمة',
      ),
    ],
  ),
  ExerciseAgeGroup(
    id: 'age_6_9',
    title: '6 – 9 أشهر',
    subtitle: 'زحف ونشاط',
    icon: Symbols.directions_run,
    items: [
      _item(
        '6_9_pl_1',
        'جمباز الرضيع 6–9 (قائمة)',
        'https://youtube.com/playlist?list=PLFYChdcFDqm1NGVpQlD3HJqva_nVl5KC_',
        moodTag: 'قائمة',
      ),
      _item('6_9_2', 'تمرين ٢', 'https://youtu.be/6bQKjpeQfkQ'),
      _item('6_9_3', 'تمرين ٣', 'https://youtu.be/OR8AI10WeyE'),
      _item(
        '6_9_pl_2',
        'تعليم الزحف (قائمة)',
        'https://youtube.com/playlist?list=PLFYChdcFDqm39E4Ppz4aH_MjlCskhVswy',
        moodTag: 'قائمة',
      ),
    ],
  ),
  ExerciseAgeGroup(
    id: 'age_9_12',
    title: '9 – 12 شهر',
    subtitle: 'وقوف ومشي مبكر',
    icon: Symbols.directions_walk,
    items: [
      _item(
        '9_12_pl',
        'تعليم المشي والوقوف (قائمة)',
        'https://youtube.com/playlist?list=PLFYChdcFDqm0VsWxvQEbj6pL690ANPDZk',
        moodTag: 'قائمة',
      ),
    ],
  ),
  ExerciseAgeGroup(
    id: 'age_12_18',
    title: 'سنة – سنة ونصف',
    subtitle: 'توازن وحركة',
    icon: Symbols.sports_gymnastics,
    items: [
      _item('12_18_1', 'تمرين ١', 'https://youtu.be/qsgdOo1gcw4'),
      _item('12_18_2', 'تمرين ٢', 'https://youtu.be/zzgbM2woqPI'),
      _item('12_18_3', 'تمرين ٣', 'https://youtu.be/n9qCcDMeWGw'),
    ],
  ),
  ExerciseAgeGroup(
    id: 'age_18_24',
    title: 'سنة ونصف – سنتين',
    subtitle: 'نشاط وتنسيق',
    icon: Symbols.sports_soccer,
    items: [
      _item('18_24_1', 'تمرين ١', 'https://youtu.be/zzgbM2woqPI'),
      _item('18_24_2', 'تمرين ٢', 'https://youtu.be/_askVfAzqdY'),
      _item('18_24_3', 'تمرين ٣', 'https://youtu.be/zxiNU78BD_Q'),
      _item('18_24_4', 'تمرين ٤', 'https://youtu.be/8_FLdwGxxPk'),
      _item('18_24_5', 'تمرين ٥', 'https://youtu.be/QIxIjwEB7DA'),
      _item('18_24_6', 'تمرين ٦', 'https://youtu.be/T67NVvu8BRk'),
      _item('18_24_7', 'تمرين ٧', 'https://youtu.be/xae5xvSGsWA'),
      _item('18_24_8', 'تمرين ٨', 'https://youtu.be/lDMvmOouXTw'),
      _item('18_24_9', 'تمرين ٩', 'https://youtu.be/RpNMEfKQMo8'),
      _item('18_24_10', 'تمرين ١٠', 'https://youtu.be/YU9DDuysUWQ'),
      _item('18_24_11', 'تمرين ١١', 'https://youtu.be/P0IlvsCtx3U'),
      _item('18_24_12', 'تمرين ١٢', 'https://youtu.be/6i2tZMIk_R4'),
      _item('18_24_13', 'تمرين ١٣', 'https://youtu.be/U-_wGm8jPeI'),
      _item('18_24_14', 'تمرين ١٤', 'https://youtu.be/TFx_Ct8E_BE'),
      _item('18_24_15', 'تمرين ١٥', 'https://youtu.be/VDpz5EQgIyU'),
      _item('18_24_16', 'تمرين ١٦', 'https://youtu.be/45sVmmwBoc8'),
      _item('18_24_17', 'تمرين ١٧', 'https://youtu.be/BYzx2Kxp1X0'),
      _item('18_24_18', 'تمرين ١٨', 'https://youtu.be/49jUtQXMnJI'),
      _item('18_24_19', 'تمرين ١٩', 'https://youtu.be/_K45xrc_36Y'),
      _item('18_24_20', 'تمرين ٢٠', 'https://youtu.be/bKwRnHSdFus'),
      _item('18_24_21', 'تمرين ٢١', 'https://youtu.be/hzkmIesyx_s'),
      _item('18_24_22', 'تمرين ٢٢', 'https://youtu.be/iVvraQVbeqo'),
      _item('18_24_23', 'تمرين ٢٣', 'https://youtu.be/Gn8AzfeEDUI'),
    ],
  ),
];

ExerciseAgeGroup? exerciseAgeGroupById(String id) {
  for (final group in exerciseAgeGroups) {
    if (group.id == id) return group;
  }
  return null;
}
