import 'package:flutter/material.dart';

/// BeBo Warm Palette — redesigned for a warm, playful baby-learning app feel.
/// Primary: turquoise #00AFAA · Secondary: coral #F1758E · Accent: sky #41AFE4
/// Background: warm cream #FFF8F2 (replaces cold blue-gray #F3F7FA)
class AppColors {
  AppColors._();

  // ── Primary (Turquoise) ───────────────────────────────────────────────────
  static const Color primary           = Color(0xFF00AFAA);
  static const Color primaryDim        = Color(0xFF008A85);
  static const Color primaryFixed      = Color(0xFFB8EAE8);
  static const Color primaryFixedDim   = Color(0xFF9ADBD8);
  static const Color primaryContainer  = Color(0xFFCDF5F3);
  static const Color onPrimary                = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed           = Color(0xFF00494A);
  static const Color onPrimaryFixedVariant    = Color(0xFF006B6C);
  static const Color onPrimaryContainer       = Color(0xFF004241);
  static const Color inversePrimary           = Color(0xFF74BAB9);
  static const Color surfaceTint              = Color(0xFF00AFAA);

  // ── Secondary (Coral Pink) ────────────────────────────────────────────────
  static const Color secondary              = Color(0xFFF1758E);
  static const Color secondaryDim           = Color(0xFFD95F7A);
  static const Color secondaryContainer     = Color(0xFFFFD9E0); // warm pink tint
  static const Color secondaryFixed         = Color(0xFFFFD9E0);
  static const Color secondaryFixedDim      = Color(0xFFFFBEC9);
  static const Color onSecondary            = Color(0xFFFFFFFF);
  static const Color onSecondaryFixed       = Color(0xFF5D1528);
  static const Color onSecondaryFixedVariant= Color(0xFF7A2339);
  static const Color onSecondaryContainer   = Color(0xFF5D1528);

