import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

/// صورة الطفل فقط في أعلى الرئيسية (بدون كارت الترحيب).
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, this.babyName = 'طفلك'});

  /// محفوظ للتوافق مع الاستدعاء؛ غير معروض حالياً.
  final String babyName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AppAssets.logoBaby,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(height: 140),
      ),
    );
  }
}
