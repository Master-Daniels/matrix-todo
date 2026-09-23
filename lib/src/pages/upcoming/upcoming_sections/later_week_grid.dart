import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/checkbox.dart';
import '../../../widgets/task_swipe.dart';
import '../../add_task/add_task_sheet.dart';
import '../../settings/settings_providers.dart';
import '../upcoming_providers.dart';
import 'task_popover.dart';
import 'upcoming_format.dart';

/// `LATER THIS WEEK` bento grid: one structural cell per task, grouped
/// under its day badge. Stacked on phones, 2-column when wide.
class LaterWeekGrid extends StatelessWidget {
  final List<TodoTask> tasks;

  const LaterWeekGrid({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final order = <String>[];
    final byDate = <String, List<TodoTask>>{};
    for (final t in tasks) {
      (byDate[t.dueDate] ??= []).add(t);
      if (!order.contains(t.dueDate)) order.add(t.dueDate);
    }
    final cells = <Widget>[];
    for (final iso in order) {
      final first = order.first == iso;
      for (var i = 0; i < byDate[iso]!.length; i++) {
        cells.add(
          _BentoCell(
            task: byDate[iso]![i],
            date: tryParseDueDate(iso) ?? DateTime.now(),
            highlightBadge: first && i == 0,
          ),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(mainAxisSize: MainAxisSize.min, children: cells);
        }
        final rows = <Widget>[];
        for (var r = 0; r * 2 < cells.length; r += 1) {
          final rowCells = <Widget>[];
          for (var c = 0; c < 2; c++) {
            final i = r * 2 + c;
            if (i < cells.length) {
              rowCells.add(Expanded(child: cells[i]));
              if (c == 0) {
                rowCells.add(Container(width: 1, color: scheme.primary));
              }
            } else {
              rowCells.add(const Expanded(child: SizedBox.shrink()));
            }
          }
          rows.add(IntrinsicHeight(child: Row(children: rowCells)));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

class _BentoCell extends ConsumerWidget {
  final TodoTask task;
  final DateTime date;
  final bool highlightBadge;

  const _BentoCell({
    required this.task,
    required this.date,
    required this.highlightBadge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.done;

    return TaskSwipe(
      swipeKey: 'bento-${task.id ?? 'n'}-${task.dueDate}',
      done: done,
      onMarkDone: () => _toggleDone(ref, task, true),
      onMarkUndone: () => _toggleDone(ref, task, false),
      onTap: () => _openEdit(context, task),
      child: Container(
        decoration: BoxDecoration(
          color: done ? scheme.surfaceContainerLow : scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: highlightBadge ? scheme.primary : Colors.transparent,
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Text(
                  fmtDayBadge(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: highlightBadge
                        ? scheme.onPrimary
                        : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '[TAG: ${task.category.toUpperCase()}]',
                style: AppTypography.indexIndicator(
                  context,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CustomCheckbox(
                  value: done,
                  onChanged: task.id == null
                      ? null
                      : (v) => _toggleDone(ref, task, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: done ? scheme.secondary : scheme.primary,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (task.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TaskPopover(task: task),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outline, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TIME: ${(task.dueTime ?? 'ANYTIME').toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Text(
                    task.category.toUpperCase(),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _openEdit(BuildContext context, TodoTask task) {
    showAnimatedModalBottomSheet(
      context: context,
      heightFactor: 0.92,
      builder: (_) => AddTaskSheet(task: task),
    );
  }

  Future<void> _toggleDone(WidgetRef ref, TodoTask task, bool done) async {
    final id = task.id;
    if (id == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.setTaskDone(id, done);
    await ref.read(reminderServiceProvider).syncAll(
          await db.getTasks(),
          enabled: ref.read(remindersEnabledProvider),
        );
    ref.invalidate(tasksProvider);
    ref.invalidate(upcomingGroupsProvider);
    ref.invalidate(weekStripProvider);
    ref.invalidate(upcomingMetricsProvider);
  }
}
