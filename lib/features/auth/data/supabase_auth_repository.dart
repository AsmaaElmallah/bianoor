import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._prefs);

  final PrefsService _prefs;

  /// Deep link scheme for mobile OAuth return (must match Android/iOS config).
  static const oauthRedirectScheme = 'io.supabase.bayanour';
  static const oauthRedirectHost = 'login-callback';

  /// Same Web Client ID used in Supabase → Auth → Google provider.
  static const _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool _googleInitialized = false;

  SupabaseClient get _client => SupabaseBootstrap.client;

  String get _oauthRedirectTo {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return '$oauthRedirectScheme://$oauthRedirectHost/';
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized || _googleWebClientId.isEmpty) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleWebClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await _ensureReady();
    if (kDebugMode) {
      debugPrint('[Auth] email login → ${email.trim()}');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final session = response.session;
      if (session == null) {
        throw AuthFailure('تعذّر تسجيل الدخول — حاولي مرة أخرى.');
      }

      await _prefs.setAuthenticated(true);
      if (kDebugMode) {
        debugPrint('[Auth] email login OK uid=${session.user.id}');
      }
      return _userFromSession(session);
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] email login failed: $e');
      throw AuthFailure.from(e);
    }
  }

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureReady();
    if (kDebugMode) {
      debugPrint('[Auth] email signup → ${email.trim()}');
    }

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': name.trim()},
      );

      final user = response.user;
      if (user == null) {
        throw AuthFailure('تعذّر إنشاء الحساب.');
      }

      if (kDebugMode) {
        debugPrint(
          '[Auth] signup OK uid=${user.id} '
          'session=${response.session != null} '
          'confirmed=${user.emailConfirmedAt != null}',
        );
      }

      await _syncDisplayName(user.id, name.trim());

      final session = response.session;
      if (session == null) {
        throw AuthFailure(
          'تم إنشاء الحساب — راجعي بريدك لتأكيد الحساب ثم سجّلي الدخول.',
        );
      }

      // End session immediately so the app lands on Login (not onboarding).
      await _client.auth.signOut();
      await _prefs.setAuthenticated(false);

      if (kDebugMode) {
        debugPrint('[Auth] signup OK — signed out, waiting for login');
      }

      return UserModel(
        id: user.id,
        email: user.email ?? email.trim(),
        name: name.trim().isEmpty ? null : name.trim(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] email signup failed: $e');
      throw AuthFailure.from(e);
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await _ensureReady();

    // Native Google (Android/iOS) is more reliable than browser OAuth.
    if (!kIsWeb && _googleWebClientId.isNotEmpty) {
      try {
        return await _googleNativeSignIn();
      } on AuthFailure {
        rethrow;
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[Auth] native Google failed, trying OAuth: $e\n$st');
        }
      }
    } else if (!kIsWeb && kDebugMode && _googleWebClientId.isEmpty) {
      debugPrint(
        '[Auth] GOOGLE_WEB_CLIENT_ID missing — using browser OAuth. '
        'Add it to dart_defines.json for native Google Sign-In.',
      );
    }

    return _signInWithOAuth(OAuthProvider.google, label: 'جوجل');
  }

  @override
  Future<UserModel> loginWithApple() =>
      _signInWithOAuth(OAuthProvider.apple, label: 'أبل');

  @override
  Future<UserModel> loginWithFacebook() =>
      _signInWithOAuth(OAuthProvider.facebook, label: 'فيسبوك');

  Future<UserModel> _googleNativeSignIn() async {
    if (kDebugMode) debugPrint('[Auth] Google native sign-in (v7)…');

    await _ensureGoogleInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('authenticate unsupported — use OAuth fallback');
    }

    // Clear stale account so the picker shows.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure('تم إلغاء تسجيل الدخول بجوجل.');
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthFailure(
        'تعذّر الحصول على رمز جوجل — تأكدي من GOOGLE_WEB_CLIENT_ID وSHA-1 في Google Cloud.',
      );
    }

    String? accessToken;
    try {
      final authz = await account.authorizationClient.authorizeScopes(
        const ['email', 'profile'],
      );
      accessToken = authz.accessToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Auth] Google accessToken optional failed: $e');
      }
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final session = response.session;
    if (session == null) {
      throw AuthFailure('تعذّر إكمال تسجيل جوجل مع السحابة.');
    }

    await _prefs.setAuthenticated(true);
    if (kDebugMode) {
      debugPrint('[Auth] Google native OK uid=${session.user.id}');
    }
    return _userFromSession(session);
  }

  Future<UserModel> _signInWithOAuth(
    OAuthProvider provider, {
    required String label,
  }) async {
    await _ensureReady();
    if (kDebugMode) {
      debugPrint(
        '[Auth] OAuth $label → redirectTo=$_oauthRedirectTo',
      );
    }

    final existing = _client.auth.currentSession;
    if (existing != null) {
      await _prefs.setAuthenticated(true);
      return _userFromSession(existing);
    }

    final completer = Completer<UserModel>();
    late final StreamSubscription<AuthState> sub;
    sub = _client.auth.onAuthStateChange.listen((data) async {
      if (kDebugMode) {
        debugPrint(
          '[Auth] onAuthStateChange event=${data.event} '
          'hasSession=${data.session != null}',
        );
      }
      final session = data.session;
      if (session == null || completer.isCompleted) return;
      if (data.event != AuthChangeEvent.signedIn &&
          data.event != AuthChangeEvent.tokenRefreshed &&
          data.event != AuthChangeEvent.userUpdated) {
        return;
      }
      try {
        await _prefs.setAuthenticated(true);
        completer.complete(await _userFromSession(session));
      } catch (e, st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      } finally {
        await sub.cancel();
      }
    });

    try {
      final launched = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: _oauthRedirectTo,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        queryParams: provider == OAuthProvider.google
            ? const {
                'access_type': 'offline',
                'prompt': 'select_account',
              }
            : null,
      );

      if (!launched) {
        await sub.cancel();
        throw AuthFailure('تعذّر فتح تسجيل الدخول عبر $label.');
      }

      return await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          sub.cancel();
          throw AuthFailure(
            'انتهت مهلة تسجيل $label.\n'
            '• فعّلي المزوّد في Supabase → Authentication → Providers\n'
            '• أضيفي redirect: $_oauthRedirectTo\n'
            '• شغّلي التطبيق بـ --dart-define-from-file=dart_defines.json',
          );
        },
      );
    } on AuthFailure {
      await sub.cancel();
      rethrow;
    } catch (e) {
      await sub.cancel();
      throw AuthFailure.from(e);
    }
  }

  @override
  Future<void> logout() async {
    if (!SupabaseBootstrap.isReady) {
      await _prefs.setAuthenticated(false);
      return;
    }

    try {
      if (!kIsWeb && _googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}

    await _client.auth.signOut();
    await _prefs.setAuthenticated(false);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _ensureReady();
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _oauthRedirectTo,
      );
      if (kDebugMode) {
        debugPrint(
          '[Auth] reset password email sent → ${email.trim()} '
          'redirectTo=$_oauthRedirectTo',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] reset password failed: $e');
      throw AuthFailure.from(e);
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _ensureReady();
    try {
      final res = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (res.user == null) {
        throw AuthFailure('تعذّر تحديث كلمة المرور.');
      }
      await _prefs.setPasswordRecoveryPending(false);
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _ensureReady();
    try {
      await _client.rpc('delete_own_account');
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] delete_own_account failed: $e');
      throw AuthFailure(
        'تعذّر حذف الحساب. تأكدي من تطبيق migration حذف الحساب على Supabase.',
      );
    }

    try {
      if (!kIsWeb && _googleInitialized) {
        await GoogleSignIn.instance.disconnect();
      }
    } catch (_) {}

    await _prefs.setAuthenticated(false);
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<UserModel?> currentUser() async {
    if (!SupabaseBootstrap.isReady) return null;

    final session = _client.auth.currentSession;
    if (session == null) return null;

    return _userFromSession(session);
  }

  Future<void> _ensureReady() async {
    if (!SupabaseBootstrap.isEnabled) {
      throw AuthFailure(
        'Supabase غير مفعّل. شغّلي:\n'
        'flutter run --dart-define-from-file=dart_defines.json',
      );
    }
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }
    if (!SupabaseBootstrap.isReady) {
      throw AuthFailure('تعذّر تهيئة الاتصال بالسحابة.');
    }
  }

  Future<void> _syncDisplayName(String userId, String name) async {
    if (name.isEmpty) return;

    try {
      await _client.from('profiles').update({'display_name': name}).eq('id', userId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Auth] profile display_name sync failed: $e\n$st');
      }
    }
  }

  Future<UserModel> _userFromSession(
    Session session, {
    String? fallbackName,
  }) async {
    final user = session.user;
    var name = fallbackName ??
        user.userMetadata?['display_name'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String?;

    if (name == null || name.trim().isEmpty) {
      try {
        final row = await _client
            .from('profiles')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();
        name = row?['display_name'] as String?;
      } catch (_) {}
    }

    final avatar = user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?;

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: name?.trim().isNotEmpty == true ? name!.trim() : null,
      photoUrl: avatar,
    );
  }
}

