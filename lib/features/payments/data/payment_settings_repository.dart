import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class PaymentSettings {
  const PaymentSettings({this.paypalEnabled = false});

  final bool paypalEnabled;
}

final paymentSettingsProvider = FutureProvider<PaymentSettings>((ref) async {
  if (!SupabaseBootstrap.isEnabled) return const PaymentSettings();
  if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
  if (!SupabaseBootstrap.isReady) return const PaymentSettings();
  try {
    final row = await SupabaseBootstrap.client
        .from('app_settings')
        .select('value')
        .eq('key', 'payment_paypal_enabled')
        .maybeSingle();
    return PaymentSettings(paypalEnabled: row?['value'] == 'true');
  } catch (e) {
    if (kDebugMode) debugPrint('[Payments] settings fetch failed: $e');
    return const PaymentSettings();
  }
});
