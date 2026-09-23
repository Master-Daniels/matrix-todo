/// Spacing rhythm from `design/DESIGN.md`.
///
/// `space-xs/sm` for badge internals, `space-md` for task rows/inputs,
/// `space-lg` for hero blocks, `space-xl` for terminal action zones.
/// Outer gutters/margins are 0 (edge-to-edge contiguous grid).
abstract final class AppSpacing {
  static const double gutter = 0;
  static const double margin = 0;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
