import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/sync/user_progress_remote_data_source.dart';
import '../../../core/sync/user_progress_sync_service.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/user_model.dart';

class AuthSessionState {
  const AuthSessionState({
    this.user,
    this.isLoading = false,
  });

  final UserModel? user;
  final bool isLoading;

  bool get isLoggedIn => user != null;
}

final userProgressSyncProvider = Provider<UserProgressSyncService>((ref) {
  return UserProgressSyncService(
    ref.watch(prefsServiceProvider),
    const UserProgressRemoteDataSource(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(prefsServiceProvider);
  if (SupabaseBootstrap.isEnabled) {
    return SupabaseAuthRepository(
      prefs,
      ref.watch(userProgressSyncProvider),
    );
  }
  return MockAuthRepository(prefs);
});

final authSessionProvider = StreamProvider<AuthSessionState>((ref) async* {
  if (!SupabaseBootstrap.isEnabled) {
    final prefs = ref.watch(prefsServiceProvider);
    if (prefs.isAuthenticated()) {
      yield const AuthSessionState(
        user: UserModel(id: 'local', email: 'local@bayanour.app'),
      );
    } else {
      yield const AuthSessionState();
    }
    return;
  }

  if (!SupabaseBootstrap.isReady) {
    await SupabaseBootstrap.init();
  }

  final sync = ref.read(userProgressSyncProvider);

  yield* Supabase.instance.client.auth.onAuthStateChange.asyncMap((event) async {
    final session = event.session;
    if (session?.user == null) {
      await ref.read(prefsServiceProvider).setAuthenticated(false);
      return const AuthSessionState();
    }

    final user = session!.user;
    await ref.read(prefsServiceProvider).setAuthenticated(true);

    if (event.event == AuthChangeEvent.signedIn ||
        event.event == AuthChangeEvent.tokenRefreshed) {
      await sync.pullToDevice(user.id);
    }

    final meta = user.userMetadata ?? {};
    return AuthSessionState(
      user: UserModel(
        id: user.id,
        email: user.email ?? '',
        name: meta['display_name'] as String? ?? meta['name'] as String?,
        photoUrl: meta['avatar_url'] as String?,
      ),
    );
  });
});

/// يستمع له GoRouter لإعادة التوجيه عند تغيّر الجلسة.
final authRefreshListenableProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authSessionProvider, (_, __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});
