import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.deepWater,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.waterLight,
    onPrimaryContainer: AppColors.navy,
    secondary: AppColors.sage,
    onSecondary: AppColors.navy,
    secondaryContainer: AppColors.sageLight,
    onSecondaryContainer: AppColors.navy,
    tertiary: AppColors.peach,
    onTertiary: AppColors.navy,
    tertiaryContainer: AppColors.peachLight,
    onTertiaryContainer: AppColors.navy,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.navy,
    surface: AppColors.foam,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.outline,
    outlineVariant: AppColors.waterLight,
    shadow: AppColors.navy,
    scrim: AppColors.navy,
    inverseSurface: AppColors.navy,
    onInverseSurface: AppColors.foam,
    inversePrimary: AppColors.waterLight,
    surfaceTint: AppColors.water,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.waterLight,
    onPrimary: AppColors.navy,
    primaryContainer: AppColors.deepWater,
    onPrimaryContainer: AppColors.foam,
    secondary: AppColors.sage,
    onSecondary: AppColors.navy,
    secondaryContainer: AppColors.nightSurfaceHigh,
    onSecondaryContainer: AppColors.sageLight,
    tertiary: AppColors.peach,
    onTertiary: AppColors.navy,
    tertiaryContainer: AppColors.nightSurfaceHigh,
    onTertiaryContainer: AppColors.peachLight,
    error: AppColors.errorContainer,
    onError: AppColors.navy,
    errorContainer: AppColors.error,
    onErrorContainer: AppColors.white,
    surface: AppColors.night,
    onSurface: AppColors.nightInk,
    onSurfaceVariant: AppColors.nightInkMuted,
    outline: AppColors.nightOutline,
    outlineVariant: AppColors.nightSurfaceHigh,
    shadow: AppColors.night,
    scrim: AppColors.night,
    inverseSurface: AppColors.nightInk,
    onInverseSurface: AppColors.night,
    inversePrimary: AppColors.deepWater,
    surfaceTint: AppColors.water,
  );

  static ThemeData _build(ColorScheme colors) {
    final textTheme = TextTheme(
      displaySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displaySize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleSize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySize,
        height: AppTypography.bodyHeight,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSize,
        height: AppTypography.bodyHeight,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSize,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        color: colors.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colors.brightness == Brightness.light
            ? AppColors.navy
            : AppColors.nightSurface,
        foregroundColor: colors.brightness == Brightness.light
            ? AppColors.white
            : AppColors.nightInk,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.brightness == Brightness.light
              ? AppColors.white
              : AppColors.nightInk,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
