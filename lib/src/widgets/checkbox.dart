import 'package:flutter/material.dart';

import '../theme/app_borders.dart';

/// Square 18x18 selection control, 0px radius.
/// Checked = solid black fill with sharp `X` (Space Mono), not a curve.
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomCheckbox({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.primary, width: 1),
          borderRadius: AppBorders.zero,
        ),
        alignment: Alignment.center,
        child: value
            ? Text(
                'X',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary,
                ),
              )
            : null,
      ),
    );
  }
}
