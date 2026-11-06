import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../stats/stats_page.dart';
import '../home_providers.dart';
import 'home_filter_sheet.dart';

/// Metrics header: `01 / 04 COMPLETED • %` + streak (taps to Stats),
/// segmented meter, single `FILTER` button opening the filter sheet.
class HomeMetrics extends ConsumerWidget {
  const HomeMetrics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = ref.watch(todayCountsProvider);
    final activeFilter = ref.watch(homeFilterProvider);

    final total = counts.maybeWhen(data: (d) => d.total, orElse: () => 0);
    final completed =
        counts.maybeWhen(data: (d) => d.completed, orElse: () => 0);
    final pct = total == 0 ? 0 : (completed / total * 100).round();
    final streak = ref.watch(streakProvider).maybeWhen(
          data: (s) => s,
          orElse: () => 0,
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$completed of $total completed • $pct%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$streak ${streak == 1 ? 'day' : 'days'} streak',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_right,
                      size: 14,
                      color: scheme.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SegmentedMeter(completed: completed, total: total),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const HomeFilterSheet(),
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter: ${activeFilter ?? 'All'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedMeter extends StatelessWidget {
  final int completed;
  final int total;

  const _SegmentedMeter({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (total <= 0) {
      return Container(height: 6, color: scheme.surfaceContainerHigh);
    }
    final segments = total.clamp(1, 8);
    return Row(
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i < segments - 1 ? 4 : 0),
              color: i < completed ? scheme.primary : scheme.outline,
            ),
          ),
      ],
    );
  }
}
