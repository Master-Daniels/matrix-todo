import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../settings/settings_providers.dart';
import '../upcoming_providers.dart';
import 'later_week_grid.dart';
import 'upcoming_format.dart';

/// `NEXT WEEK & BEYOND` accordion: outer bar with total badge + expand
/// icon, inside three range segments (next-7 / week-after / horizon) each
/// expanding its rows inline via `VIEW SEGMENT ->`.
class NextWeekAccordion extends ConsumerStatefulWidget {
  final List<TodoTask> tasks;

  const NextWeekAccordion({super.key, required this.tasks});

  @override
  ConsumerState<NextWeekAccordion> createState() => _NextWeekAccordionState();
}

class _NextWeekAccordionState extends ConsumerState<NextWeekAccordion> {
  bool expanded = true;
  final Set<int> openSegments = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weekStart = ref.watch(weekStartProvider);
    final now = dayOf(DateTime.now());
    final sunday = weekEndOf(now, weekStart.weekday);
    final seg1End = sunday.add(const Duration(days: 7));
    final seg2End = sunday.add(const Duration(days: 14));

    final seg1 = <TodoTask>[];
    final seg2 = <TodoTask>[];
    final seg3 = <TodoTask>[];
    for (final t in widget.tasks) {
      final d = dayOf(tryParseDueDate(t.dueDate) ?? now);
      if (!d.isAfter(seg1End)) {
        seg1.add(t);
      } else if (!d.isAfter(seg2End)) {
        seg2.add(t);
      } else {
        seg3.add(t);
      }
    }
    final segments = [
      (
        label:
            '${fmtDayBadge(sunday.add(const Duration(days: 1)))} - ${fmtDayBadge(seg1End)}',
        tasks: seg1,
      ),
      (
        label:
            '${fmtDayBadge(seg1End.add(const Duration(days: 1)))} - ${fmtDayBadge(seg2End)}',
        tasks: seg2,
      ),
      (label: '${monthShort[seg2End.month - 1]} ${seg2End.year} HORIZON', tasks: seg3),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '[03]',
                  style: AppTypography.indexIndicator(
                    context,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next week & beyond',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Text(
                    '${widget.tasks.length} tasks',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (var s = 0; s < segments.length; s++)
            if (segments[s].tasks.isNotEmpty)
              _SegmentBlock(
                label: segments[s].label,
                tasks: segments[s].tasks,
                open: openSegments.contains(s),
                onToggle: () => setState(() {
                  openSegments.contains(s)
                      ? openSegments.remove(s)
                      : openSegments.add(s);
                }),
              ),
      ],
    );
  }
}

class _SegmentBlock extends StatelessWidget {
  final String label;
  final List<TodoTask> tasks;
  final bool open;
  final VoidCallback onToggle;

  const _SegmentBlock({
    required this.label,
    required this.tasks,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ),
                    Text(
                      '${tasks.length} TASKS',
                      style: AppTypography.indexIndicator(
                        context,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tasks.first.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  open ? 'HIDE SEGMENT -' : 'VIEW SEGMENT ->',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open)
          for (final task in tasks)
            LaterWeekRow(
              task: task,
              date: tryParseDueDate(task.dueDate) ?? dayOf(DateTime.now()),
            ),
      ],
    );
  }
}
