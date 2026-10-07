import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/payment_item.dart';

final paypalCheckoutServiceProvider = Provider<PaypalCheckoutService>((ref) {
  return const PaypalCheckoutService();
});

class PaypalOrder {
  const PaypalOrder({required this.id, required this.approveUrl});
  final String id;
  final Uri approveUrl;
}

class PaypalException implements Exception {
  const PaypalException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PaypalCheckoutService {
  const PaypalCheckoutService();

  Future<void> _ensureReady() async {
    if (!SupabaseBootstrap.isEnabled) throw const PaypalException('الخدمة غير متاحة حالياً');
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    if (SupabaseBootstrap.client.auth.currentUser == null) {
      throw const PaypalException('سجّلي دخولك الأول علشان تقدري تدفعي');
    }
  }

  Future<PaypalOrder> createOrder(PaymentItem item) async {
    await _ensureReady();
    try {
      final res = await SupabaseBootstrap.client.functions.invoke(
        'paypal-checkout',
        body: {'action': 'create', 'kind': item.kind.name, 'item_id': item.id},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return PaypalOrder(
        id: data['order_id'] as String,
        approveUrl: Uri.parse(data['approve_url'] as String),
      );
    } on FunctionException catch (e) {
      if (kDebugMode) debugPrint('[PayPal] create failed: ${e.status} ${e.details}');
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      throw PaypalException(switch (code) {
        'paypal_disabled' => 'الدفع بـ PayPal متوقف حالياً',
        'no_price' => 'السعر بالدولار مش مضبوط لسه، جرّبي طريقة دفع تانية',
        _ => 'تعذّر بدء الدفع، حاولي تاني',
      });
    }
  }

  /// True once PayPal confirmed the payment and access was granted.
  Future<bool> confirm(String orderId) async {
    await _ensureReady();
    try {
      final res = await SupabaseBootstrap.client.functions.invoke(
        'paypal-checkout',
        body: {'action': 'capture', 'order_id': orderId},
      );
      return (res.data as Map?)?['ok'] == true;
    } on FunctionException catch (e) {
      if (kDebugMode) debugPrint('[PayPal] capture: ${e.status} ${e.details}');
      return false;
    }
  }
}