  // ── Tertiary (Sky Blue) ───────────────────────────────────────────────────
  static const Color tertiary              = Color(0xFF41AFE4);
  static const Color tertiaryDim           = Color(0xFF2E9AD0);
  static const Color tertiaryContainer     = Color(0xFFDDF0FB); // soft sky tint
  static const Color tertiaryFixed         = Color(0xFFDDF0FB);
  static const Color tertiaryFixedDim      = Color(0xFFC5E5F6);
  static const Color onTertiary            = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed       = Color(0xFF014A63);
  static const Color onTertiaryFixedVariant= Color(0xFF016486);
  static const Color onTertiaryContainer   = Color(0xFF014A63);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error            = Color(0xFFF42D29);
  static const Color errorDim         = Color(0xFFC41E1A);
  static const Color errorContainer   = Color(0xFFFFDAD6);
  static const Color onError          = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF690005);

  // ── Surfaces — warm cream replaces cold blue-gray ─────────────────────────
  /// Warm cream — الخلفية الرئيسية الدافية (was cold #F3F7FA)
  static const Color background              = Color(0xFFFFF8F2);
  static const Color surface                 = Color(0xFFFFF8F2);
  static const Color surfaceBright           = Color(0xFFFFFFFF);
  static const Color surfaceDim              = Color(0xFFF5EAE0);  // warm peach-gray
  static const Color surfaceVariant          = Color(0xFFF5EAE0);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFFFF1E8); // warm cream-peach
  static const Color surfaceContainer        = Color(0xFFFFE8D8); // peach
  static const Color surfaceContainerHigh    = Color(0xFFFFDDC8); // deeper peach
  static const Color surfaceContainerHighest = Color(0xFFFFD1B8); // warm orange-peach
  static const Color inverseSurface          = Color(0xFF2A1F1A); // warm dark
  static const Color inverseOnSurface        = Color(0xFFFFF1E8);
  static const Color onSurface              = Color(0xFF2A1F1A); // warm dark charcoal
  static const Color onSurfaceVariant        = Color(0xFF7A6055); // warm medium brown
  static const Color onBackground            = Color(0xFF2A1F1A);

  // ── Outlines ──────────────────────────────────────────────────────────────
  static const Color outline        = Color(0xFFE8D5C8); // warm light border
  static const Color outlineVariant = Color(0xFFF0E4D8); // very soft warm border

  // ── Progress ──────────────────────────────────────────────────────────────
  static const Color progressActive   = Color(0xFF00AFAA);
  static const Color progressInactive = Color(0xFFE8D5C8);

  // ── Language tile backgrounds (warm pastels) ──────────────────────────────
  static const Color langEnglishBg    = Color(0xFFBFE0EF); // pastel blue
  static const Color langArabicBg     = Color(0xFFC8E6BF); // mint green
  static const Color langFrenchBg     = Color(0xFFF5D5F0); // lavender
  static const Color langGermanBg     = Color(0xFFFFE8A0); // warm yellow
  static const Color langSpanishBg    = Color(0xFFFFD5B8); // warm peach
  static const Color langTurkishBg    = Color(0xFFFFCDD5); // coral tint
  static const Color langUrduBg       = Color(0xFFCCF0ED); // teal tint
  static const Color langIndonesianBg = Color(0xFFE8D8F5); // periwinkle

  // ── Subscription / plan badges ────────────────────────────────────────────
  static const Color planGoldBadge     = Color(0xFFFFCC37);
  static const Color planMonthlyText   = Color(0xFF2A1F1A);
  static const Color planMonthlySub    = Color(0xFF00AFAA);
  static const Color planBronzeText    = Color(0xFF5E3A17);
  static const Color planBronzeSub     = Color(0xFF8C6239);
  static const Color planSilverText    = Color(0xFF2D3748);
  static const Color planSilverSub     = Color(0xFF4A5568);
  static const Color planGoldText      = Color(0xFF5C4A16);
  static const Color planGoldSub       = Color(0xFF8C7324);
  static const Color planBronzeStart   = Color(0xFFEADDCC);
  static const Color planBronzeEnd     = Color(0xFFD4B499);
  static const Color planSilverStart   = Color(0xFFE8EEF1);
  static const Color planSilverEnd     = Color(0xFFC4D1D9);
  static const Color planGoldStart     = Color(0xFFFCEEB5);
  static const Color planGoldEnd       = Color(0xFFEBD171);

  // ── Age chips ─────────────────────────────────────────────────────────────
  static const Color ageWarmBg    = Color(0xFFFFE8A0);
  static const Color ageOrangeBg  = Color(0xFFFFD5B8);
  static const Color ageWarmText  = Color(0xFF2A1F1A);
  static const Color ageOrangeText= Color(0xFF2A1F1A);

  // ── Curriculum track accent colors ───────────────────────────────────────
  /// Each curriculum section has its own warm accent for cards + icons
  static const Color trackQuranGold    = Color(0xFFFFAA00);
  static const Color trackQuranLight   = Color(0xFFFFF3CC);
  static const Color trackMathOrange   = Color(0xFFFF7043);
  static const Color trackMathLight    = Color(0xFFFFE4DB);
  static const Color trackVisualPurple = Color(0xFF9C6FD6);
  static const Color trackVisualLight  = Color(0xFFEFE3FF);
  static const Color trackEmotionalRed = Color(0xFFF1758E);
  static const Color trackEmotionalLight = Color(0xFFFFE4EC);
  static const Color trackLibraryBlue  = Color(0xFF41AFE4);
  static const Color trackLibraryLight = Color(0xFFE0F3FD);
  static const Color trackExerciseGreen= Color(0xFF4CAF7D);
  static const Color trackExerciseLight= Color(0xFFDDF6E8);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, tertiary],
  );

  /// Warm scaffold gradient — the main background for most screens
  static const LinearGradient warmBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8F2), // warm cream top
      Color(0xFFFFF2E8), // peach bottom
    ],
  );

  /// Hero gradient for top sections (home, subscription)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFCDF5F3), // mint teal
      Color(0xFFFFE8D8), // warm peach
    ],
  );

  // ── BeBo marketing / splash ───────────────────────────────────────────────
  static const Color beboSplashPurple      = Color(0xFF5E4FD6);
  static const Color beboSplashPurpleDeep  = Color(0xFF4534B8);
  static const Color beboTealWave          = Color(0xFF26BBAA);
  static const Color beboMarketingPurple   = Color(0xFF5D5FEF);
  static const Color beboMarketingPurpleDim= Color(0xFF4B4DD6);
  static const Color beboIndigoHeading     = Color(0xFF5C67B1);
  static const Color beboLavenderCta       = Color(0xFFD4C4F7);
  static const Color beboLavenderCtaDeep   = Color(0xFFB9A3EB);
  static const Color beboTealOnboarding    = Color(0xFF26BBAA);

  static const LinearGradient beboPurpleCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [beboMarketingPurple, beboMarketingPurpleDim],
  );

  static const LinearGradient beboLavenderCtaGradient = LinearGradient(
    colors: [beboLavenderCta, beboLavenderCtaDeep],
  );
}
