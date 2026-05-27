import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// تهيئة عميل Supabase (اختياري — بدون مفاتيح يعمل التطبيق محلياً فقط).
abstract final class SupabaseBootstrap {
  static bool _initialized = false;

  static bool get isEnabled => SupabaseConfig.isConfigured;

  static bool get isReady => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase غير مُهيّأ — أضيفي SUPABASE_URL و SUPABASE_ANON_KEY');
    }
    return Supabase.instance.client;
  }

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured || _initialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }
}
