import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_borders.dart';

/// Square 22x22 selection control, 0px radius.
/// Checked = solid fill with sharp `X` (Space Mono), not a curve.
/// [inverted] renders for black backgrounds (white box / black X).
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool inverted;
  final String? semanticLabel;

  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.inverted = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final edge = inverted ? scheme.onPrimary : scheme.primary;
    return Semantics(
      checked: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged != null
            ? () {
                if (!value) {
                  HapticFeedback.mediumImpact();
                } else {
                  HapticFeedback.selectionClick();
                }
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value
                  ? edge
                  : (inverted
                      ? Colors.transparent
                      : scheme.surfaceContainerLowest),
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
        ),
      ),
    );
  }
}
