import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographic identity: geometric Megrim for headings/body,
/// technical Space Mono (uppercase) for labels/indices/metadata.
///
/// Fonts resolve in this order: bundled `assets/fonts` (see `pubspec.yaml`
/// `fonts:` + `assets/fonts/README.md`) first, Google Fonts runtime cache
/// second (warmed at startup via [precache]). No per-paint fetching.
abstract final class AppTypography {
  static String get displayFamily => 'Megrim';
  static String get monoFamily => 'Space Mono';

  /// Warm the font cache before first paint. Call once in `main()` after
  /// `WidgetsFlutterBinding.ensureInitialized()`. Resolves instantly once
  /// the `.ttf` files are bundled.
  static Future<void> precache() => GoogleFonts.pendingFonts([
    GoogleFonts.megrim(),
    GoogleFonts.spaceMono(),
    GoogleFonts.spaceMono(fontWeight: FontWeight.w700),
    GoogleFonts.spaceMono(
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    ),
  ]);

  static final TextStyle _megrimBase = TextStyle(fontFamily: 'Megrim');
  static final TextStyle _monoBase = TextStyle(fontFamily: 'Space Mono');

  static TextTheme textTheme(ColorScheme scheme) {
    final megrim = _megrimBase;
    final mono = _monoBase;

    TextStyle scaled(
      TextStyle? base, {
      required double size,
      required double height,
      required FontWeight weight,
      required double letterSpacing,
      Color? color,
    }) {
      return (base ?? const TextStyle()).copyWith(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: letterSpacing * size,
        color: color ?? scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge: scaled(
        megrim,
        size: 40,
        height: 44,
        weight: FontWeight.w700,
        letterSpacing: -0.04,
      ),
      headlineLarge: scaled(
        megrim,
        size: 28,
        height: 32,
        weight: FontWeight.w600,
        letterSpacing: -0.03,
      ),
      headlineMedium: scaled(
        megrim,
        size: 22,
        height: 26,
        weight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
      headlineSmall: scaled(
        megrim,
        size: 18,
        height: 22,
        weight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      bodyLarge: scaled(
        megrim,
        size: 16,
        height: 22,
        weight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: scaled(
        megrim,
        size: 14,
        height: 20,
        weight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: scaled(
        megrim,
        size: 12,
        height: 16,
        weight: FontWeight.w400,
        letterSpacing: 0.01,
      ),
      labelLarge: scaled(
        mono,
        size: 13,
        height: 16,
        weight: FontWeight.w700,
        letterSpacing: 0.08,
      ),
      labelMedium: scaled(
        mono,
        size: 11,
        height: 14,
        weight: FontWeight.w400,
        letterSpacing: 0.06,
      ),
      labelSmall: scaled(
        mono,
        size: 10,
        height: 12,
        weight: FontWeight.w400,
        letterSpacing: 0.08,
      ),
    );
  }

  /// `index-indicator`: Space Mono 11/11 w700 +10%, e.g. `01`, `[OK]`.
  static TextStyle indexIndicator(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: 11,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: color ?? scheme.onSurface,
    );
  }
}
