import 'package:flutter/material.dart';

import 'app_borders.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the  [ThemeData]: monochrome scheme, Megrim +
/// Space Mono type, zero radius, zero elevation, 1px structural borders.
///
/// Both [light] and [dark] share [_build] so structural styling stays
/// identical — only the [ColorScheme] flips (black-on-white vs
/// white-on-near-black). Pair with `ThemeMode.system` in [MaterialApp].
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.lightScheme);

  static ThemeData dark() => _build(AppColors.darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final text = AppTypography.textTheme(scheme);

    final thin = BorderSide(color: scheme.primary, width: 1);
    final thick = BorderSide(color: scheme.primary, width: 2);

    InputBorder inputBorder(BorderSide side) =>
        OutlineInputBorder(borderRadius: AppBorders.zero, borderSide: side);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      // Zero shadows globally.
      shadowColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        shape: Border(bottom: thin),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.onPrimary,
        unselectedItemColor: scheme.secondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: AppBorders.outlinedBorder(side: thin),
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.surfaceContainerLowest,
          side: thin,
          shape: AppBorders.sharpRectangle,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: AppBorders.sharpRectangle,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(16),
        border: inputBorder(thin),
        enabledBorder: inputBorder(thin),
        focusedBorder: inputBorder(thick),
        disabledBorder: inputBorder(thin),
        errorBorder: inputBorder(BorderSide(color: scheme.error, width: 1)),
        focusedErrorBorder: inputBorder(
          BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: text.labelSmall,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.secondary),
        errorStyle: text.labelSmall?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w700,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: AppBorders.sharpRectangle,
        side: thin,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerLowest;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: AppBorders.outlinedBorder(side: thin),
        labelStyle: text.labelSmall,
        side: thin,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(top: BorderSide(color: scheme.primary, width: 2)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: AppBorders.outlinedSharp(side: thin),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.primary,
        thickness: 1,
        space: 0,
      ),
      extensions: const [AppFixedColors()],
    );
  }
}