/// User-facing auth errors (Arabic).
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;

  static AuthFailure from(Object error) {
    if (error is AuthFailure) return error;

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return AuthFailure(
          'البريد أو كلمة المرور غير صحيحة.\n'
          'لو أول مرة: اضغطي «إنشاء حساب» مش تسجيل الدخول.',
        );
      }
      if (msg.contains('user already registered')) {
        return AuthFailure('هذا البريد مسجّل مسبقاً — جرّبي تسجيل الدخول.');
      }
      if (msg.contains('password')) {
        return AuthFailure('كلمة المرور ضعيفة — استخدمي 6 أحرف على الأقل.');
      }
      if (msg.contains('email not confirmed')) {
        return AuthFailure('يرجى تأكيد البريد الإلكتروني أولاً.');
      }
      if (msg.contains('rate limit') || msg.contains('for security purposes')) {
        return AuthFailure(
          'تم إرسال طلبات كثيرة — انتظري دقيقة ثم أعيدي المحاولة.',
        );
      }
      if (msg.contains('redirect') || msg.contains('unable to validate')) {
        return AuthFailure(
          'رابط العودة غير مسموح في Supabase.\n'
          'أضيفي في Redirect URLs:\n'
          'io.supabase.bayanour://login-callback/',
        );
      }
      if (msg.contains('provider is not enabled') ||
          msg.contains('unsupported provider') ||
          msg.contains('validation_failed')) {
        return AuthFailure(
          'مزوّد الدخول غير مفعّل أو غير مضبوط في Supabase — راجعي Authentication → Providers.',
        );
      }
      return AuthFailure(error.message);
    }

    return AuthFailure('حدث خطأ — حاولي لاحقاً.');
  }
}
