import 'package:flutter/material.dart';

/// Oyunun renkleri. Paylaşım kartı da aynılarını kullanır.
abstract final class AppColors {
  static const Color paper = Color(0xFFFFF8F0);
  static const Color cardPaper = Color(0xFFFFFDF9);
  static const Color ink = Color(0xFF2B1D16);
  static const Color muted = Color(0xFF7A6458);
  static const Color accent = Color(0xFFC0392B);
  static const Color legendary = Color(0xFFD4A017);

  static const Color nightPaper = Color(0xFF1F1915);
  static const Color nightCard = Color(0xFF2A221D);
  static const Color nightInk = Color(0xFFF3E9DF);
}

/// Gömülü yazı tipi (OFL lisanslı, `assets/fonts/OFL.txt`).
const String appFontFamily = 'Nunito';

ThemeData buildAppTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: light ? AppColors.accent : base.primary,
    surface: light ? AppColors.paper : AppColors.nightPaper,
    onSurface: light ? AppColors.ink : AppColors.nightInk,
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: appFontFamily,
    // Hazır metin teması kendi yazı tipi adını taşır; Nunito açıkça uygulanır.
    textTheme: _boldHeadings(ThemeData(brightness: brightness).textTheme)
        .apply(fontFamily: appFontFamily),
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: light ? AppColors.cardPaper : AppColors.nightCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: (light ? AppColors.muted : AppColors.nightInk).withValues(
            alpha: 0.18,
          ),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// Nunito ince durduğu için başlıklar kalın.
TextTheme _boldHeadings(TextTheme t) => t.copyWith(
  displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800),
  headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
  headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
  titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
);
