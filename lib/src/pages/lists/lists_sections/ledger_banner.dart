import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../lists_providers.dart';

/// `SYSTEM LEDGER // V.xx` banner with live list/task counts,
/// completion badge and sync badge.
class LedgerBanner extends ConsumerWidget {
  const LedgerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = ref.watch(listsSummaryProvider);

    final lists = summary.maybeWhen(data: (s) => s.lists, orElse: () => 0);
    final tasks = summary.maybeWhen(data: (s) => s.tasks, orElse: () => 0);
    final done = summary.maybeWhen(data: (s) => s.completed, orElse: () => 0);
    final pct = tasks == 0 ? 0.0 : done / tasks * 100;
    final pctLabel =
        'COMPLETION: ${pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1)}%';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SYSTEM LEDGER // V.04',
                style: AppTypography.indexIndicator(
                  context,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$lists ACTIVE LISTS // $tasks TOTAL TASKS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Text(
                  pctLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: scheme.primary,
                child: Text(
                  'SYNCED [OK]',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
