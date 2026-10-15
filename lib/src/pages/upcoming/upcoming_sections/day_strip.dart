import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../upcoming_providers.dart';
import 'upcoming_format.dart';

/// Static 7-day strip (Mon–Sun): weekday, day number, `[nn]` task count.
/// Today renders inverted with a `NOW` tag. Display-only, no interaction.
class DayStrip extends ConsumerWidget {
  const DayStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stripAsync = ref.watch(weekStripProvider);
    final days = stripAsync.maybeWhen(data: (d) => d, orElse: () => null);
    final today = dayOf(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 1),
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: scheme.primary,
                      width: i == 6 ? 0 : 1,
                    ),
                  ),
                ),
                child: _DayCell(
                  day: days?[i].day,
                  count: days?[i].count,
                  isToday: days != null &&
                      dayOf(days[i].day).isAtSameMomentAs(today),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime? day;
  final int? count;
  final bool isToday;

  const _DayCell({required this.day, required this.count, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = isToday ? scheme.onPrimary : scheme.primary;
    final muted = isToday ? scheme.inversePrimary : scheme.secondary;
    return Container(
      color: isToday ? scheme.primary : scheme.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Stack(
        children: [
          if (isToday)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.onPrimary, width: 1),
                ),
                child: Text(
                  'NOW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day == null ? '---' : weekdayShort[day!.weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 2),
                Text(
                  day == null ? '--' : '${day!.day}'.padLeft(2, '0'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == null
                      ? '[--]'
                      : '[${'$count'.padLeft(2, '0')}]',
                  style: AppTypography.indexIndicator(context, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
