import 'package:flutter/material.dart';

import '../../../theme/app_typography.dart';

/// Mono section header: grey uppercase label left, optional index right
/// (e.g. `REQ*`, `SELECT ONE`, `STATE: LVL-3`).
class SectionLabel extends StatelessWidget {
  final String left;
  final String? right;
  final bool boldRight;

  const SectionLabel(
    this.left, {
    super.key,
    this.right,
    this.boldRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            left,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        if (right != null)
          Text(
            right!,
            style:
                (boldRight
                        ? AppTypography.indexIndicator(context)
                        : theme.textTheme.labelSmall)
                    ?.copyWith(
                      color: boldRight
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      fontWeight: boldRight ? FontWeight.w700 : null,
                    ),
          ),
      ],
    );
  }
}
