import 'package:flutter/material.dart';

/// Material 3 tokens aligned with the official **BeBo** palette (primary / secondary / grays).
/// Reference swatches: turquoise `#00AFAA`, coral `#F1758E`, sky `#41AFE4`, pastels + `#E7ECF7` surfaces.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00AFAA); // Vibrant Turquoise
  static const Color primaryDim = Color(0xFF008A85);
  static const Color primaryFixed = Color(0xFFBFE0EF); // Light Pastel Blue
  static const Color primaryFixedDim = Color(0xFFA8D4EA);
  static const Color primaryContainer = Color(
    0xFFD4F5F4,
  ); // Light turquoise tint
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF00494A);
  static const Color onPrimaryFixedVariant = Color(0xFF006B6C);
  static const Color onPrimaryContainer = Color(0xFF004241);
  static const Color inversePrimary = Color(0xFF74BAB9); // Muted Teal
  static const Color surfaceTint = Color(0xFF00AFAA);

  static const Color secondary = Color(0xFFF1758E); // Coral Pink
  static const Color secondaryDim = Color(0xFFD95F7A);
  static const Color secondaryContainer = Color(0xFFFDD7C6); // Pale Peach
  static const Color secondaryFixed = Color(0xFFFDD7C6);
  static const Color secondaryFixedDim = Color(0xFFFCC4AE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryFixed = Color(0xFF5D1528);
  static const Color onSecondaryFixedVariant = Color(0xFF7A2339);
  static const Color onSecondaryContainer = Color(0xFF5D1528);

  static const Color tertiary = Color(0xFF41AFE4); // Sky Blue
  static const Color tertiaryDim = Color(0xFF2E9AD0);
  static const Color tertiaryContainer = Color(
    0xFFE7ECF7,
  ); // Off-White Periwinkle
  static const Color tertiaryFixed = Color(0xFFE7ECF7);
  static const Color tertiaryFixedDim = Color(0xFFD9E0F0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed = Color(0xFF014A63);
  static const Color onTertiaryFixedVariant = Color(0xFF016486);
  static const Color onTertiaryContainer = Color(0xFF014A63);

  static const Color error = Color(0xFFF42D29); // Bright Red
  static const Color errorDim = Color(0xFFC41E1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF690005);

  /// Slightly cool off-white; pairs with soft clay shadows.
  static const Color background = Color(0xFFF3F7FA);
  static const Color surface = Color(0xFFF3F7FA);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE7ECF7);
  static const Color surfaceVariant = Color(0xFFE7ECF7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEBF0F7);
  static const Color surfaceContainer = Color(0xFFE7ECF7);
  static const Color surfaceContainerHigh = Color(0xFFE0E6F2);
  static const Color surfaceContainerHighest = Color(0xFFD8DEE9);
  static const Color inverseSurface = Color(0xFF1F272E);
  static const Color inverseOnSurface = Color(0xFFE7ECF7);
  static const Color onSurface = Color(0xFF1F272E); // Dark Charcoal
  static const Color onSurfaceVariant = Color(0xFF70767B); // Medium-Dark Gray
  static const Color onBackground = Color(0xFF1F272E);

  static const Color outline = Color(0xFFDCDCDC); // Light Gray
  static const Color outlineVariant = Color(0xFFE8E8E8);

  // Progress indicator tokens
  static const Color progressActive = Color(0xFF00AFAA);
  static const Color progressInactive = Color(0xFFDCDCDC);

  // Language tile backgrounds (BeBo secondary pastels)
  static const Color langEnglishBg = Color(0xFFBFE0EF); // Light Pastel Blue
  static const Color langArabicBg = Color(0xFFCDE5C2); // Pale Mint Green
  static const Color langFrenchBg = Color(0xFFF8E2F5); // Pale Lavender
  static const Color langGermanBg = Color(0xFFFFEBC0); // Creamy Yellow
  static const Color langSpanishBg = Color(0xFFFDD7C6); // Pale Peach
  static const Color langTurkishBg = Color(0xFFFDE8EC); // Coral tint
  static const Color langUrduBg = Color(0xFFE3F4F3); // Muted Teal tint
  static const Color langIndonesianBg = Color(
    0xFFE7ECF7,
  ); // Off-White Periwinkle

  // Subscription badge / plans
  static const Color planGoldBadge = Color(0xFFFFCC37); // Golden Yellow
  static const Color planMonthlyText = Color(0xFF1F272E);
  static const Color planMonthlySub = Color(0xFF00AFAA);
  static const Color planBronzeText = Color(0xFF5E3A17);
  static const Color planBronzeSub = Color(0xFF8C6239);
  static const Color planSilverText = Color(0xFF2D3748);
  static const Color planSilverSub = Color(0xFF4A5568);
  static const Color planGoldText = Color(0xFF5C4A16);
  static const Color planGoldSub = Color(0xFF8C7324);
  static const Color planBronzeStart = Color(0xFFEADDCC);
  static const Color planBronzeEnd = Color(0xFFD4B499);
  static const Color planSilverStart = Color(0xFFE8EEF1);
  static const Color planSilverEnd = Color(0xFFC4D1D9);
  static const Color planGoldStart = Color(0xFFFCEEB5);
  static const Color planGoldEnd = Color(0xFFEBD171);

  // Baby age chips (BeBo yellow / peach)
  static const Color ageWarmBg = Color(0xFFFFEBC0); // Creamy Yellow
  static const Color ageOrangeBg = Color(0xFFFDD7C6); // Pale Peach
  static const Color ageWarmText = Color(0xFF1F272E);
  static const Color ageOrangeText = Color(0xFF1F272E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, tertiary],
  );

  // —— BeBo marketing / splash (screenshots) ——
  static const Color beboSplashPurple = Color(0xFF5E4FD6);
  static const Color beboSplashPurpleDeep = Color(0xFF4534B8);
  static const Color beboTealWave = Color(0xFF26BBAA);
  static const Color beboMarketingPurple = Color(0xFF5D5FEF);
  static const Color beboMarketingPurpleDim = Color(0xFF4B4DD6);
  static const Color beboIndigoHeading = Color(0xFF5C67B1);
  static const Color beboLavenderCta = Color(0xFFD4C4F7);
  static const Color beboLavenderCtaDeep = Color(0xFFB9A3EB);
  static const Color beboTealOnboarding = Color(0xFF26BBAA);

  static const LinearGradient beboPurpleCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [beboMarketingPurple, beboMarketingPurpleDim],
  );

  static const LinearGradient beboLavenderCtaGradient = LinearGradient(
    colors: [beboLavenderCta, beboLavenderCtaDeep],
  );
}
