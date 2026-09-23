import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Hero sub-header from daily_to_do_focus: mono kicker row +
/// Megrim headline. Static copy for v1.
class HomeHero extends StatelessWidget {
  final String kicker;
  final String weekday;

  const HomeHero({
    super.key,
    this.kicker = 'DAILY HABITS & ROUTINES',
    this.weekday = 'TUESDAY',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  kicker.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
              ),
              Text(
                weekday.toUpperCase(),
                style: AppTypography.indexIndicator(
                  context,
                  color: scheme.primary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'FOCUS ON WHAT MATTERS. KEEP IT SIMPLE, MAKE IT COUNT.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
