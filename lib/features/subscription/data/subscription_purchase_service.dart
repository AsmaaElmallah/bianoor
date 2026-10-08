import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/subscription_plan_model.dart';
import 'subscription_cloud_repository.dart';

final subscriptionPurchaseServiceProvider =
    Provider<SubscriptionPurchaseService>((ref) {
  final service = SubscriptionPurchaseService(
    ref.watch(subscriptionCloudRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

enum PurchaseOutcome { success, cancelled, unavailable, failed }

class PurchaseResult {
  const PurchaseResult(this.outcome, {this.message});
  final PurchaseOutcome outcome;
  final String? message;
}

/// Tries store IAP first; falls back to sandbox activate (+ Edge verify).
class SubscriptionPurchaseService {
  SubscriptionPurchaseService(this._cloud);

  final SubscriptionCloudRepository _cloud;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PurchaseResult>? _pending;
  bool get _isMobileStore =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _platformLabel {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'sandbox';
  }

  Future<void> ensureListening() async {
    if (_sub != null) return;
    if (!_isMobileStore) return;
    _sub = _iap.purchaseStream.listen(_onPurchases);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    await ensureListening();

    if (!_isMobileStore || !await _iap.isAvailable()) {
      return _sandboxActivate(plan, reason: 'store_unavailable');
    }

    final productId = defaultTargetPlatform == TargetPlatform.iOS
        ? (plan.storeProductIdIos ?? '')
        : (plan.storeProductIdAndroid ?? '');

    if (productId.isEmpty) {
      return _sandboxActivate(plan, reason: 'missing_product_id');
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[IAP] product $productId not found — sandbox fallback. '
          'errors=${response.error}',
        );
      }
      return _sandboxActivate(plan, reason: 'product_not_found');
    }

    final product = response.productDetails.first;
    _pending = Completer<PurchaseResult>();

    final ok = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!ok) {
      _pending = null;
      return const PurchaseResult(
        PurchaseOutcome.failed,
        message: 'تعذّر بدء الشراء',
      );
    }

    return _pending!.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        _pending = null;
        return const PurchaseResult(
          PurchaseOutcome.failed,
          message: 'انتهت مهلة الشراء',
        );
      },
    );
  }

  Future<PurchaseResult> restore() async {
    await ensureListening();
    if (_isMobileStore && await _iap.isAvailable()) {
      await _iap.restorePurchases();
    }
    final sub = await _cloud.restorePurchases();
    return PurchaseResult(
      sub?.isActive == true
          ? PurchaseOutcome.success
          : PurchaseOutcome.failed,
      message: sub?.isActive == true ? null : 'لا اشتراك نشط لاستعادته',
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      // Course products share the same purchase stream; CoursePurchaseService owns them.
      final planForProduct = await _planIdForProduct(purchase.productID);
      if (planForProduct == null) continue;

      if (purchase.status == PurchaseStatus.error) {
        _completePending(
          PurchaseResult(
            PurchaseOutcome.failed,
            message: purchase.error?.message ?? 'فشل الشراء',
          ),
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        _completePending(const PurchaseResult(PurchaseOutcome.cancelled));
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final planId = planForProduct;
        final verified = await _verifyViaEdgeOrLocal(
          planId: planId,
          productId: purchase.productID,
          purchaseId: purchase.purchaseID,
          receipt: purchase.verificationData.serverVerificationData,
          platform: _platformLabel,
        );
        _completePending(
          verified
              ? const PurchaseResult(PurchaseOutcome.success)
              : const PurchaseResult(
                  PurchaseOutcome.failed,
                  message: 'فشل التحقق من الإيصال',
                ),
        );
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _completePending(PurchaseResult result) {
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete(result);
    }
    _pending = null;
  }

  Future<String?> _planIdForProduct(String productId) async {
    final plans = await _cloud.fetchActivePlans();
    for (final p in plans) {
      if (p.storeProductIdIos == productId ||
          p.storeProductIdAndroid == productId) {
        return p.id;
      }
    }
    return null;
  }

  Future<PurchaseResult> _sandboxActivate(
    SubscriptionPlan plan, {
    required String reason,
  }) async {
    // Never grant paid access without the store in release builds.
    if (!subscriptionSandboxAllowed) {
      debugPrint('[IAP] sandbox blocked in release reason=$reason');
      return PurchaseResult(
        PurchaseOutcome.unavailable,
        message: reason == 'missing_product_id'
            ? 'منتج الاشتراك غير مضبوط بعد'
            : 'المتجر غير متاح حاليًا — جرّبي لاحقًا',
      );
    }
    debugPrint('[IAP] sandbox activate plan=${plan.id} reason=$reason');

    // Edge Function often not deployed yet — activate locally in debug first.
    final localOk = await _cloud.activatePlan(plan.id);
    if (localOk) {
      return const PurchaseResult(PurchaseOutcome.success);
    }

    final edgeOk = await _verifyViaEdgeOrLocal(
      planId: plan.id,
      productId: plan.storeProductIdAndroid ?? plan.storeProductIdIos,
      platform: 'sandbox',
      mode: 'sandbox',
      allowClientActivate: false,
    );
    if (edgeOk) {
      return const PurchaseResult(PurchaseOutcome.success);
    }

    return const PurchaseResult(
      PurchaseOutcome.failed,
      message:
          'تعذّر تفعيل الاشتراك.\nتأكدي أن جدول الاشتراكات و سياساته مطبّقة على Supabase.',
    );
  }

  Future<bool> _verifyViaEdgeOrLocal({
    required String planId,
    String? productId,
    String? purchaseId,
    String? receipt,
    String platform = 'sandbox',
    String mode = 'store',
    bool allowClientActivate = false,
  }) async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    if (!SupabaseBootstrap.isReady) return false;

    try {
      final res = await SupabaseBootstrap.client.functions.invoke(
        'verify-subscription',
        body: {
          'plan_id': planId,
          'product_id': productId,
          'purchase_id': purchaseId,
          'receipt': receipt,
          'platform': platform,
          'mode': mode,
        },
      );
      if (res.status >= 200 && res.status < 300) return true;
      if (kDebugMode) {
        debugPrint('[IAP] edge verify status=${res.status} data=${res.data}');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[IAP] edge verify failed: $e\n$st');
    }

    // Client-side activate is debug-only safety net.
    if (allowClientActivate && kDebugMode) {
      return _cloud.activatePlan(planId);
    }
    return false;
  }
}
