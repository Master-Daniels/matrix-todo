import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppBorders {
  static const Radius zeroRadius = Radius.zero;
  static const BorderRadius zero = BorderRadius.zero;

  /// Legacy light-mode constants. Prefer the scheme-aware helpers below
  /// ([thinFor], [thickFor], ...) so borders flip with [ThemeMode.system].
  static const BorderSide thin = BorderSide(color: AppColors.primary, width: 1);
  static const BorderSide thick = BorderSide(
    color: AppColors.primary,
    width: 2,
  );
  static const BorderSide thinWhite = BorderSide(
    color: AppColors.onPrimary,
    width: 1,
  );

  static BoxBorder get allThin => Border.all(color: AppColors.primary);
  static BoxBorder get topThick =>
      const Border(top: BorderSide(color: AppColors.primary, width: 2));

  // ---- Scheme-aware helpers (dark-mode safe) ----
  static BorderSide thinFor(ColorScheme scheme) =>
      BorderSide(color: scheme.primary, width: 1);
  static BorderSide thickFor(ColorScheme scheme) =>
      BorderSide(color: scheme.primary, width: 2);
  static BorderSide onPrimaryThinFor(ColorScheme scheme) =>
      BorderSide(color: scheme.onPrimary, width: 1);

  static BoxBorder allThinFor(ColorScheme scheme) =>
      Border.all(color: scheme.primary);
  static BoxBorder topThickFor(ColorScheme scheme) =>
      Border(top: BorderSide(color: scheme.primary, width: 2));

  static const RoundedRectangleBorder sharpRectangle = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static ShapeBorder outlinedSharp({BorderSide side = thin}) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: side);
  }

  static OutlinedBorder outlinedBorder({BorderSide side = thin}) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: side);
  }
}
