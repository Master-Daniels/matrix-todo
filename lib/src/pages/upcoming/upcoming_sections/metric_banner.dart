import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../upcoming_providers.dart';

/// 4-cell KPI matrix: total scheduled, due tomorrow, overdue blocks,
/// execution capacity (done ratio). 2×2 on phones, 4-across when wide.
class MetricBanner extends ConsumerWidget {
  const MetricBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(upcomingMetricsProvider);
    final total = m.maybeWhen(data: (v) => v.total, orElse: () => 0);
    final dueTomorrow =
        m.maybeWhen(data: (v) => v.dueTomorrow, orElse: () => 0);
    final overdue = m.maybeWhen(data: (v) => v.overdue, orElse: () => 0);
    final capacity =
        m.maybeWhen(data: (v) => v.capacityPct, orElse: () => 0);

    final cells = [
      _MetricCell(
        index: 'METRIC // 01',
        value: '$total'.padLeft(2, '0'),
        label: 'TOTAL SCHEDULED',
      ),
      _MetricCell(
        index: 'METRIC // 02',
        value: '$dueTomorrow'.padLeft(2, '0'),
        label: 'DUE TOMORROW',
      ),
      _MetricCell(
        index: 'METRIC // 03',
        value: '$overdue'.padLeft(2, '0'),
        label: 'OVERDUE BLOCKS',
        dimmed: overdue == 0,
      ),
      _MetricCell(
        index: 'ALLOCATION // 04',
        value: '$capacity',
        suffix: '%',
        label: 'EXECUTION CAPACITY',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _MetricRow(cells: cells);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetricRow(cells: cells.sublist(0, 2)),
            _MetricRow(cells: cells.sublist(2, 4), topBorder: true),
          ],
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  final List<_MetricCell> cells;
  final bool topBorder;

  const _MetricRow({required this.cells, this.topBorder = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: scheme.primary,
            width: topBorder ? 1 : 0,
          ),
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(child: cells[i]),
              if (i < cells.length - 1)
                Container(width: 1, color: scheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String index;
  final String value;
  final String? suffix;
  final String label;
  final bool dimmed;

  const _MetricCell({
    required this.index,
    required this.value,
    required this.label,
    this.suffix,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = dimmed ? scheme.secondary : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.displayLarge?.copyWith(color: fg),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: theme.textTheme.labelMedium?.copyWith(color: fg),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
