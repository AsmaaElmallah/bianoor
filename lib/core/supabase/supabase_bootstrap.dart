import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Optional Supabase init — enabled when dart-defines are set.
///
/// Run: `flutter run --dart-define-from-file=dart_defines.json`
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool _ready = false;

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Same as [isConfigured] for Phase 1 — no separate kill-switch yet.
  static bool get isEnabled => isConfigured;

  static bool get isReady => _ready;

  static SupabaseClient get client {
    if (!_ready) {
      throw StateError('Supabase not initialized — call SupabaseBootstrap.init() first');
    }
    return Supabase.instance.client;
  }

  static Future<void> init() async {
    if (_ready) return;

    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[Supabase] skipped — set SUPABASE_URL + SUPABASE_ANON_KEY '
          '(dart_defines.json)',
        );
      }
      return;
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _ready = true;

    if (kDebugMode) {
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint(
        '[Supabase] initialized — session: ${session != null ? "active" : "none"}',
      );
    }
  }

  /// Lightweight ping — returns false when offline or not configured.
  static Future<bool> healthCheck() async {
    if (!isReady) return false;

    try {
      await client.from('quran_reciters').select('id').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Supabase] healthCheck failed: $e');
      return false;
    }
  }
}
