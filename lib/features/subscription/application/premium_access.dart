import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../data/subscription_cloud_repository.dart';

/// [known] is false when neither the server nor a cached answer was available.
typedef LessonAccess = ({int days, bool known});

/// Falls back to the last value the server reported when offline.
final lessonAccessProvider = FutureProvider<LessonAccess>((ref) async {
  ref.watch(mySubscriptionProvider);
  final prefs = ref.watch(prefsServiceProvider);
  final days = await ref.watch(subscriptionCloudRepositoryProvider).fetchUnlockedLessonDays();
  final userId = SupabaseBootstrap.isReady ? SupabaseBootstrap.client.auth.currentUser?.id : null;
  if (userId == null) return (days: days ?? 0, known: days != null);
  if (days == null) {
    final cached = prefs.getCachedLessonDays(userId);
    return (days: cached ?? 0, known: cached != null);
  }
  await prefs.setCachedLessonDays(userId, days);
  return (days: days, known: true);
});

/// Curriculum days the four lessons are unlocked up to (0 = nothing paid yet).
final unlockedLessonDaysProvider = FutureProvider<int>((ref) async {
  return (await ref.watch(lessonAccessProvider.future)).days;
});

/// Keeps a calendar-based curriculum [day] from running past the first locked day,
/// so days that pass while unpaid are not skipped once she pays.
Future<int> holdCurriculumDay(Ref ref, int day) async {
  final access = await ref.watch(lessonAccessProvider.future);
  if (!access.known || day <= access.days + 1) return day;
  return access.days + 1;
}

/// Message shown on the plans screen when a locked lesson day was tapped.
String lessonLockedReason(int unlocked) => unlocked <= 0
    ? 'دروس طفلك بتتفتح بالباقة، وكل باقة بتفتح أيام بتفضل معاكِ على طول.'
    : 'طفلك خلّص الـ $unlocked يوم المفتوحين 👏 افتحي الأيام الجاية عشان يكمل.';

/// Opens the plans screen and refreshes access after it closes.
Future<void> openPlansForLessons(BuildContext context, WidgetRef ref) async {
  final unlocked = await ref.read(unlockedLessonDaysProvider.future);
  if (!context.mounted) return;
  await context.push<bool>(AppRoutes.subscription, extra: lessonLockedReason(unlocked));
  ref.invalidate(mySubscriptionProvider);
}

/// True when curriculum [day] is unlocked; otherwise offers the plans and re-checks after.
Future<bool> requireLessonDay(BuildContext context, WidgetRef ref, int day) async {
  if (day <= await ref.read(unlockedLessonDaysProvider.future)) return true;
  if (!context.mounted) return false;
  await openPlansForLessons(context, ref);
  return day <= await ref.read(unlockedLessonDaysProvider.future);
}
