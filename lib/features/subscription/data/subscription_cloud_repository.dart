import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../../payments/domain/payment_item.dart';
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
    this.lessonDays = 0,
  });

  final String id;
  final String? planId;
  final String status;
  final DateTime? expiresAt;

  /// Curriculum days unlocked by all paid plans (cumulative, never expire).
  final int lessonDays;

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
        lessonDays: (row['lesson_days'] as int?) ?? 0,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] mine failed: $e\n$st');
      return null;
    }
  }

  /// Lesson days the server unlocks for the signed-in user (staff get all); null when unreachable.
  Future<int?> fetchUnlockedLessonDays() async {
    if (!await _ready()) return null;
    if (SupabaseBootstrap.client.auth.currentUser == null) return 0;
    try {
      final days = await SupabaseBootstrap.client.rpc('lesson_days_unlocked');
      return (days as num?)?.toInt() ?? 0;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] lesson days failed: $e\n$st');
      return null;
    }
  }

  Future<List<SubscriptionPlan>> fetchActivePlans() async {
    if (!await _ready()) return [];
    try {
      final rows = await SupabaseBootstrap.client
          .from('subscription_plans')
          .select()
          .eq('active', true)
          .order('sort_order');

      final data = List<Map<String, dynamic>>.from(rows as List);
      final savings = planSavings([
        for (final row in data)
          (days: (row['duration_days'] as int?) ?? 30, usd: parseUsd(row['price_usd'])),
      ]);
      var best = -1;
      for (var i = 0; i < savings.length; i++) {
        if ((savings[i] ?? 0) > (best < 0 ? 0 : savings[best]!)) best = i;
      }

      final list = <SubscriptionPlan>[];
      for (var i = 0; i < data.length; i++) {
        final row = data[i];
        final featuresRaw = row['features'];
        final features = featuresRaw is List
            ? featuresRaw.map((e) => e.toString()).toList()
            : const <String>[];
        final look = _lookForIndex(i);
        final days = (row['duration_days'] as int?) ?? 30;
        final usd = parseUsd(row['price_usd']);
        final duration = planDurationLabel(days);
        list.add(
          SubscriptionPlan(
            id: row['id'] as String,
            title: row['name'] as String? ?? 'باقة',
            duration: duration,
            price: formatUsd(usd) ?? 'السعر قريباً',
            priceSuffix: usd == null ? '' : '/ $duration',
            features: features,
            gradient: look.gradient,
            titleColor: look.titleColor,
            subtitleColor: look.subtitleColor,
            buttonColor: look.buttonColor,
            buttonTextColor: look.buttonTextColor,
            badge: i == best ? 'الأكثر توفيراً' : null,
            durationDays: days,
            priceUsd: usd,
            savingsPercent: savings[i],
          ),
        );
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Subscriptions] plans failed: $e\n$st');
      return [];
    }
  }
}

/// Percent saved by each plan vs. buying the shortest priced plan repeatedly.
/// Null for the base plan, unpriced plans, or savings under 1%.
@visibleForTesting
List<int?> planSavings(List<({int days, double? usd})> plans) {
  ({int days, double usd})? base;
  for (final p in plans) {
    final usd = p.usd;
    if (usd == null || p.days <= 0) continue;
    if (base == null || p.days < base.days) base = (days: p.days, usd: usd);
  }
  return [
    for (final p in plans)
      () {
        final usd = p.usd;
        if (base == null || usd == null || p.days <= base.days) return null;
        final full = base.usd * p.days / base.days;
        final pct = ((full - usd) / full * 100).round();
        return pct >= 1 ? pct : null;
      }(),
  ];
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
