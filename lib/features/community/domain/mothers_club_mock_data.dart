import 'mothers_club_models.dart';

/// Fallback محلي عند تعطيل Supabase أو فشل الجلب.
List<MothersClubCategory> localMothersClubCategories() {
  return [
    MothersClubCategory(
      id: 'parenting',
      label: 'نصائح التربية',
      icon: MothersClubCategory.iconFromKey('child_care'),
      tint: MothersClubCategory.colorsForId('parenting').$1,
      iconColor: MothersClubCategory.colorsForId('parenting').$2,
    ),
    MothersClubCategory(
      id: 'quran',
      label: 'رحلات قرآنية',
      icon: MothersClubCategory.iconFromKey('menu_book'),
      tint: MothersClubCategory.colorsForId('quran').$1,
      iconColor: MothersClubCategory.colorsForId('quran').$2,
    ),
    MothersClubCategory(
      id: 'nutrition',
      label: 'التغذية',
      icon: MothersClubCategory.iconFromKey('restaurant'),
      tint: MothersClubCategory.colorsForId('nutrition').$1,
      iconColor: MothersClubCategory.colorsForId('nutrition').$2,
    ),
    MothersClubCategory(
      id: 'activities',
      label: 'أنشطة',
      icon: MothersClubCategory.iconFromKey('toys'),
      tint: MothersClubCategory.colorsForId('activities').$1,
      iconColor: MothersClubCategory.colorsForId('activities').$2,
    ),
  ];
}

List<MothersClubPost> localMothersClubPosts() {
  final now = DateTime.now();
  return [
    MothersClubPost(
      id: 'local-1',
      authorDisplayName: 'سارة أحمد',
      title: 'كيف بدأتم تعليم أطفالكم السور القصيرة؟',
      body:
          'بدأت مع طفلي ذو الثلاث سنوات في تحفيظ سورة الفاتحة والإخلاص، وجدت أن التكرار وقت اللعب هو الأكثر فعالية. هل لديكم تجارب أخرى؟',
      tag: '#الختمة_الأولى',
      categoryId: 'quran',
      likeCount: 24,
      commentCount: 12,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    MothersClubPost(
      id: 'local-2',
      authorDisplayName: 'ليلى محمد',
      title: 'وجبات خفيفة وصحية للمدرسة',
      body:
          'أبحث عن أفكار لوجبات خفيفة لا تستغرق وقتاً طويلاً في التحضير وتكون غنية بالعناصر الغذائية الضرورية لنمو الطفل.',
      tag: '#تغذية_الطفل',
      categoryId: 'nutrition',
      likeCount: 45,
      commentCount: 8,
      createdAt: now.subtract(const Duration(hours: 5)),
      likedByMe: true,
      muted: true,
    ),
  ];
}
