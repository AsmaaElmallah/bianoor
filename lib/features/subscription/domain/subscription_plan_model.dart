import 'package:flutter/material.dart';

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
    this.durationDays = 30,
    this.priceUsd,
    this.savingsPercent,
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
  final int durationDays;
  final double? priceUsd;

  /// Saving vs. paying monthly for the same period; null when not meaningful.
  final int? savingsPercent;

  bool get canBuy => priceUsd != null;
}

/// «شهر» / «3 شهور» / «6 شهور» / «سنة» from the plan's duration.
String planDurationLabel(int days) {
  if (days >= 360) return days >= 720 ? '${(days / 365).round()} سنين' : 'سنة';
  final months = (days / 30).round();
  if (months <= 1) return 'شهر';
  if (months == 2) return 'شهرين';
  return '$months شهور';
}
