import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/app_page_transitions.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => lightFor(const Locale('en'));
  static ThemeData get dark => darkFor(const Locale('en'));

  static ThemeData lightFor(
    Locale locale, {
    bool applyGoogleFonts = true,
  }) => _build(_lightScheme, locale, applyGoogleFonts);

  static ThemeData darkFor(
    Locale locale, {
    bool applyGoogleFonts = true,
  }) => _build(_darkScheme, locale, applyGoogleFonts);

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

  static ThemeData _build(
    ColorScheme colors,
    Locale locale,
    bool applyGoogleFonts,
  ) {
    final defaults = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
    ).textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    final baseTextTheme = defaults.copyWith(
      displaySmall: defaults.displaySmall?.copyWith(
        fontSize: AppTypography.displaySize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      headlineMedium: defaults.headlineMedium?.copyWith(
        fontSize: AppTypography.headlineSize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      titleLarge: defaults.titleLarge?.copyWith(
        fontSize: AppTypography.titleSize,
        height: AppTypography.tightHeight,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      bodyLarge: defaults.bodyLarge?.copyWith(
        fontSize: AppTypography.bodySize,
        height: AppTypography.bodyHeight,
        color: colors.onSurface,
      ),
      bodyMedium: defaults.bodyMedium?.copyWith(
        fontSize: AppTypography.labelSize,
        height: AppTypography.bodyHeight,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: defaults.labelLarge?.copyWith(
        fontSize: AppTypography.labelSize,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      labelSmall: defaults.labelSmall?.copyWith(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        color: colors.onSurfaceVariant,
      ),
    );
    final textTheme = applyGoogleFonts
        ? locale.languageCode == 'ar'
              ? GoogleFonts.notoSansArabicTextTheme(baseTextTheme)
              : GoogleFonts.notoSansTextTheme(baseTextTheme)
        : baseTextTheme.apply(fontFamily: AppTypography.familyFor(locale));

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
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}
