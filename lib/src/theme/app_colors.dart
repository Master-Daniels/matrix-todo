import 'package:flutter/material.dart';

/// Monochrome  palette from `design/DESIGN.md`.
///
/// Core rule: color never signals state — state is binary inversion
/// (white-on-black), border-weight emphasis, or strikethrough.
abstract final class AppColors {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Core surfaces
  static const surface = Color(0xFFF9F9F9);
  static const surfaceDim = Color(0xFFDADADA);
  static const surfaceBright = Color(0xFFF9F9F9);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF3F3F4);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceHigh = Color(0xFFE8E8E8);
  static const surfaceHighest = Color(0xFFE2E2E2);
  static const surfaceVariant = Color(0xFFE2E2E2);

  // On-surfaces (darkened for body/metadata legibility on white)
  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF2F3033);
  static const inverseSurface = Color(0xFF2F3131);
  static const inverseOnSurface = Color(0xFFF0F1F1);

  // Primary (structural anchor)
  static const primary = Color(0xFF000000);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1B1B1B);
  static const onPrimaryContainer = Color(0xFF848484);
  static const inversePrimary = Color(0xFFC6C6C6);

  // Secondary / tertiary (darkened: secondary is the app-wide muted
  // text tone — metadata, hints, unselected states — on white surfaces)
  static const secondary = Color(0xFF3B3C44);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE3E1EC);
  static const onSecondaryContainer = Color(0xFF43444C);
  static const tertiary = Color(0xFF000000);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF1A1C1D);
  static const onTertiaryContainer = Color(0xFF838485);

  // Outlines
  static const outline = Color(0xFF7E7576);
  static const outlineVariant = Color(0xFFCFC4C5);
  static const surfaceTint = Color(0xFF5E5E5E);

  // Error (only non-mono accent permitted)
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Fixed tones (kept for spec completeness via extension)
  static const primaryFixed = Color(0xFFE2E2E2);
  static const primaryFixedDim = Color(0xFFC6C6C6);
  static const onPrimaryFixed = Color(0xFF1B1B1B);
  static const onPrimaryFixedVariant = Color(0xFF474747);
  static const secondaryFixed = Color(0xFFE3E1EC);
  static const secondaryFixedDim = Color(0xFFC6C5CF);
  static const onSecondaryFixed = Color(0xFF1A1B22);
  static const onSecondaryFixedVariant = Color(0xFF46464E);
  static const tertiaryFixed = Color(0xFFE2E2E3);
  static const tertiaryFixedDim = Color(0xFFC6C6C7);
  static const onTertiaryFixed = Color(0xFF1A1C1D);
  static const onTertiaryFixedVariant = Color(0xFF454748);

  static const background = Color(0xFFF9F9F9);
  static const onBackground = Color(0xFF1A1C1C);

  // ---- Dark (inverted ) ----
  // Rule preserved: white structural lines on near-black surfaces,
  // state = inversion (black-on-white), border weight, strikethrough.
  static const darkSurface = Color(0xFF0A0A0A);
  static const darkSurfaceDim = Color(0xFF0A0A0A);
  static const darkSurfaceBright = Color(0xFF2B2B2B);
  static const darkSurfaceLowest = Color(0xFF000000);
  static const darkSurfaceLow = Color(0xFF131313);
  static const darkSurfaceContainer = Color(0xFF1A1A1A);
  static const darkSurfaceHigh = Color(0xFF222222);
  static const darkSurfaceHighest = Color(0xFF2B2B2B);
  static const darkSurfaceVariant = Color(0xFF2B2B2B);

  static const darkOnSurface = Color(0xFFF5F5F5);
  static const darkOnSurfaceVariant = Color(0xFFB8B8B8);
  static const darkInverseSurface = Color(0xFFF9F9F9);
  static const darkInverseOnSurface = Color(0xFF1A1C1C);

  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkOnPrimary = Color(0xFF000000);
  static const darkPrimaryContainer = Color(0xFFE8E8E8);
  static const darkOnPrimaryContainer = Color(0xFF2A2A2A);
  static const darkInversePrimary = Color(0xFF646464);

  static const darkSecondary = Color(0xFFA8A9B3);
  static const darkOnSecondary = Color(0xFF000000);
  static const darkSecondaryContainer = Color(0xFF2A2A2E);
  static const darkOnSecondaryContainer = Color(0xFFC5C6CE);
  static const darkTertiary = Color(0xFFFFFFFF);
  static const darkOnTertiary = Color(0xFF000000);
  static const darkTertiaryContainer = Color(0xFF2A2A2A);
  static const darkOnTertiaryContainer = Color(0xFFB0B0B0);

  static const darkOutline = Color(0xFF8A8A8A);
  static const darkOutlineVariant = Color(0xFF3A3A3A);
  static const darkSurfaceTint = Color(0xFFD0D0D0);

  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  static const darkBackground = Color(0xFF0A0A0A);
  static const darkOnBackground = Color(0xFFF5F5F5);

  /// Canonical light [ColorScheme] for the  system.
  static ColorScheme get lightScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceHighest,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainer: surfaceContainer,
    surfaceContainerLow: surfaceLow,
    surfaceContainerLowest: surfaceLowest,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
  );

  /// Inverted  [ColorScheme]: white structure on near-black.
  static ColorScheme get darkScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkTertiary,
    onTertiary: darkOnTertiary,
    tertiaryContainer: darkTertiaryContainer,
    onTertiaryContainer: darkOnTertiaryContainer,
    error: darkError,
    onError: darkOnError,
    errorContainer: darkErrorContainer,
    onErrorContainer: darkOnErrorContainer,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceHighest,
    surfaceContainerHigh: darkSurfaceHigh,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerLow: darkSurfaceLow,
    surfaceContainerLowest: darkSurfaceLowest,
    surfaceDim: darkSurfaceDim,
    surfaceBright: darkSurfaceBright,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    inverseSurface: darkInverseSurface,
    onInverseSurface: darkInverseOnSurface,
    inversePrimary: darkInversePrimary,
    surfaceTint: darkSurfaceTint,
  );
}

