import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// Bayanour × Arena mobile identity (pixel-matched to arena.site dashboard)
/// Cream #FFF9F3 | Ink #29223F | Purple #6D4BF3 | Green #58CC02 | Orange #FF9600
/// ══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ── Primary — Arena purple ────────────────────────────────────────────────
  static const Color primary = Color(0xFF6D4BF3);
  static const Color primaryDim = Color(0xFF5036D9);
  static const Color primaryFixed = Color(0xFFE8E0FF);
  static const Color primaryFixedDim = Color(0xFFD2C6FF);
  static const Color primaryContainer = Color(0xFFF0EBFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF1A1040);
  static const Color onPrimaryFixedVariant = Color(0xFF3D2A8A);
  static const Color onPrimaryContainer = Color(0xFF2E1F6E);
  static const Color inversePrimary = Color(0xFFB8A6FF);
  static const Color surfaceTint = Color(0xFF6D4BF3);

  // ── Secondary — Arena orange ──────────────────────────────────────────────
  static const Color secondary = Color(0xFFFF9600);
  static const Color secondaryDim = Color(0xFFE07800);
  static const Color secondaryContainer = Color(0xFFFFF4CC);
  static const Color secondaryFixed = Color(0xFFFFF4CC);
  static const Color secondaryFixedDim = Color(0xFFFFE8A3);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryFixed = Color(0xFF3D2200);
  static const Color onSecondaryFixedVariant = Color(0xFF6E4000);
  static const Color onSecondaryContainer = Color(0xFF5A3400);

  // ── Tertiary — Arena green ────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF58CC02);
  static const Color tertiaryDim = Color(0xFF46A302);
  static const Color tertiaryContainer = Color(0xFFE6F9D4);
  static const Color tertiaryFixed = Color(0xFFE6F9D4);
  static const Color tertiaryFixedDim = Color(0xFFC8F0A0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed = Color(0xFF163800);
  static const Color onTertiaryFixedVariant = Color(0xFF2A5C00);
  static const Color onTertiaryContainer = Color(0xFF1F4A00);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE74C5E);
  static const Color errorDim = Color(0xFFC43A4A);
  static const Color errorContainer = Color(0xFFFFE8EC);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF5C1820);

  // ── Surfaces — Arena cream #FFF9F3 ────────────────────────────────────────
  static const Color background = Color(0xFFFFF9F3);
  static const Color surface = Color(0xFFFFF9F3);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0E8DC);
  static const Color surfaceVariant = Color(0xFFF5EDE3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF4EC);
  static const Color surfaceContainer = Color(0xFFF8EFE6);
  static const Color surfaceContainerHigh = Color(0xFFF0E6DC);
  static const Color surfaceContainerHighest = Color(0xFFE6DCD0);
  static const Color inverseSurface = Color(0xFF29223F);
  static const Color inverseOnSurface = Color(0xFFFFF9F3);
  static const Color onSurface = Color(0xFF29223F);
  static const Color onSurfaceVariant = Color(0xFF5D5570);
  static const Color onBackground = Color(0xFF29223F);

  // ── Outlines ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFD4CBE0);
  static const Color outlineVariant = Color(0xFFEDE6F5);

  static const Color hintPlaceholder = Color(0xFF8A8299);

  // ── Progress ──────────────────────────────────────────────────────────────
  static const Color progressActive = Color(0xFF6D4BF3);
  static const Color progressInactive = Color(0xFFD4CBE0);

  // ── Language tile backgrounds ─────────────────────────────────────────────
  static const Color langEnglishBg = Color(0xFFE8F0F5);
  static const Color langArabicBg = Color(0xFFE6F9D4);
  static const Color langFrenchBg = Color(0xFFF0EBFF);
  static const Color langGermanBg = Color(0xFFFFF4CC);
  static const Color langSpanishBg = Color(0xFFFFE8D8);
  static const Color langTurkishBg = Color(0xFFF0E4E8);
  static const Color langUrduBg = Color(0xFFE8EEF0);
  static const Color langIndonesianBg = Color(0xFFF0EBFF);

  // ── Subscription / plan badges ────────────────────────────────────────────
  static const Color planGoldBadge = Color(0xFFFF9600);
  static const Color planMonthlyText = Color(0xFF29223F);
  static const Color planMonthlySub = Color(0xFF6D4BF3);
  static const Color planBronzeText = Color(0xFF6E4C28);
  static const Color planBronzeSub = Color(0xFFE07800);
  static const Color planSilverText = Color(0xFF3A4A52);
  static const Color planSilverSub = Color(0xFF6E858F);
  static const Color planGoldText = Color(0xFF6E4C28);
  static const Color planGoldSub = Color(0xFFFF9600);
  static const Color planBronzeStart = Color(0xFFFFF4CC);
  static const Color planBronzeEnd = Color(0xFFFFE8A3);
  static const Color planSilverStart = Color(0xFFE8F0F5);
  static const Color planSilverEnd = Color(0xFFD2E0E8);
  static const Color planGoldStart = Color(0xFFFFF4CC);
  static const Color planGoldEnd = Color(0xFFFFE0A0);

  // ── Age chips ─────────────────────────────────────────────────────────────
  static const Color ageWarmBg = Color(0xFFFFF4CC);
  static const Color ageOrangeBg = Color(0xFFFFE8D8);
  static const Color ageWarmText = Color(0xFF29223F);
  static const Color ageOrangeText = Color(0xFF29223F);

  // ── Curriculum track accents (Arena dashboard tiles) ──────────────────────
  static const Color trackQuranGold = Color(0xFF46A302);
  static const Color trackQuranLight = Color(0xFFE6F9D4);

  static const Color trackMathOrange = Color(0xFF4A7FD6);
  static const Color trackMathLight = Color(0xFFE2EEFF);

  static const Color trackVisualPurple = Color(0xFF6D4BF3);
  static const Color trackVisualLight = Color(0xFFF0EBFF);

  static const Color trackEmotionalRed = Color(0xFFE85D8A);
  static const Color trackEmotionalLight = Color(0xFFFFE5EE);

  static const Color trackLibraryBlue = Color(0xFF5B8DEF);
  static const Color trackLibraryLight = Color(0xFFE8F0FF);

  static const Color trackExerciseGreen = Color(0xFF58CC02);
  static const Color trackExerciseLight = Color(0xFFE6F9D4);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B6FFF), Color(0xFF6D4BF3)],
  );

  /// Arena phone: flat cream (no multi-tone wash).
  static const LinearGradient warmBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF9F3), Color(0xFFFFF9F3)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0EBFF), Color(0xFFFFF4CC)],
  );

  /// Arena «خطة اليوم» card.
  static const LinearGradient todayPlanGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF8B6FFF), Color(0xFF6D4BF3), Color(0xFF5036D9)],
  );

  // ── BeBo marketing aliases ────────────────────────────────────────────────
  static const Color beboSplashPurple = primary;
  static const Color beboSplashPurpleDeep = primaryDim;
  static const Color beboTealWave = tertiary;
  static const Color beboMarketingPurple = primary;
  static const Color beboMarketingPurpleDim = primaryDim;
  static const Color beboIndigoHeading = onSurface;
  static const Color beboLavenderCta = Color(0xFF8B6FFF);
  static const Color beboLavenderCtaDeep = Color(0xFF6D4BF3);
  static const Color beboTealOnboarding = tertiary;

  static const LinearGradient beboPurpleCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [beboMarketingPurple, beboMarketingPurpleDim],
  );

  static const LinearGradient beboLavenderCtaGradient = LinearGradient(
    colors: [beboLavenderCta, beboLavenderCtaDeep],
  );
}
