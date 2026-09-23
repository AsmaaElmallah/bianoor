import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../curriculum/data/progress_sync_service.dart';
import '../../notifications/data/notifications_cloud_repository.dart';
import '../domain/user_model.dart';

/// True while the user opened the app from a password-recovery deep link.
final passwordRecoveryPendingProvider = StateProvider<bool>((ref) {
  return ref.read(prefsServiceProvider).isPasswordRecoveryPending();
});

/// Current signed-in user — Supabase stream or local mock fallback.
final authSessionProvider = StreamProvider<UserModel?>((ref) {
  final prefs = ref.watch(prefsServiceProvider);

  if (!SupabaseBootstrap.isEnabled) {
    // No fake logged-in user — force real cloud auth via dart_defines.
    return Stream.value(null);
  }

  final controller = StreamController<UserModel?>();

  Future<void> markRecovery(bool pending) async {
    await prefs.setPasswordRecoveryPending(pending);
    ref.read(passwordRecoveryPendingProvider.notifier).state = pending;
  }

  Future<void> bootstrap() async {
    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }

    if (!SupabaseBootstrap.isReady) {
      controller.add(null);
      return;
    }

    final client = SupabaseBootstrap.client;

    Future<void> emit(
      Session? session, {
      bool fromRecovery = false,
    }) async {
      if (session == null) {
        await prefs.setAuthenticated(false);
        await markRecovery(false);
        controller.add(null);
        return;
      }

      if (fromRecovery) {
        await markRecovery(true);
      }

      final recovery = prefs.isPasswordRecoveryPending();

      // Don't sync onboarding/progress during password reset.
      if (!recovery) {
        try {
          await ref.read(progressSyncServiceProvider).pullAndMerge();
        } catch (_) {}
      }

      await prefs.setAuthenticated(true);
      controller.add(await _mapUser(client, session));

      if (recovery) return;

      try {
        final token =
            'local:${session.user.id}:${DateTime.now().millisecondsSinceEpoch ~/ 86400000}';
        await ref.read(notificationsCloudRepositoryProvider).upsertDeviceToken(
              token: token,
              platform: defaultTargetPlatform.name,
            );
      } catch (_) {}
    }

    await emit(client.auth.currentSession);

    final sub = client.auth.onAuthStateChange.listen((data) async {
      if (kDebugMode) {
        debugPrint(
          '[Auth] onAuthStateChange event=${data.event} '
          'hasSession=${data.session != null}',
        );
      }
      final isRecovery = data.event == AuthChangeEvent.passwordRecovery;
      await emit(data.session, fromRecovery: isRecovery);
    });

    ref.onDispose(() {
      sub.cancel();
      controller.close();
    });
  }

  unawaited(bootstrap().catchError((Object e, StackTrace st) {
    controller.addError(e, st);
  }));

  return controller.stream;
});

Future<UserModel> _mapUser(SupabaseClient client, Session session) async {
  final user = session.user;
  var name = user.userMetadata?['display_name'] as String?;

  if (name == null || name.trim().isEmpty) {
    try {
      final row = await client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      name = row?['display_name'] as String?;
    } catch (_) {}
  }

  return UserModel(
    id: user.id,
    email: user.email ?? '',
    name: name?.trim().isNotEmpty == true ? name!.trim() : null,
    photoUrl: user.userMetadata?['avatar_url'] as String?,
  );
}

/// Notifier for go_router refresh on auth changes.
final authRefreshListenableProvider = Provider<AuthRefreshListenable>((ref) {
  final listenable = AuthRefreshListenable();
  ref.listen(authSessionProvider, (_, __) => listenable.refresh());
  ref.listen(passwordRecoveryPendingProvider, (_, __) => listenable.refresh());
  ref.onDispose(listenable.dispose);
  return listenable;
});

class AuthRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
