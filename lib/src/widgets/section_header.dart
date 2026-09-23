import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ledger section bar: uppercase mono title + right-aligned index
/// (e.g. `[SEC 01]`), 1px top/bottom rules.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? index;
  final bool inverted;

  const SectionHeader({
    super.key,
    required this.title,
    this.index,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = inverted ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = inverted ? scheme.onPrimary : scheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 1),
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (index != null)
              Text(
                index!,
                style: AppTypography.indexIndicator(context, color: fg),
              ),
          ],
        ),
      ),
    );
  }
}
