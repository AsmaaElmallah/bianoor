import '../../../core/storage/prefs_service.dart';
import '../domain/user_model.dart';

/// Auth interface. Swap the mock impl for Firebase/Supabase later by
/// replacing the provider's implementation only — UI stays untouched.
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
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs);

  final PrefsService _prefs;

  Future<UserModel> _delayedReturn(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 700));
    await _prefs.setAuthenticated(true);
    return user;
  }

  @override
  Future<UserModel> login({required String email, required String password}) {
    return _delayedReturn(
      UserModel(id: 'mock-${email.hashCode}', email: email),
    );
  }

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) {
    return _delayedReturn(
      UserModel(id: 'mock-${email.hashCode}', email: email, name: name),
    );
  }

  @override
  Future<UserModel> loginWithGoogle() {
    return _delayedReturn(
      const UserModel(
        id: 'google-mock',
        email: 'google@bayanour.app',
        name: 'Google User',
      ),
    );
  }

  @override
  Future<UserModel> loginWithApple() {
    return _delayedReturn(
      const UserModel(
        id: 'apple-mock',
        email: 'apple@bayanour.app',
        name: 'Apple User',
      ),
    );
  }

  @override
  Future<UserModel> loginWithFacebook() {
    return _delayedReturn(
      const UserModel(
        id: 'fb-mock',
        email: 'fb@bayanour.app',
        name: 'Facebook User',
      ),
    );
  }

  @override
  Future<void> logout() async {
    await _prefs.setAuthenticated(false);
  }
}
