import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF006C49);
  static const onPrimary = Colors.white;
  static const primaryContainer = Color(0xFF10B981);
  static const onPrimaryContainer = Color(0xFF00422B);
  static const secondary = Color(0xFF545F73);
  static const onSecondary = Colors.white;
  static const secondaryContainer = Color(0xFFD5E0F8);
  static const onSecondaryContainer = Color(0xFF586377);
  static const tertiary = Color(0xFF505F76);
  static const onTertiary = Colors.white;
  static const tertiaryContainer = Color(0xFF94A4BD);
  static const onTertiaryContainer = Color(0xFF2A3A4F);
  static const background = Color(0xFFF4FBF4);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFDDE4DD);
  static const onSurface = Color(0xFF161D19);
  static const onSurfaceVariant = Color(0xFF3C4A42);
  static const outline = Color(0xFF6C7A71);
  static const outlineVariant = Color(0xFFBBCABF);
  static const error = Color(0xFFBA1A1A);
  static const onError = Colors.white;
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const surfaceTint = Color(0xFF006C49);
  static const cardBorder = Color(0xFFE2E8F0);
  static const formFill = Color(0xFFF8FAFC);
  static const mutedText = Color(0xFF64748B);
  static const successContainer = Color(0xFFDCFCE7);
  static const dangerContainer = Color(0xFFFEE2E2);
}

class AppTheme {
  static ThemeData get themeData {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      shadow: Color(0x0F1E293B),
      inverseSurface: Color(0xFF2B322D),
      onInverseSurface: Color(0xFFEBF3EB),
      inversePrimary: Color(0xFF4EDEA3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        surfaceTintColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: const Color(0x0F1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.formFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        elevation: 4,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            height: 56 / 48,
            color: AppColors.onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01,
            height: 40 / 32,
            color: AppColors.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32 / 24,
            color: AppColors.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            height: 28 / 18,
            color: AppColors.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: AppColors.onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
            letterSpacing: 0.01,
            color: AppColors.secondary,
          ),
          labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
            color: AppColors.secondary,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    );
  }
}
