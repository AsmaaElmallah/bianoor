import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/course.dart';

final coursePurchaseServiceProvider = Provider<CoursePurchaseService>((ref) {
  final service = CoursePurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Localized store price (e.g. "EGP 199.00"), or null when the store product isn't available.
final courseStorePriceProvider = FutureProvider.family<String?, Course>((ref, course) {
  return ref.watch(coursePurchaseServiceProvider).storePrice(course);
});

enum CoursePurchaseOutcome { success, cancelled, unavailable, failed }

class CoursePurchaseResult {
  const CoursePurchaseResult(this.outcome, {this.message});
  final CoursePurchaseOutcome outcome;
  final String? message;
}

/// Buys a paid course as a one-time store product, then unlocks it via the
/// `verify-course-purchase` Edge Function (which checks the receipt with Google).
class CoursePurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<CoursePurchaseResult>? _pending;
  Course? _pendingCourse;

  bool get _isMobileStore =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  String? productIdFor(Course course) => defaultTargetPlatform == TargetPlatform.iOS
      ? course.storeProductIdIos
      : course.storeProductIdAndroid;

  void _ensureListening() {
    if (_sub != null || !_isMobileStore) return;
    _sub = _iap.purchaseStream.listen(_onPurchases);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<ProductDetails?> _product(Course course) async {
    final productId = productIdFor(course);
    if (!_isMobileStore || productId == null || !await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      if (kDebugMode) debugPrint('[CourseIAP] product $productId not found: ${response.error}');
      return null;
    }
    return response.productDetails.first;
  }

  Future<String?> storePrice(Course course) async {
    try {
      return (await _product(course))?.price;
    } catch (_) {
      return null;
    }
  }

  Future<CoursePurchaseResult> buy(Course course) async {
    if (_pending != null) {
      return const CoursePurchaseResult(CoursePurchaseOutcome.failed, message: 'فيه عملية شراء شغالة بالفعل');
    }
    _ensureListening();
    final product = await _product(course);
    if (product == null) {
      return const CoursePurchaseResult(
        CoursePurchaseOutcome.unavailable,
        message: 'الشراء من المتجر مش متاح للدورة دي حالياً',
      );
    }

    _pendingCourse = course;
    final completer = Completer<CoursePurchaseResult>();
    _pending = completer;

    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      _finish(const CoursePurchaseResult(CoursePurchaseOutcome.failed, message: 'تعذّر بدء الشراء'));
    }

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        _pending = null;
        _pendingCourse = null;
        return const CoursePurchaseResult(CoursePurchaseOutcome.failed, message: 'انتهت مهلة الشراء');
      },
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final course = await _courseForProduct(purchase.productID);
      if (course == null) continue;
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        _finish(CoursePurchaseResult(
          CoursePurchaseOutcome.failed,
          message: purchase.error?.message ?? 'فشل الشراء',
        ));
      } else if (purchase.status == PurchaseStatus.canceled) {
        _finish(const CoursePurchaseResult(CoursePurchaseOutcome.cancelled));
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final error = await _verify(course, purchase);
        if (error == null) {
          if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
          _finish(const CoursePurchaseResult(CoursePurchaseOutcome.success));
        } else {
          _finish(CoursePurchaseResult(CoursePurchaseOutcome.failed, message: error));
        }
        continue;
      }

      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
    }
  }

  Future<Course?> _courseForProduct(String productId) async {
    final pending = _pendingCourse;
    if (pending != null && productIdFor(pending) == productId) return pending;
    if (!SupabaseBootstrap.isReady) return null;
    final column = _platform == 'ios' ? 'store_product_id_ios' : 'store_product_id_android';
    try {
      final row = await SupabaseBootstrap.client
          .from('courses')
          .select()
          .eq(column, productId)
          .maybeSingle();
      return row == null ? null : Course.fromRow(row);
    } catch (_) {
      return null;
    }
  }

  /// Returns null on success, or a message for the mother.
  Future<String?> _verify(Course course, PurchaseDetails purchase) async {
    if (!SupabaseBootstrap.isReady) return 'السحابة غير متاحة';
    try {
      final res = await SupabaseBootstrap.client.functions.invoke(
        'verify-course-purchase',
        body: {
          'course_id': course.id,
          'product_id': purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
          'platform': _platform,
        },
      );
      if (res.status >= 200 && res.status < 300) return null;
      if (kDebugMode) debugPrint('[CourseIAP] verify status=${res.status} data=${res.data}');
    } catch (e) {
      if (kDebugMode) debugPrint('[CourseIAP] verify failed: $e');
    }
    return 'تم الدفع لكن تعذّر تفعيل الدورة — تواصلي معانا وهنفعّلها لك فوراً.';
  }

  void _finish(CoursePurchaseResult result) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(result);
    _pending = null;
    _pendingCourse = null;
  }
}
