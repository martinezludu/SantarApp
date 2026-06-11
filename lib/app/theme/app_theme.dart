import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.ember,
    onPrimary: AppColors.surface900,
    primaryContainer: AppColors.emberDim,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.emberGlow,
    onSecondary: AppColors.surface900,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface900,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface900,
    surfaceContainerLow: AppColors.surface800,
    surfaceContainer: AppColors.surface800,
    surfaceContainerHigh: AppColors.surface700,
    surfaceContainerHighest: AppColors.surface600,
    outline: AppColors.surface600,
    outlineVariant: AppColors.surface700,
  );

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ember,
    onPrimary: Colors.white,
    primaryContainer: AppColors.emberGlow,
    onPrimaryContainer: AppColors.surface900,
    secondary: AppColors.emberDim,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.lightBg,
    onSurface: AppColors.lightTextPrimary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.lightSurface,
    surfaceContainer: AppColors.lightSurface,
    surfaceContainerHigh: AppColors.lightSurfaceAlt,
    surfaceContainerHighest: Color(0xFFE2E2EA),
    outline: Color(0xFFCFCFDA),
    outlineVariant: Color(0xFFE2E2EA),
  );

  static ThemeData get dark => _build(_darkScheme);
  static ThemeData get light => _build(_lightScheme);

  static ThemeData _build(ColorScheme s) {
    final textTheme = AppTextStyles.textTheme(s.onSurface, s.onSurfaceVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      scaffoldBackgroundColor: s.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        labelStyle: textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        prefixIconColor: s.onSurfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.ember, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.ember),
      ),
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
