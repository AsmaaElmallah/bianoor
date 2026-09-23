import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/subscription_cloud_repository.dart';

/// Blocks premium UI until the user has an active cloud subscription.
class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({
    super.key,
    required this.child,
    this.title = 'هذه الميزة للمشتركين',
    this.message = 'اشتركي في إحدى الباقات للمتابعة.',
  });

  final Widget child;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mySubscriptionProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => _Locked(
        title: title,
        message: 'تعذّر التحقق من الاشتراك. حاولِ لاحقاً.',
      ),
      data: (sub) {
        if (sub?.isActive == true) return child;
        return _Locked(title: title, message: message);
      },
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'عرض الباقات',
              onPressed: () => context.push(AppRoutes.subscription),
            ),
          ],
        ),
      ),
    );
  }
}
