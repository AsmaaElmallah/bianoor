import 'package:flutter/material.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// BeBo Royal Palette — بيانور
/// Primary: Violet Royal  #6D28D9  |  Secondary: Amber Gold  #D97706
/// Tertiary: Ocean Teal   #0891B2  |  Background: Violet Cream  #FAF5FF
/// ══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ── Primary — Violet Royal ────────────────────────────────────────────────
  static const Color primary           = Color(0xFF6D28D9); // Violet-700
  static const Color primaryDim        = Color(0xFF5B21B6); // Violet-800
  static const Color primaryFixed      = Color(0xFFDDD6FE); // Violet-200
  static const Color primaryFixedDim   = Color(0xFFC4B5FD); // Violet-300
  static const Color primaryContainer  = Color(0xFFEDE9FE); // Violet-100
  static const Color onPrimary                = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed           = Color(0xFF2E1065); // Violet-950
  static const Color onPrimaryFixedVariant    = Color(0xFF4C1D95); // Violet-900
  static const Color onPrimaryContainer       = Color(0xFF3B0764); // Violet-950
  static const Color inversePrimary           = Color(0xFFA78BFA); // Violet-400
  static const Color surfaceTint              = Color(0xFF6D28D9);

  // ── Secondary — Amber Gold ────────────────────────────────────────────────
  static const Color secondary              = Color(0xFFD97706); // Amber-600
  static const Color secondaryDim           = Color(0xFFB45309); // Amber-700
  static const Color secondaryContainer     = Color(0xFFFEF3C7); // Amber-100
  static const Color secondaryFixed         = Color(0xFFFEF3C7);
  static const Color secondaryFixedDim      = Color(0xFFFDE68A); // Amber-200
  static const Color onSecondary            = Color(0xFFFFFFFF);
  static const Color onSecondaryFixed       = Color(0xFF78350F); // Amber-900
  static const Color onSecondaryFixedVariant= Color(0xFF92400E); // Amber-800
  static const Color onSecondaryContainer   = Color(0xFF78350F);

  // ── Tertiary — Ocean Teal ─────────────────────────────────────────────────
  static const Color tertiary              = Color(0xFF0891B2); // Cyan-600
  static const Color tertiaryDim           = Color(0xFF0E7490); // Cyan-700
  static const Color tertiaryContainer     = Color(0xFFCFFAFE); // Cyan-100
  static const Color tertiaryFixed         = Color(0xFFCFFAFE);
  static const Color tertiaryFixedDim      = Color(0xFFA5F3FC); // Cyan-200
  static const Color onTertiary            = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed       = Color(0xFF083344); // Cyan-950
  static const Color onTertiaryFixedVariant= Color(0xFF164E63); // Cyan-900
  static const Color onTertiaryContainer   = Color(0xFF083344);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error            = Color(0xFFDC2626); // Red-600
  static const Color errorDim         = Color(0xFFB91C1C); // Red-700
  static const Color errorContainer   = Color(0xFFFEE2E2); // Red-100
  static const Color onError          = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D); // Red-950

  // ── Surfaces — Violet Cream ───────────────────────────────────────────────
  /// Barely-tinted violet cream — الخلفية الرئيسية الراقية
  static const Color background              = Color(0xFFFAF5FF); // Violet-50
  static const Color surface                 = Color(0xFFFAF5FF);
  static const Color surfaceBright           = Color(0xFFFFFFFF);
  static const Color surfaceDim              = Color(0xFFF3E8FF); // Violet-100-ish
  static const Color surfaceVariant          = Color(0xFFF3E8FF);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFF5F3FF); // Violet-50-deep
  static const Color surfaceContainer        = Color(0xFFEDE9FE); // Violet-100
  static const Color surfaceContainerHigh    = Color(0xFFDDD6FE); // Violet-200
  static const Color surfaceContainerHighest = Color(0xFFC4B5FD); // Violet-300
  static const Color inverseSurface          = Color(0xFF2E1065); // Violet-950
  static const Color inverseOnSurface        = Color(0xFFF5F3FF); // Violet-50
  static const Color onSurface              = Color(0xFF1E1B4B); // Indigo-950
  static const Color onSurfaceVariant        = Color(0xFF4338CA); // Indigo-700 (readable violet)
  static const Color onBackground            = Color(0xFF1E1B4B);

  // ── Outlines ──────────────────────────────────────────────────────────────
  static const Color outline        = Color(0xFFDDD6FE); // Violet-200
  static const Color outlineVariant = Color(0xFFEDE9FE); // Violet-100

  /// نص placeholder داخل الحقول — واضح على الخلفية البيضاء/الكريمية.
  static const Color hintPlaceholder = Color(0xFF5B5678); // violet-gray ~4.5:1 on white

  // ── Progress ──────────────────────────────────────────────────────────────
  static const Color progressActive   = Color(0xFF6D28D9);
  static const Color progressInactive = Color(0xFFDDD6FE);

  // ── Language tile backgrounds (Royal pastels) ─────────────────────────────
  static const Color langEnglishBg    = Color(0xFFDBEAFE); // Blue-100
  static const Color langArabicBg     = Color(0xFFD1FAE5); // Emerald-100
  static const Color langFrenchBg     = Color(0xFFFCE7F3); // Pink-100
  static const Color langGermanBg     = Color(0xFFFEF3C7); // Amber-100
  static const Color langSpanishBg    = Color(0xFFFFEDD5); // Orange-100
  static const Color langTurkishBg    = Color(0xFFFFE4E6); // Rose-100
  static const Color langUrduBg       = Color(0xFFCFFAFE); // Cyan-100
  static const Color langIndonesianBg = Color(0xFFEDE9FE); // Violet-100

  // ── Subscription / plan badges ────────────────────────────────────────────
  static const Color planGoldBadge     = Color(0xFFF59E0B); // Amber-400
  static const Color planMonthlyText   = Color(0xFF1E1B4B);
  static const Color planMonthlySub    = Color(0xFF6D28D9);
  static const Color planBronzeText    = Color(0xFF78350F);
  static const Color planBronzeSub     = Color(0xFFB45309);
  static const Color planSilverText    = Color(0xFF1E3A5F);
  static const Color planSilverSub     = Color(0xFF3B82F6);
  static const Color planGoldText      = Color(0xFF78350F);
  static const Color planGoldSub       = Color(0xFFD97706);
  static const Color planBronzeStart   = Color(0xFFFEF3C7);
  static const Color planBronzeEnd     = Color(0xFFFDE68A);
  static const Color planSilverStart   = Color(0xFFE0F2FE);
  static const Color planSilverEnd     = Color(0xFFBAE6FD);
  static const Color planGoldStart     = Color(0xFFFEF9C3);
  static const Color planGoldEnd       = Color(0xFFFEF08A);

  // ── Age chips ─────────────────────────────────────────────────────────────
  static const Color ageWarmBg    = Color(0xFFFEF3C7); // Amber-100
  static const Color ageOrangeBg  = Color(0xFFFFEDD5); // Orange-100
  static const Color ageWarmText  = Color(0xFF1E1B4B);
  static const Color ageOrangeText= Color(0xFF1E1B4B);

  // ── Curriculum track accent colors (Royal variants) ───────────────────────
  static const Color trackQuranGold    = Color(0xFFD97706); // Amber-600
  static const Color trackQuranLight   = Color(0xFFFEF3C7); // Amber-100

  static const Color trackMathOrange   = Color(0xFFEA580C); // Orange-600
  static const Color trackMathLight    = Color(0xFFFFEDD5); // Orange-100

  static const Color trackVisualPurple = Color(0xFF7C3AED); // Violet-600
  static const Color trackVisualLight  = Color(0xFFEDE9FE); // Violet-100

  static const Color trackEmotionalRed = Color(0xFFDB2777); // Pink-600
  static const Color trackEmotionalLight = Color(0xFFFCE7F3); // Pink-100

  static const Color trackLibraryBlue  = Color(0xFF2563EB); // Blue-600
  static const Color trackLibraryLight = Color(0xFFDBEAFE); // Blue-100

  static const Color trackExerciseGreen= Color(0xFF16A34A); // Green-600
  static const Color trackExerciseLight= Color(0xFFDCFCE7); // Green-100

  // ── Gradients ────────────────────────────────────────────────────────────

  /// زر CTA الرئيسي — تدرج بنفسجي ملكي
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], // Violet-600 → Violet-700
  );

  /// خلفية الـ scaffold — بنفسجي كريمي شفاف
  static const LinearGradient warmBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAF5FF), // Violet-50
      Color(0xFFF5F3FF), // slightly deeper
    ],
  );

  /// Hero gradient — بنفسجي + ذهبي
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEDE9FE), // Violet-100
      Color(0xFFFEF3C7), // Amber-100
    ],
  );

  // ── BeBo marketing / splash ───────────────────────────────────────────────
  static const Color beboSplashPurple      = Color(0xFF6D28D9); // Royal primary
  static const Color beboSplashPurpleDeep  = Color(0xFF4C1D95);
  static const Color beboTealWave          = Color(0xFF0891B2); // Teal tertiary
  static const Color beboMarketingPurple   = Color(0xFF7C3AED);
  static const Color beboMarketingPurpleDim= Color(0xFF6D28D9);
  static const Color beboIndigoHeading     = Color(0xFF4338CA);
  static const Color beboLavenderCta       = Color(0xFFA78BFA); // Violet-400
  static const Color beboLavenderCtaDeep   = Color(0xFF8B5CF6); // Violet-500
  static const Color beboTealOnboarding    = Color(0xFF0891B2);

  static const LinearGradient beboPurpleCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [beboMarketingPurple, beboMarketingPurpleDim],
  );

  static const LinearGradient beboLavenderCtaGradient = LinearGradient(
    colors: [beboLavenderCta, beboLavenderCtaDeep],
  );
}
