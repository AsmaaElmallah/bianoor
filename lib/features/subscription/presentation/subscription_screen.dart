import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../domain/subscription_plan_model.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -96,
              right: -88,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.62),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 248,
              left: -150,
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.46),
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
                      const _TopRoundAvatar(
                        child: Icon(Symbols.menu, color: AppColors.primary, size: 24, fill: 1),
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
                        Container(
                          width: 128,
                          height: 128,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            AppAssets.logoBaby,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Symbols.child_care,
                              color: AppColors.primary,
                              fill: 1,
                              size: 72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'اختر باقتك التعليمية',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'استثمر في مستقبل طفلك مع مناهجنا\nالمتخصصة والأنشطة التفاعلية',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ...subscriptionPlans.map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PlanCard(
                              plan: plan,
                              onSubscribe: () => context.go(AppRoutes.onboardingQuestions),
                            ),
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
  final VoidCallback onSubscribe;

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
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: plan.buttonColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onSubscribe,
                child: Center(
                  child: Text(
                    'اشترك الآن',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: plan.buttonTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
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
          Text('طرق الدفع الإلكترونية',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PayBadge(label: 'APPLE', dark: true, icon: Symbols.phone_iphone),
              _PayBadge(label: 'GOOGLE', dark: false, icon: Symbols.payments),
              _PayBadge(label: 'VISA', dark: false, icon: Symbols.credit_card),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تشفير آمن لحماية بيانات الدفع',
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