/// Extra fixed/dim tones that don't fit [ColorScheme].
@immutable
class AppFixedColors extends ThemeExtension<AppFixedColors> {
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixed;
  final Color onTertiaryFixedVariant;

  const AppFixedColors({
    this.primaryFixed = AppColors.primaryFixed,
    this.primaryFixedDim = AppColors.primaryFixedDim,
    this.onPrimaryFixed = AppColors.onPrimaryFixed,
    this.onPrimaryFixedVariant = AppColors.onPrimaryFixedVariant,
    this.secondaryFixed = AppColors.secondaryFixed,
    this.secondaryFixedDim = AppColors.secondaryFixedDim,
    this.onSecondaryFixed = AppColors.onSecondaryFixed,
    this.onSecondaryFixedVariant = AppColors.onSecondaryFixedVariant,
    this.tertiaryFixed = AppColors.tertiaryFixed,
    this.tertiaryFixedDim = AppColors.tertiaryFixedDim,
    this.onTertiaryFixed = AppColors.onTertiaryFixed,
    this.onTertiaryFixedVariant = AppColors.onTertiaryFixedVariant,
  });

  @override
  AppFixedColors copyWith({
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
  }) {
    return AppFixedColors(
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      onPrimaryFixedVariant:
          onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      onSecondaryFixedVariant:
          onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      onTertiaryFixedVariant:
          onTertiaryFixedVariant ?? this.onTertiaryFixedVariant,
    );
  }

  @override
  AppFixedColors lerp(ThemeExtension<AppFixedColors>? other, double t) {
    if (other is! AppFixedColors) return this;
    return AppFixedColors(
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      primaryFixedDim: Color.lerp(primaryFixedDim, other.primaryFixedDim, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      onPrimaryFixedVariant: Color.lerp(
        onPrimaryFixedVariant,
        other.onPrimaryFixedVariant,
        t,
      )!,
      secondaryFixed: Color.lerp(secondaryFixed, other.secondaryFixed, t)!,
      secondaryFixedDim: Color.lerp(
        secondaryFixedDim,
        other.secondaryFixedDim,
        t,
      )!,
      onSecondaryFixed: Color.lerp(
        onSecondaryFixed,
        other.onSecondaryFixed,
        t,
      )!,
      onSecondaryFixedVariant: Color.lerp(
        onSecondaryFixedVariant,
        other.onSecondaryFixedVariant,
        t,
      )!,
      tertiaryFixed: Color.lerp(tertiaryFixed, other.tertiaryFixed, t)!,
      tertiaryFixedDim: Color.lerp(
        tertiaryFixedDim,
        other.tertiaryFixedDim,
        t,
      )!,
      onTertiaryFixed: Color.lerp(onTertiaryFixed, other.onTertiaryFixed, t)!,
      onTertiaryFixedVariant: Color.lerp(
        onTertiaryFixedVariant,
        other.onTertiaryFixedVariant,
        t,
      )!,
    );
  }
}
