import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../curriculum/data/progress_sync_service.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'اكتبي إيميلك';
  if (!_emailPattern.hasMatch(v)) return 'الإيميل مش مكتوب صح';
  return null;
}

/// After any successful sign-in: a brand-new account starts onboarding fresh,
/// an existing one pulls its saved progress, then the app moves on.
///
/// Everything is read from [ref] up front — the auth redirect may dispose the
/// calling screen before the awaits finish.
Future<void> finishSignIn(WidgetRef ref) async {
  final router = ref.read(appRouterProvider);
  final prefs = ref.read(prefsServiceProvider);
  final sync = ref.read(progressSyncServiceProvider);

  final createdAt = DateTime.tryParse(
    SupabaseBootstrap.client.auth.currentUser?.createdAt ?? '',
  );
  // abs(): a wrong phone clock must never make an old account look new.
  final isNewAccount = createdAt != null &&
      DateTime.now().toUtc().difference(createdAt.toUtc()).abs() <
          const Duration(minutes: 5);

  if (isNewAccount) {
    await prefs.setOnboardingComplete(false);
    await prefs.setRulesAccepted(false);
    await prefs.setBabyName('');
  } else {
    try {
      await sync.pullAndMerge();
    } catch (_) {}
  }

  final hasBaby = prefs.getBabyName()?.trim().isNotEmpty ?? false;
  router.go(
    prefs.isOnboardingComplete() && hasBaby ? AppRoutes.home : AppRoutes.language,
  );
}
