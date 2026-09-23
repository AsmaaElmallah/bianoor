import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/subscription_plan_model.dart';

final subscriptionCloudRepositoryProvider =
    Provider<SubscriptionCloudRepository>((ref) {
  return SubscriptionCloudRepository();
});

final cloudSubscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(subscriptionCloudRepositoryProvider).fetchActivePlans();
});

final mySubscriptionProvider = FutureProvider<UserSubscription?>((ref) {
  return ref.watch(subscriptionCloudRepositoryProvider).fetchMySubscription();
});

final hasActiveSubscriptionProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(mySubscriptionProvider).whenData((sub) => sub?.isActive ?? false);
});

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.planId,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String? planId;
  final String status;
  final DateTime? expiresAt;

  bool get isActive {
    if (status != 'active' && status != 'trial') return false;
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(DateTime.now().toUtc());
  }
}

class SubscriptionCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<UserSubscription?> fetchMySubscription() async {
    if (!await _ready()) return null;
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await SupabaseBootstrap.client
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      final exp = row['expires_at'] as String?;
      return UserSubscription(
        id: row['id'] as String,
        planId: row['plan_id'] as String?,
        status: row['status'] as String? ?? 'inactive',
        expiresAt: exp != null ? DateTime.tryParse(exp)?.toUtc() : null,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] mine failed: $e\n$st');
      return null;
    }
  }

  /// Debug-only sandbox activate — never call from release purchase paths.
  Future<bool> activatePlan(String planId, {int durationDays = 30}) async {
    if (!kDebugMode) {
      debugPrint('[Subscriptions] activatePlan blocked outside debug');
      return false;
    }
    if (!await _ready()) {
      debugPrint('[Subscriptions] activatePlan: supabase not ready');
      return false;
    }
    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[Subscriptions] activatePlan: no current user');
      return false;
    }

    try {
      final plan = await SupabaseBootstrap.client
          .from('subscription_plans')
          .select('duration_days')
          .eq('id', planId)
          .maybeSingle();
      final days = (plan?['duration_days'] as int?) ?? durationDays;
      final expires = DateTime.now().toUtc().add(Duration(days: days));
      final payload = {
        'user_id': userId,
        'plan_id': planId,
        'status': 'active',
        'expires_at': expires.toIso8601String(),
        'store_receipt':
            'sandbox:${DateTime.now().toUtc().toIso8601String()}',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Prefer update-then-insert so missing UNIQUE migration still works.
      final existing = await SupabaseBootstrap.client
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await SupabaseBootstrap.client
            .from('user_subscriptions')
            .update(payload)
            .eq('user_id', userId);
      } else {
        await SupabaseBootstrap.client.from('user_subscriptions').insert(payload);
      }

      if (kDebugMode) {
        debugPrint('[Subscriptions] activatePlan OK plan=$planId user=$userId');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] activate failed: $e\n$st');
      return false;
    }
  }

  Future<UserSubscription?> restorePurchases() async {
    return fetchMySubscription();
  }

  Future<List<SubscriptionPlan>> fetchActivePlans() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('subscription_plans')
          .select()
          .eq('active', true)
          .order('sort_order');

      final list = <SubscriptionPlan>[];
      var i = 0;
      for (final row in List<Map<String, dynamic>>.from(rows as List)) {
        final featuresRaw = row['features'];
        final features = featuresRaw is List
            ? featuresRaw.map((e) => e.toString()).toList()
            : const <String>[];
        final look = _lookForIndex(i);
        final priceDisplay = row['price_display'] as String? ?? '';
        list.add(
          SubscriptionPlan(
            id: row['id'] as String,
            title: row['name'] as String? ?? 'باقة',
            duration: priceDisplay,
            price: priceDisplay,
            priceSuffix: '',
            features: features,
            gradient: look.gradient,
            titleColor: look.titleColor,
            subtitleColor: look.subtitleColor,
            buttonColor: look.buttonColor,
            buttonTextColor: look.buttonTextColor,
            badge: i == 3 ? 'الأكثر توفيراً' : null,
            storeProductIdIos: row['store_product_id_ios'] as String?,
            storeProductIdAndroid: row['store_product_id_android'] as String?,
            durationDays: (row['duration_days'] as int?) ?? 30,
          ),
        );
        i++;
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] plans failed: $e\n$st');
      return [];
    }
  }
}

class _PlanLook {
  const _PlanLook({
    required this.gradient,
    required this.titleColor,
    required this.subtitleColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });

  final List<Color> gradient;
  final Color titleColor;
  final Color subtitleColor;
  final Color buttonColor;
  final Color buttonTextColor;
}

_PlanLook _lookForIndex(int i) {
  switch (i % 4) {
    case 0:
      return const _PlanLook(
        gradient: [
          AppColors.surfaceContainerLowest,
          AppColors.surfaceContainerLow,
        ],
        titleColor: AppColors.planMonthlyText,
        subtitleColor: AppColors.planMonthlySub,
        buttonColor: Colors.white,
        buttonTextColor: AppColors.primary,
      );
    case 1:
      return const _PlanLook(
        gradient: [AppColors.planBronzeStart, AppColors.planBronzeEnd],
        titleColor: AppColors.planBronzeText,
        subtitleColor: AppColors.planBronzeSub,
        buttonColor: AppColors.planBronzeText,
        buttonTextColor: Colors.white,
      );
    case 2:
      return const _PlanLook(
        gradient: [AppColors.planSilverStart, AppColors.planSilverEnd],
        titleColor: AppColors.planSilverText,
        subtitleColor: AppColors.planSilverSub,
        buttonColor: AppColors.planSilverText,
        buttonTextColor: Colors.white,
      );
    default:
      return const _PlanLook(
        gradient: [AppColors.planGoldStart, AppColors.planGoldEnd],
        titleColor: AppColors.planGoldText,
        subtitleColor: AppColors.planGoldSub,
        buttonColor: AppColors.planGoldText,
        buttonTextColor: Colors.white,
      );
  }
}
