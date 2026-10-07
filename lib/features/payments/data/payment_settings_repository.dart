import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class PaymentSettings {
  const PaymentSettings({
    this.manualEnabled = false,
    this.manualInstructions = '',
    this.paypalEnabled = false,
    this.whatsappNumber = '',
  });

  final bool manualEnabled;
  final String manualInstructions;
  final bool paypalEnabled;

  /// International digits only, or empty when not set.
  final String whatsappNumber;

  bool get canPayManually => manualEnabled && whatsappNumber.isNotEmpty;
}

final paymentSettingsProvider = FutureProvider<PaymentSettings>((ref) async {
  if (!SupabaseBootstrap.isEnabled) return const PaymentSettings();
  if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
  if (!SupabaseBootstrap.isReady) return const PaymentSettings();
  try {
    final rows = await SupabaseBootstrap.client.from('app_settings').select('key, value').inFilter('key', [
      'payment_manual_enabled',
      'payment_manual_instructions',
      'payment_paypal_enabled',
      'library_whatsapp',
    ]);
    final values = {
      for (final row in List<Map<String, dynamic>>.from(rows as List))
        row['key'] as String: (row['value'] as String?) ?? '',
    };
    return PaymentSettings(
      manualEnabled: values['payment_manual_enabled'] == 'true',
      manualInstructions: values['payment_manual_instructions']?.trim() ?? '',
      paypalEnabled: values['payment_paypal_enabled'] == 'true',
      whatsappNumber: (values['library_whatsapp'] ?? '').replaceAll(RegExp(r'\D'), ''),
    );
  } catch (e) {
    if (kDebugMode) debugPrint('[Payments] settings fetch failed: $e');
    return const PaymentSettings();
  }
});
