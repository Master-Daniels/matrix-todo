import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../home_providers.dart';

/// Progress ledger: left daily counts + status, right 3x3 matrix,
/// bottom COMPLETED / REMAINING / STREAK strip.
class HomeProgressBlock extends ConsumerWidget {
  const HomeProgressBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = ref.watch(todayCountsProvider);

    final total = counts.maybeWhen(data: (d) => d.total, orElse: () => 0);
    final completed =
        counts.maybeWhen(data: (d) => d.completed, orElse: () => 0);
    final remaining =
        counts.maybeWhen(data: (d) => d.remaining, orElse: () => 0);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    color: scheme.surfaceContainerLowest,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY PROGRESS',
                              style: AppTypography.indexIndicator(
                                context,
                                color: scheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completed OF $total DONE',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$remaining TASKS LEFT FOR TODAY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: scheme.primary,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'STATUS:',
                                style: theme.textTheme.labelSmall,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                color: scheme.primary,
                                child: Text(
                                  remaining == 0 && total > 0
                                      ? 'CLEAR'
                                      : 'ON TRACK',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: scheme.primary, width: 1),
                      ),
                    ),
                    child: _MatrixGrid(
                      completed: completed,
                      total: total,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            child: Row(
              children: [
                _StatCell(
                  label: 'COMPLETED',
                  value: completed.toString().padLeft(2, '0'),
                ),
                _StatCell(
                  label: 'REMAINING',
                  value: remaining.toString().padLeft(2, '0'),
                ),
                const _StatCell(label: 'STREAK', value: '7 DAYS'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixGrid extends StatelessWidget {
  final int completed;
  final int total;

  const _MatrixGrid({required this.completed, required this.total});

  Widget _cell(BuildContext context, int i) {
    final scheme = Theme.of(context).colorScheme;
    final done = i < completed;
    final pending = !done && i < total;
    final bg = done
        ? scheme.primary
        : pending
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerHigh;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              right: BorderSide(
                color: scheme.primary,
                width: i % 3 == 2 ? 0 : 1,
              ),
              bottom: BorderSide(
                color: scheme.primary,
                width: i >= 6 ? 0 : 1,
              ),
            ),
          ),
          child: Center(
            child: done
                ? Text(
                    '✓',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                : pending
                    ? Container(
                        width: 8,
                        height: 8,
                        color: scheme.primary,
                      )
                    : Text(
                        '-',
                        style: AppTypography.indexIndicator(
                          context,
                          color: scheme.secondary,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [_cell(context, 0), _cell(context, 1), _cell(context, 2)]),
        Row(children: [_cell(context, 3), _cell(context, 4), _cell(context, 5)]),
        Row(children: [_cell(context, 6), _cell(context, 7), _cell(context, 8)]),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        color: scheme.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.indexIndicator(
                context,
                color: scheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value.toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
