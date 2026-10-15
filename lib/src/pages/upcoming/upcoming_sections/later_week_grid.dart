import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../data/recurrence.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/deck_swipe.dart';
import '../../../widgets/done_undo.dart';
import '../../../widgets/subtask_slot.dart';
import '../../add_task/add_task_sheet.dart';
import '../../home/home_sections/reschedule_dialog.dart';
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
      for (var i = 0; i < byDate[iso]!.length; i++) {
        cells.add(
          LaterWeekRow(
            task: byDate[iso]![i],
            date: tryParseDueDate(iso) ?? DateTime.now(),
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

/// Later-week row from the timeline design: `[WED 07]` date chip,
/// title, due time and a chevron collapsing the notes. Notes render
/// expanded by default. Swipe right completes, left reschedules.
/// Also reused for open Next Week & Beyond segments.
class LaterWeekRow extends ConsumerStatefulWidget {
  final TodoTask task;
  final DateTime date;

  const LaterWeekRow({
    super.key,
    required this.task,
    required this.date,
  });

  @override
  ConsumerState<LaterWeekRow> createState() => _LaterWeekRowState();
}

class _LaterWeekRowState extends ConsumerState<LaterWeekRow> {
  bool _expanded = true;

  TodoTask get task => widget.task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.done;
    final date = widget.date;

    return HomeDeckSwipe(
      swipeKey: 'bento-${task.id ?? 'n'}-${task.dueDate}',
      done: done,
      rotate: false,
      onComplete: () => _completeWithUndo(task),
      onReschedule: () => showRescheduleDialog(context, task),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weekdayShort[date.weekday - 1],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                      Text(
                        date.day.toString().padLeft(2, '0'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: done ? scheme.secondary : scheme.primary,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      normalizeDueTime(task.dueTime).isEmpty
                          ? 'ANYTIME'
                          : normalizeDueTime(task.dueTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                TaskPopover(task: task),
              ],
            ),
            if (_expanded && task.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.secondary,
                ),
              ),
            ],
            if (task.id != null) SubtaskSlot(taskId: task.id),
            if (task.recurrence.trim().toUpperCase() == 'DAILY' ||
                task.recurrence.trim().toUpperCase() == 'WEEKLY')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '↻ ${task.recurrence.trim().toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
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
      builder: (_) => AddTaskSheet(task: task),
    );
  }

  Future<int?> _toggleDone(WidgetRef ref, TodoTask task, bool done) async {
    final id = task.id;
    if (id == null) return null;
    final db = ref.read(appDatabaseProvider);
    int? cloneId;
    if (done) {
      cloneId = await completeTaskWithRecurrence(db, task);
    } else {
      await db.setTaskDone(id, false);
    }
    await ref.read(reminderServiceProvider).syncAll(
          await db.getTasks(),
          enabled: ref.read(remindersEnabledProvider),
        );
    ref.invalidate(tasksProvider);
    ref.invalidate(upcomingGroupsProvider);
    ref.invalidate(weekStripProvider);
    return cloneId;
  }

  Future<void> _completeWithUndo(TodoTask task) async {
    final cloneId = await _toggleDone(ref, task, true);
    if (!mounted || !context.mounted) return;
    showDoneUndo(
      context,
      ref,
      task,
      () => _undoComplete(ref, task, cloneId),
    );
  }

  Future<void> _undoComplete(WidgetRef ref, TodoTask task, int? cloneId) async {
    if (cloneId != null) {
      try {
        await ref.read(appDatabaseProvider).deleteTask(cloneId);
      } catch (_) {}
    }
    await _toggleDone(ref, task, false);
  }
}
