import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../upcoming_providers.dart';
import 'upcoming_format.dart';

/// 7-day strip (Mon–Sun): weekday, day number, `[nn]` task count.
/// Interactive: tapping a day filters upcoming tasks for that day.
/// Today renders inverted with a `NOW` tag. Selected day inverts with `SEL ■`.
class DayStrip extends ConsumerWidget {
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onSelectDay;

  const DayStrip({
    super.key,
    this.selectedDay,
    this.onSelectDay,
  });

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
                  isSelected: days != null &&
                      selectedDay != null &&
                      dayOf(days[i].day).isAtSameMomentAs(dayOf(selectedDay!)),
                  onTap: days?[i].day == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onSelectDay?.call(days![i].day);
                        },
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
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = isToday || isSelected;
    final fg = active ? scheme.onPrimary : scheme.primary;
    final muted = active ? scheme.inversePrimary : scheme.secondary;

    String? tagText;
    if (isToday && isSelected) {
      tagText = 'NOW ■';
    } else if (isToday) {
      tagText = 'NOW';
    } else if (isSelected) {
      tagText = 'SEL ■';
    }

    final dayName = day == null ? 'Day' : weekdayShort[day!.weekday - 1];
    final countText = count == null ? '0 tasks' : '$count tasks';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$dayName, ${day?.day ?? ''}, $countText${isToday ? ', today' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (onTap != null) {
            HapticFeedback.selectionClick();
            onTap!();
          }
        },
        child: Container(
          color: active ? scheme.primary : scheme.surface,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Stack(
            children: [
              if (tagText != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.onPrimary, width: 1),
                    ),
                    child: Text(
                      tagText,
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
        ),
      ),
    );
  }
}
