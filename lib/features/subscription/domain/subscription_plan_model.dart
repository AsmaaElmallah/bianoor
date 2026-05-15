import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.duration,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.gradient,
    required this.titleColor,
    required this.subtitleColor,
    required this.buttonColor,
    required this.buttonTextColor,
    this.badge,
  });

  final String id;
  final String title;
  final String duration;
  final String price;
  final String priceSuffix;
  final List<String> features;
  final List<Color> gradient;
  final Color titleColor;
  final Color subtitleColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final String? badge;
}

const _commonFeatures = [
  'منهج تعليمي متخصص لمرحلة طفلك العمرية بدقة',
  'أنشطة متخصصة مناسبة لعمره تطوّر مهاراته وإدراكه',
  'تمارين رياضية متخصصة بعمره وتناسب قدراته',
  'توجيه ومتابعة ورقابة منا ومنكم أولاً بأول',
  'استشارات خاصة',
];

final subscriptionPlans = <SubscriptionPlan>[
  SubscriptionPlan(
    id: 'monthly',
    title: 'الباقة الشهرية',
    duration: 'شهر واحد',
    price: r'$5',
    priceSuffix: '/ شهر',
    features: _commonFeatures,
    gradient: const [AppColors.surfaceContainerLowest, AppColors.surfaceContainerLow],
    titleColor: AppColors.planMonthlyText,
    subtitleColor: AppColors.planMonthlySub,
    buttonColor: Colors.white,
    buttonTextColor: AppColors.primary,
  ),
  SubscriptionPlan(
    id: 'bronze',
    title: 'الباقة البرونزية',
    duration: '3 أشهر',
    price: r'$15',
    priceSuffix: '/ 3 أشهر',
    features: _commonFeatures,
    gradient: const [AppColors.planBronzeStart, AppColors.planBronzeEnd],
    titleColor: AppColors.planBronzeText,
    subtitleColor: AppColors.planBronzeSub,
    buttonColor: AppColors.planBronzeText,
    buttonTextColor: Colors.white,
  ),
  SubscriptionPlan(
    id: 'silver',
    title: 'الباقة الفضية',
    duration: '6 أشهر',
    price: r'$30',
    priceSuffix: '/ 6 أشهر',
    features: _commonFeatures,
    gradient: const [AppColors.planSilverStart, AppColors.planSilverEnd],
    titleColor: AppColors.planSilverText,
    subtitleColor: AppColors.planSilverSub,
    buttonColor: AppColors.planSilverText,
    buttonTextColor: Colors.white,
  ),
  SubscriptionPlan(
    id: 'gold',
    title: 'الباقة الذهبية',
    duration: 'سنة كاملة',
    price: r'$60',
    priceSuffix: '/ سنة',
    features: _commonFeatures,
    gradient: const [AppColors.planGoldStart, AppColors.planGoldEnd],
    titleColor: AppColors.planGoldText,
    subtitleColor: AppColors.planGoldSub,
    buttonColor: AppColors.planGoldText,
    buttonTextColor: Colors.white,
    badge: 'الأكثر توفيراً',
  ),
];
