import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../data/recurrence.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/checkbox.dart';
import '../../../widgets/deck_swipe.dart';
import '../../../widgets/done_undo.dart';
import '../../../widgets/subtask_slot.dart';
import '../../add_task/add_task_sheet.dart';
import '../../home/home_sections/reschedule_dialog.dart';
import '../../settings/settings_providers.dart';
import '../upcoming_providers.dart';
import 'task_popover.dart';
import 'upcoming_format.dart';

/// Shared section bar: inverted index header (`[01] TOMORROW` + title +
/// `N TASKS` badge). Used by [TimelineSection] and the Later This Week
/// block so every timeline header matches.
class TimelineHeader extends StatelessWidget {
  final String index;
  final String title;
  final int count;
  final bool inverted;

  const TimelineHeader({
    super.key,
    required this.index,
    required this.title,
    required this.count,
    this.inverted = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = inverted ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = inverted ? scheme.onPrimary : scheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: bg,
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
            index.toUpperCase(),
            style: AppTypography.indexIndicator(
              context,
              color: inverted ? scheme.inversePrimary : scheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: fg,
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
              color: scheme.surface,
              border: Border.all(
                color: inverted ? scheme.onPrimary : scheme.primary,
                width: 1,
              ),
            ),
            child: Text(
              '$count TASKS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ledger day block: inverted index header (`[01] TOMORROW // WED APR 15`
/// + `N TASKS` badge) over contiguous task rows. Reused for the conditional
/// OVERDUE block with a plain (non-inverted) header.
class TimelineSection extends StatelessWidget {
  final String index;
  final String title;
  final List<TodoTask> tasks;
  final bool inverted;

  /// Overdue blocks also stamp the due *day* (not just the time) so the
  /// missed day is visible at a glance.
  final bool showDueDate;

  const TimelineSection({
    super.key,
    required this.index,
    required this.title,
    required this.tasks,
    this.inverted = true,
    this.showDueDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimelineHeader(
          index: index,
          title: title,
          count: tasks.length,
          inverted: inverted,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tasks.length; i++)
              UpcomingTaskRow(
                task: tasks[i],
                index: (i + 1).toString().padLeft(2, '0'),
                showDueDate: showDueDate,
              ),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _DashedEmpty(
                  onPlan: () => showAnimatedModalBottomSheet(
                    context: context,
                    builder: (_) => const AddTaskSheet(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Dashed `[EMPTY STATE]` box from the timeline design: no scheduled
/// tasks + `+ PLAN TIME BLOCK` entry point.
class _DashedEmpty extends StatelessWidget {
  final VoidCallback onPlan;

  const _DashedEmpty({required this.onPlan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CustomPaint(
      painter: _DashedBorderPainter(color: scheme.primary),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '[EMPTY STATE]',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NO TASKS SCHEDULED',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ENJOY THE SPACE — CALENDAR IS FULLY CLEAR',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onPlan,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Text(
                  '+ PLAN TIME BLOCK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      var drawn = 0.0;
      while (drawn < total) {
        final end = (drawn + dash).clamp(0.0, total);
        canvas.drawLine(
          a + (b - a) * (drawn / total),
          a + (b - a) * (end / total),
          paint,
        );
        drawn += dash + gap;
      }
    }

    line(Offset.zero, Offset(size.width, 0));
    line(Offset(size.width, 0), Offset(size.width, size.height));
    line(Offset(size.width, size.height), Offset(0, size.height));
    line(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tomorrow-style row: leading time/index strip over a checkbox body with
/// priority label + ⋮ popover. Done rows render concrete + struck-through.
/// When this row is the notification deep-link target ([focusedTaskIdProvider])
/// it scrolls into view once and renders highlighted until tapped.
class UpcomingTaskRow extends ConsumerStatefulWidget {
  final TodoTask task;
  final String index;

  /// When true, the trailing stamp shows the due day + time
  /// (`DUE YESTERDAY 18:00`) in red; otherwise time (or date) alone.
  final bool showDueDate;

  const UpcomingTaskRow({
    super.key,
    required this.task,
    required this.index,
    this.showDueDate = false,
  });

  @override
  ConsumerState<UpcomingTaskRow> createState() => _UpcomingTaskRowState();
}

class _UpcomingTaskRowState extends ConsumerState<UpcomingTaskRow> {
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealIfFocused());
  }

  void _revealIfFocused() {
    if (_scrolled || !mounted) return;
    if (ref.read(focusedTaskIdProvider) == widget.task.id) {
      _scrolled = true;
      try {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          alignment: 0.3,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final index = widget.index;
    final focused = ref.watch(focusedTaskIdProvider) == task.id;
    if (focused && !_scrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealIfFocused());
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.done;
    final bg = done ? scheme.surfaceContainerLow : scheme.surface;
    final fg = done ? scheme.secondary : scheme.primary;

    return HomeDeckSwipe(
      swipeKey: 'upcoming-${task.id ?? 'n'}-$index',
      done: done,
      rotate: false,
      onComplete: () => _completeWithUndo(task),
      onReschedule: () => showRescheduleDialog(context, task),
      onTap: () {
        if (focused) {
          ref.read(focusedTaskIdProvider.notifier).clear();
        }
        _openEdit(context, task);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(color: scheme.primary, width: 1),
          ),
        ),
        // Deep-link highlight while this row is the notification target.
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: scheme.secondary, width: 2),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$index/',
                  style: AppTypography.indexIndicator(
                    context,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: task.priority >= 3
                        ? scheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: scheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.priority >= 3
                          ? scheme.onPrimary
                          : scheme.primary,
                      fontWeight: task.priority >= 3
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  fmtDueStamp(task, showDate: widget.showDueDate),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.showDueDate && !done
                        ? scheme.error
                        : fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: CustomCheckbox(
                    value: done,
                    onChanged: task.id == null
                        ? null
                        : (v) => _checkWithUndo(task, v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: fg,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.notes,
                          style: theme.textTheme.labelSmall?.copyWith(
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
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (task.priority >= 3 && !done)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'PRIORITY: HIGH',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                      ),
                    TaskPopover(task: task),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, TodoTask task) {    showAnimatedModalBottomSheet(
      context: context,
      builder: (_) => AddTaskSheet(task: task),
    );
  }

  Future<int?> _toggleDone(WidgetRef ref, TodoTask task, bool done) async {
    final id = task.id;
    if (id == null) return null;
    ref.read(focusedTaskIdProvider.notifier).clear();
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

  Future<void> _undoComplete(WidgetRef ref, TodoTask task, int? cloneId) async {
    if (cloneId != null) {
      try {
        await ref.read(appDatabaseProvider).deleteTask(cloneId);
      } catch (_) {}
    }
    await _toggleDone(ref, task, false);
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

  Future<void> _checkWithUndo(TodoTask task, bool done) async {
    final cloneId = await _toggleDone(ref, task, done);
    if (done && mounted && context.mounted) {
      showDoneUndo(
        context,
        ref,
        task,
        () => _undoComplete(ref, task, cloneId),
      );
    }
  }
}
