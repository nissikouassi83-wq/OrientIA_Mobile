import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final themeNotifier = ValueNotifier<bool>(true); // toujours dark

class AppColors {
  // Fonds
  static const Color bg       = Color(0xFF0D1117);
  static const Color bgCard   = Color(0xFF161B22);
  static const Color card     = Color(0xFF1C2128);

  // Accents
  static const Color accent   = Color(0xFFF97316); // orange
  static const Color violet   = Color(0xFF8B5CF6); // violet
  static const Color green    = Color(0xFF10B981); // succès
  static const Color red      = Color(0xFFEF4444); // alerte

  // Texte
  static const Color ink      = Color(0xFFF0F6FC);
  static const Color muted    = Color(0xFF8B949E);

  // Bordure
  static const Color line     = Color(0xFF30363D);

  // Aliases de compatibilité (const pour usage dans LinearGradient const)
  static const Color teal        = violet;
  static const Color error       = red;
  static const Color success     = green;
  static Color get surface       => bg;
  static Color get accentSoft    => accent.withValues(alpha: 0.15);
  static Color get tealSoft      => violet.withValues(alpha: 0.15);
  static Color get cardElevated  => bgCard;
  static Color get inkSoft       => ink;
}

class AppTheme {
  static ThemeData get dark  => _build();
  static ThemeData get light => _build();

  static ThemeData _build() {
    const bg    = AppColors.bg;
    const cardC = AppColors.card;
    const onSurf= AppColors.ink;
    const mutedC= AppColors.muted;
    const lineC = AppColors.line;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        secondary: AppColors.violet,
        surface: cardC,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurf,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: cardC,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurf,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: onSurf, fontWeight: FontWeight.w700, fontSize: 18,
        ),
        iconTheme: IconThemeData(color: onSurf),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardC,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lineC),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lineC),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: mutedC),
        hintStyle: const TextStyle(color: mutedC),
        prefixIconColor: mutedC,
      ),
      cardTheme: CardThemeData(
        color: cardC,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lineC),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lineC),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: onSurf, fontWeight: FontWeight.w800, fontSize: 32),
        headlineLarge: TextStyle(color: onSurf, fontWeight: FontWeight.w700, fontSize: 28),
        headlineMedium:TextStyle(color: onSurf, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge:    TextStyle(color: onSurf, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium:   TextStyle(color: onSurf, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:     TextStyle(color: onSurf, fontSize: 16),
        bodyMedium:    TextStyle(color: mutedC, fontSize: 14),
        bodySmall:     TextStyle(color: mutedC, fontSize: 12),
        labelLarge:    TextStyle(color: onSurf, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardC,
        contentTextStyle: const TextStyle(color: onSurf),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
