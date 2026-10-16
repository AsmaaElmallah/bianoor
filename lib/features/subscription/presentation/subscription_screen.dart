import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_widget.dart';
import '../../payments/domain/payment_item.dart';
import '../../payments/presentation/payment_options_sheet.dart';
import '../../notifications/application/push_notifications.dart';
import '../application/premium_access.dart';
import '../data/subscription_cloud_repository.dart';
import '../domain/subscription_plan_model.dart';

/// Opened with [reason] (e.g. «افتحي اليوم 31 من الحساب») when a locked item was tapped.
/// Pops `true` after a successful payment when pushed on top of another screen.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, this.reason});

  final String? reason;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _busyPlanId;

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (_busyPlanId != null) return;
    setState(() => _busyPlanId = plan.id);
    final paid = await payWithPaypal(
      context,
      ref,
      PaymentItem(kind: PaymentKind.subscription, id: plan.id, title: plan.title, priceUsd: plan.priceUsd),
    );
    if (!mounted) return;
    setState(() => _busyPlanId = null);
    if (!paid) return;
    ref.invalidate(mySubscriptionProvider);
    ref.invalidate(lessonAccessProvider);
    unawaited(PushNotifications.instance.cancelSubscriptionRenewal());
    _onActivated(plan);
  }

  void _onActivated(SubscriptionPlan plan) {
    AppAnalytics.purchaseSuccess(plan.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تفعيل ${plan.title} 🎉 اتفتحلك ${plan.durationDays} يوم دروس'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _leave(true);
  }

  void _leave([bool paid = false]) {
    if (context.canPop()) {
      context.pop(paid);
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncPlans = ref.watch(cloudSubscriptionPlansProvider);
    final mySub = ref.watch(mySubscriptionProvider).valueOrNull;
    final reason = widget.reason;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const BeboShellBackground(showBottomCurve: false),
            // Blob bottom-left (accent over shell)
            Positioned(
              bottom: 80,
              left: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      _TopRoundAvatar(
                        child: Image.asset(
                          AppAssets.logoBaby,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Symbols.account_circle, size: 22, color: AppColors.primary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'بيانور',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _leave,
                        child: const _TopRoundAvatar(
                          child: Icon(Symbols.close, color: AppColors.primary, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                    child: Column(
                      children: [
                const SizedBox(height: 8),
                // Floating mascot with glow shadow
                Center(
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 90,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        FloatingWidget(
                          amplitude: 8,
                          duration: const Duration(milliseconds: 3600),
                          child: Image.asset(
                            AppAssets.mascotCapLying,
                            height: 135,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 128,
                              height: 128,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Symbols.child_care,
                                  color: AppColors.primary, fill: 1, size: 72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                        const SizedBox(height: 20),
                        Text(
                          (mySub?.lessonDays ?? 0) > 0 ? 'مدّي باقتكِ' : 'اختاري باقتكِ',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (reason != null && reason.isNotEmpty) ...[
                          Text(
                            reason,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          (mySub?.lessonDays ?? 0) > 0
                              ? 'أي باقة هتزود أيام على المفتوحلكِ دلوقتي، واللي اتفتح قبل كده بيفضل معاكِ.'
                              : 'كل باقة بتفتح أيام من الدروس الأربعة، وبتتجمع مع اللي قبلها.\nاللي اتفتح بيفضل معاكِ على طول.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if ((mySub?.lessonDays ?? 0) > 0 || mySub?.isActive == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                [
                                  if ((mySub?.lessonDays ?? 0) > 0)
                                    'مفتوحلكِ دلوقتي ${mySub!.lessonDays} يوم — التمديد هيضيف أيام جديدة فوقهم',
                                  if (mySub?.isActive == true && mySub?.expiresAt != null)
                                    'تنتهي المزايا في ${_formatExpiry(mySub!.expiresAt!.toLocal())}',
                                ].join('\n'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ...((asyncPlans.valueOrNull?.isNotEmpty == true)
                                ? asyncPlans.valueOrNull!
                                : const <SubscriptionPlan>[])
                            .map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PlanCard(
                              plan: plan,
                              onSubscribe: _busyPlanId == null && plan.canBuy
                                  ? () => _subscribe(plan)
                                  : null,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _leave,
                          child: const Text('بعدين'),
                        ),
                        if (asyncPlans.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if ((asyncPlans.valueOrNull ?? []).isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'الباقات مش متاحة دلوقتي، جربي بعدين.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 6),
                        const _PaymentSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSubscribe});
  final SubscriptionPlan plan;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [plan.gradient.first, plan.gradient.last],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.planGoldBadge,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    plan.badge!,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              if (plan.savingsPercent != null) ...[
                if (plan.badge != null) const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    'وفّري ${plan.savingsPercent}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                plan.duration,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: plan.titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: plan.titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: plan.price,
              style: theme.textTheme.displaySmall?.copyWith(
                color: plan.titleColor,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: ' ${plan.priceSuffix}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: plan.titleColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Symbols.check_circle, size: 20, color: AppColors.onSurface, fill: 1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: plan.titleColor.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ClaySubscribeButton(
            label: plan.canBuy
                ? 'ادفعي ومدّي ${plan.durationDays} يوم دروس'
                : 'السعر هيتحدد قريب',
            color: plan.buttonColor,
            textColor: plan.buttonTextColor,
            onTap: onSubscribe,
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text('طريقة الدفع',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PayBadge(label: 'PAYPAL', dark: true, icon: Symbols.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'الدفع بالدولار عن طريق PayPal — آمن ومشفّر',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          )
        ],
      ),
    );
  }
}

class _PayBadge extends StatelessWidget {
  const _PayBadge({required this.label, required this.dark, required this.icon});
  final String label;
  final bool dark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.onSurface;
    final bg = dark ? Colors.black : AppColors.surfaceContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 15),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ClaySubscribeButton extends StatefulWidget {
  const _ClaySubscribeButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  State<_ClaySubscribeButton> createState() => _ClaySubscribeButtonState();
}

class _ClaySubscribeButtonState extends State<_ClaySubscribeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final depth = Color.lerp(widget.color, Colors.black, 0.2) ?? widget.color;
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 200),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        height: 52 + (_pressed ? 0 : 5),
        transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
        child: Stack(
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 52 + (_pressed ? 0 : 5),
                decoration: BoxDecoration(
                  color: depth,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              left: 0, right: 0, top: 0,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.textColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatExpiry(DateTime local) {
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

class _TopRoundAvatar extends StatelessWidget {
  const _TopRoundAvatar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: child),
    );
  }
}
