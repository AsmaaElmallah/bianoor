/// مصدر البيانات المعروضة للمستخدم.
enum ContentFetchSource {
  /// جُلب من Supabase بنجاح.
  remote,

  /// Supabase متصل لكن لا صفوف منشورة — عُرض المحلي.
  remoteEmpty,

  /// لم تُضبط مفاتيح Supabase في التشغيل.
  supabaseDisabled,

  /// فشل الطلب — عُرض المحلي.
  errorFallback,
}

class ContentFetchResult<T> {
  const ContentFetchResult({
    required this.data,
    required this.source,
    this.errorMessage,
    this.remoteCount,
  });

  final T data;
  final ContentFetchSource source;
  final String? errorMessage;
  final int? remoteCount;

  bool get usedRemote =>
      source == ContentFetchSource.remote || source == ContentFetchSource.remoteEmpty;

  bool get shouldWarnUser =>
      source == ContentFetchSource.supabaseDisabled ||
      source == ContentFetchSource.remoteEmpty ||
      source == ContentFetchSource.errorFallback;

  String userMessageAr(String featureLabel) {
    switch (source) {
      case ContentFetchSource.remote:
        return 'تم تحميل $featureLabel من السحابة';
      case ContentFetchSource.remoteEmpty:
        return 'لا محتوى منشور لـ$featureLabel على السحابة — يُعرض المحتوى المحلي';
      case ContentFetchSource.supabaseDisabled:
        return 'Supabase غير مفعّل — شغّلي التطبيق بـ dart_defines.json';
      case ContentFetchSource.errorFallback:
        final detail = errorMessage != null && errorMessage!.isNotEmpty
            ? ' ($errorMessage)'
            : '';
        return 'تعذر الاتصال بـ$featureLabel$detail — يُعرض المحتوى المحلي';
    }
  }
}
