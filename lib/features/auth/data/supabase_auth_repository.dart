import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/sync/user_progress_sync_service.dart';
import '../domain/auth_exception.dart' show BayanourAuthException;
import '../domain/user_model.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._prefs, this._progressSync);

  final PrefsService _prefs;
  final UserProgressSyncService _progressSync;

  SupabaseClient get _client {
    if (!SupabaseBootstrap.isReady) {
      throw const BayanourAuthException('Supabase غير مُهيّأ');
    }
    return SupabaseBootstrap.client;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const BayanourAuthException('تعذر تسجيل الدخول');
      }
      return _finishAuth(user);
    } on BayanourAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw BayanourAuthException(_mapAuthError(e));
    } catch (e) {
      throw BayanourAuthException('تعذر تسجيل الدخول: $e');
    }
  }

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': name.trim()},
      );
      final user = response.user;
      if (user == null) {
        throw const BayanourAuthException('تعذر إنشاء الحساب');
      }
      if (response.session == null) {
        throw const BayanourAuthException(
          'تم إنشاء الحساب. افتحي بريدكِ لتأكيد البريد ثم سجّلي الدخول.',
        );
      }
      return _finishAuth(user);
    } on BayanourAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw BayanourAuthException(_mapAuthError(e));
    } catch (e) {
      throw BayanourAuthException('تعذر إنشاء الحساب: $e');
    }
  }

  @override
  Future<UserModel> loginWithGoogle() {
    throw const BayanourAuthException('تسجيل Google قريباً — استخدمي البريد وكلمة المرور');
  }

  @override
  Future<UserModel> loginWithApple() {
    throw const BayanourAuthException('تسجيل Apple قريباً — استخدمي البريد وكلمة المرور');
  }

  @override
  Future<UserModel> loginWithFacebook() {
    throw const BayanourAuthException('تسجيل Facebook قريباً — استخدمي البريد وكلمة المرور');
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    await _prefs.setAuthenticated(false);
  }

  Future<UserModel> _finishAuth(User user) async {
    await _prefs.setAuthenticated(true);
    final model = _userFromSupabase(user);
    await _progressSync.pullToDevice(user.id);
    return model;
  }

  UserModel _userFromSupabase(User user) {
    final meta = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: meta['display_name'] as String? ?? meta['name'] as String?,
      photoUrl: meta['avatar_url'] as String?,
    );
  }

  String _mapAuthError(AuthApiException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'هذا البريد مسجّل مسبقاً';
    }
    if (msg.contains('password')) {
      return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
    }
    return e.message;
  }
}
