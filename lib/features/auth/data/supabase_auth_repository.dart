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
        throw AuthFailure('ما قدرناش ندخلك، جربي تاني.');
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
        throw AuthFailure('ما قدرناش نعمل الحساب، جربي تاني.');
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
        throw EmailConfirmationRequired();
      }

      await _prefs.setAuthenticated(true);
      return _userFromSession(session, fallbackName: name.trim());
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
        throw AuthFailure('اتلغى الدخول بجوجل.');
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Auth] Google idToken null — check GOOGLE_WEB_CLIENT_ID and SHA-1');
      }
      throw AuthFailure('الدخول بجوجل مش متاح دلوقتي، ادخلي بالإيميل.');
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
      throw AuthFailure('الدخول بجوجل ما كملش، جربي تاني.');
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
          if (kDebugMode) {
            debugPrint(
              '[Auth] OAuth $label timed out — check provider + redirect $_oauthRedirectTo',
            );
          }
          throw AuthFailure('الدخول بـ$label ما كملش، جربي تاني أو ادخلي بالإيميل.');
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
      throw AuthFailure('ما قدرناش نحذف الحساب دلوقتي، جربي تاني بعد شوية.');
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

  @override
  Future<void> updateDisplayName(String name) async {
    await _ensureReady();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw AuthFailure('اكتبي اسمك الأول.');
    try {
      final res = await _client.auth.updateUser(
        UserAttributes(data: {'display_name': trimmed}),
      );
      final user = res.user;
      if (user == null) throw AuthFailure('تعذّر حفظ الاسم.');
      await _syncDisplayName(user.id, trimmed);
    } catch (e) {
      throw AuthFailure.from(e);
    }
  }

  Future<UserModel?> currentUser() async {
    if (!SupabaseBootstrap.isReady) return null;

    final session = _client.auth.currentSession;
    if (session == null) return null;

    return _userFromSession(session);
  }

  Future<void> _ensureReady() async {
    if (!SupabaseBootstrap.isEnabled) {
      if (kDebugMode) {
        debugPrint('[Auth] Supabase disabled — run with --dart-define-from-file=dart_defines.json');
      }
      throw AuthFailure('الخدمة مش متاحة دلوقتي، جربي تاني بعد شوية.');
    }
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }
    if (!SupabaseBootstrap.isReady) {
      throw AuthFailure('مفيش اتصال بالإنترنت، اتأكدي من النت وجربي تاني.');
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

/// Signup succeeded but Supabase wants the email confirmed before login.
class EmailConfirmationRequired extends AuthFailure {
  EmailConfirmationRequired()
      : super('اتعمل الحساب ✔ افتحي إيميلك وأكدي الحساب، وبعدين سجّلي دخول.');
}

/// User-facing auth errors (Arabic).
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;

  static const _generic = 'حصلت مشكلة في الدخول، جربي تاني بعد شوية.';

  static AuthFailure from(Object error) {
    if (error is AuthFailure) return error;

    if (kDebugMode) debugPrint('[Auth] raw error: $error');

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return AuthFailure(
          'الإيميل أو كلمة السر مش صح.\n'
          'لو أول مرة تستخدمي التطبيق، اعملي حساب جديد.',
        );
      }
      if (msg.contains('user already registered') ||
          msg.contains('already been registered')) {
        return AuthFailure('الإيميل ده عنده حساب بالفعل، سجّلي دخول.');
      }
      if (msg.contains('email not confirmed')) {
        return AuthFailure('أكدي إيميلك الأول من الرسالة اللي وصلتلك، وبعدين سجّلي دخول.');
      }
      if (msg.contains('rate limit') || msg.contains('for security purposes')) {
        return AuthFailure('محاولات كتير ورا بعض، استني دقيقة وجربي تاني.');
      }
      if (msg.contains('should be different')) {
        return AuthFailure('اختاري كلمة سر جديدة غير القديمة.');
      }
      if (msg.contains('password') &&
          (msg.contains('at least') || msg.contains('weak') || msg.contains('short'))) {
        return AuthFailure('كلمة السر ضعيفة، خليها 6 حروف أو أرقام على الأقل.');
      }
      return AuthFailure(_generic);
    }

    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('timeout')) {
      return AuthFailure('مفيش إنترنت أو النت ضعيف، اتأكدي من الاتصال وجربي تاني.');
    }
    return AuthFailure(_generic);
  }
}
