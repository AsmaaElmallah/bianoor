import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_service.dart';

/// App locale from SharedPreferences (defaults to Arabic).
final appLocaleProvider = Provider<Locale>((ref) {
  final code = ref.watch(prefsServiceProvider).getLanguage() ?? 'ar';
  return Locale(code);
});

bool isRtlLocale(Locale locale) {
  const rtl = {'ar', 'ur', 'fa', 'he'};
  return rtl.contains(locale.languageCode);
}
