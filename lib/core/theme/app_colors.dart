import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// Bayanour warm palette — sugar beige + dusty rose + caramel
/// Background #FFF8F1 | Primary #B77B72 | Secondary #C79254 | Text #493732
/// Tertiary olive #7C8668 for calm accents
/// ══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ── Primary — dusty rose ──────────────────────────────────────────────────
  static const Color primary = Color(0xFFB77B72);
  static const Color primaryDim = Color(0xFF9A635C);
  static const Color primaryFixed = Color(0xFFF0D9D5);
  static const Color primaryFixedDim = Color(0xFFE2C0BA);
  static const Color primaryContainer = Color(0xFFF6E8E5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF3A221F);
  static const Color onPrimaryFixedVariant = Color(0xFF6E4540);
  static const Color onPrimaryContainer = Color(0xFF5A3834);
  static const Color inversePrimary = Color(0xFFD9A8A1);
  static const Color surfaceTint = Color(0xFFB77B72);

  // ── Secondary — caramel ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFFC79254);
  static const Color secondaryDim = Color(0xFFA8783F);
  static const Color secondaryContainer = Color(0xFFF6E6D0);
  static const Color secondaryFixed = Color(0xFFF6E6D0);
  static const Color secondaryFixedDim = Color(0xFFE8D0AE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryFixed = Color(0xFF3D2A12);
  static const Color onSecondaryFixedVariant = Color(0xFF6E4C28);
  static const Color onSecondaryContainer = Color(0xFF5A3E20);

  // ── Tertiary — quiet olive ────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF7C8668);
  static const Color tertiaryDim = Color(0xFF646E52);
  static const Color tertiaryContainer = Color(0xFFE4E8DC);
  static const Color tertiaryFixed = Color(0xFFE4E8DC);
  static const Color tertiaryFixedDim = Color(0xFFCBD2C0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed = Color(0xFF2A3020);
  static const Color onTertiaryFixedVariant = Color(0xFF4A5340);
  static const Color onTertiaryContainer = Color(0xFF3A4232);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFC45C5C);
  static const Color errorDim = Color(0xFFA84848);
  static const Color errorContainer = Color(0xFFF8E4E4);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF5C2424);

  // ── Surfaces — sugar cream #FFF8F1 ────────────────────────────────────────
  static const Color background = Color(0xFFFFF8F1);
  static const Color surface = Color(0xFFFFF8F1);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF0E6DA);
  static const Color surfaceVariant = Color(0xFFF5EBE1);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF4EC);
  static const Color surfaceContainer = Color(0xFFF8EDE3);
  static const Color surfaceContainerHigh = Color(0xFFF0E3D7);
  static const Color surfaceContainerHighest = Color(0xFFE6D7C9);
  static const Color inverseSurface = Color(0xFF493732);
  static const Color inverseOnSurface = Color(0xFFFFF8F1);
  static const Color onSurface = Color(0xFF493732);
  static const Color onSurfaceVariant = Color(0xFF6E5A52);
  static const Color onBackground = Color(0xFF493732);

  // ── Outlines ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFDCCFBD);
  static const Color outlineVariant = Color(0xFFEDE2D4);

  static const Color hintPlaceholder = Color(0xFF7A6A62);

  // ── Progress ──────────────────────────────────────────────────────────────
  static const Color progressActive = Color(0xFFB77B72);
  static const Color progressInactive = Color(0xFFDCCFBD);

  // ── Language tile backgrounds ─────────────────────────────────────────────
  static const Color langEnglishBg = Color(0xFFE8F0F5);
  static const Color langArabicBg = Color(0xFFE4E8DC);
  static const Color langFrenchBg = Color(0xFFF6E8E5);
  static const Color langGermanBg = Color(0xFFF6E6D0);
  static const Color langSpanishBg = Color(0xFFF5E6D8);
  static const Color langTurkishBg = Color(0xFFF4E3DE);
  static const Color langUrduBg = Color(0xFFE8EEF0);
  static const Color langIndonesianBg = Color(0xFFF6E8E5);

  // ── Subscription / plan badges ────────────────────────────────────────────
  static const Color planGoldBadge = Color(0xFFC79254);
  static const Color planMonthlyText = Color(0xFF493732);
  static const Color planMonthlySub = Color(0xFFB77B72);
  static const Color planBronzeText = Color(0xFF6E4C28);
  static const Color planBronzeSub = Color(0xFFA8783F);
  static const Color planSilverText = Color(0xFF3A4A52);
  static const Color planSilverSub = Color(0xFF6E858F);
  static const Color planGoldText = Color(0xFF6E4C28);
  static const Color planGoldSub = Color(0xFFC79254);
  static const Color planBronzeStart = Color(0xFFF6E6D0);
  static const Color planBronzeEnd = Color(0xFFE8D0AE);
  static const Color planSilverStart = Color(0xFFE8F0F5);
  static const Color planSilverEnd = Color(0xFFD2E0E8);
  static const Color planGoldStart = Color(0xFFF8ECCC);
  static const Color planGoldEnd = Color(0xFFE8D4A0);

  // ── Age chips ─────────────────────────────────────────────────────────────
  static const Color ageWarmBg = Color(0xFFF6E6D0);
  static const Color ageOrangeBg = Color(0xFFF5E6D8);
  static const Color ageWarmText = Color(0xFF493732);
  static const Color ageOrangeText = Color(0xFF493732);

  // ── Curriculum track accents ──────────────────────────────────────────────
  static const Color trackQuranGold = Color(0xFFC79254);
  static const Color trackQuranLight = Color(0xFFF6E6D0);

  static const Color trackMathOrange = Color(0xFFB9785D);
  static const Color trackMathLight = Color(0xFFF5E6D8);

  static const Color trackVisualPurple = Color(0xFF9A7B86);
  static const Color trackVisualLight = Color(0xFFF0E4E8);

  static const Color trackEmotionalRed = Color(0xFFB77B72);
  static const Color trackEmotionalLight = Color(0xFFF6E8E5);

  static const Color trackLibraryBlue = Color(0xFF6E858F);
  static const Color trackLibraryLight = Color(0xFFE8F0F5);

  static const Color trackExerciseGreen = Color(0xFF7C8668);
  static const Color trackExerciseLight = Color(0xFFE4E8DC);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC7928A), Color(0xFFB77B72)],
  );

  static const LinearGradient warmBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8F1), Color(0xFFF8EDE3)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E8E5), Color(0xFFF6E6D0)],
  );

  // ── BeBo marketing aliases (kept for existing call sites) ─────────────────
  static const Color beboSplashPurple = primary;
  static const Color beboSplashPurpleDeep = primaryDim;
  static const Color beboTealWave = tertiary;
  static const Color beboMarketingPurple = primary;
  static const Color beboMarketingPurpleDim = primaryDim;
  static const Color beboIndigoHeading = onSurface;
  static const Color beboLavenderCta = Color(0xFFC7928A);
  static const Color beboLavenderCtaDeep = Color(0xFFB77B72);
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
