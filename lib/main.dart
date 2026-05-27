import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/prefs_service.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/config/supabase_config.dart';
import 'core/sync/user_progress_remote_data_source.dart';
import 'core/sync/user_progress_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseBootstrap.init();

  if (SupabaseConfig.isConfigured && SupabaseBootstrap.isReady) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final sync = UserProgressSyncService(
        PrefsService(prefs),
        const UserProgressRemoteDataSource(),
      );
      await sync.pullToDevice(user.id);
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final prefsService = PrefsService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefsService),
      ],
      child: const BayanourApp(),
    ),
  );
}
