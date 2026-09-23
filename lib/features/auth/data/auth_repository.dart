import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/user_model.dart';
import 'supabase_auth_repository.dart';

/// Auth interface — UI depends on this only.
abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithApple();
  Future<UserModel> loginWithFacebook();
  Future<void> logout();
  Future<void> resetPassword({required String email});
  Future<void> updatePassword({required String newPassword});
  Future<void> deleteAccount();
}

/// Used only when dart_defines are missing — never fakes a successful login.
class DisabledAuthRepository implements AuthRepository {
  static const _msg =
      'السحابة غير مفعّلة.\nشغّلي من مجلد bayanour:\n.\\run.ps1\nأو:\nflutter run --dart-define-from-file=dart_defines.json';

  Future<UserModel> _blocked() async {
    throw AuthFailure(_msg);
  }

  @override
  Future<UserModel> login({required String email, required String password}) =>
      _blocked();

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) =>
      _blocked();

  @override
  Future<UserModel> loginWithGoogle() => _blocked();

  @override
  Future<UserModel> loginWithApple() => _blocked();

  @override
  Future<UserModel> loginWithFacebook() => _blocked();

  @override
  Future<void> logout() async {}

  @override
  Future<void> resetPassword({required String email}) async {
    throw AuthFailure(_msg);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    throw AuthFailure(_msg);
  }

  @override
  Future<void> deleteAccount() async {
    throw AuthFailure(_msg);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.read(prefsServiceProvider);
  if (SupabaseBootstrap.isEnabled) {
    return SupabaseAuthRepository(prefs);
  }
  return DisabledAuthRepository();
});
