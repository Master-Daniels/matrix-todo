import 'package:flutter/material.dart';

import '../theme/app_borders.dart';

/// Square 22x22 selection control, 0px radius.
/// Checked = solid fill with sharp `X` (Space Mono), not a curve.
/// [inverted] renders for black backgrounds (white box / black X).
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool inverted;

  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final edge = inverted ? scheme.onPrimary : scheme.primary;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: value
              ? edge
              : (inverted ? Colors.transparent : scheme.surfaceContainerLowest),
          border: Border.all(color: edge, width: 1),
          borderRadius: AppBorders.zero,
        ),
        alignment: Alignment.center,
        child: value
            ? Text(
                'X',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: inverted ? scheme.primary : scheme.onPrimary,
                ),
              )
            : null,
      ),
    );
  }
}
