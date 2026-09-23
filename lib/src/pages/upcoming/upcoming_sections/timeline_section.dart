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

/// Ledger day block: inverted index header (`[01] TOMORROW // WED APR 15`
/// + `N TASKS` badge) over contiguous task rows. Reused for the conditional
/// OVERDUE block with a plain (non-inverted) header.
class TimelineSection extends StatelessWidget {
  final String index;
  final String title;
  final List<TodoTask> tasks;
  final bool inverted;

  const TimelineSection({
    super.key,
    required this.index,
    required this.title,
    required this.tasks,
    this.inverted = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = inverted ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = inverted ? scheme.onPrimary : scheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                  color: inverted ? scheme.surface : scheme.surface,
                  border: Border.all(
                    color: inverted ? scheme.onPrimary : scheme.primary,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${tasks.length} TASKS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tasks.length; i++)
              UpcomingTaskRow(
                task: tasks[i],
                index: (i + 1).toString().padLeft(2, '0'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tomorrow-style row: leading time/index strip over a checkbox body with
/// priority label + ⋮ popover. Done rows render concrete + struck-through.
/// When this row is the notification deep-link target ([focusedTaskIdProvider])
/// it scrolls into view once and renders highlighted until tapped.
class UpcomingTaskRow extends ConsumerStatefulWidget {
  final TodoTask task;
  final String index;

  const UpcomingTaskRow({super.key, required this.task, required this.index});

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

    return TaskSwipe(
      swipeKey: 'upcoming-${task.id ?? 'n'}-$index',
      done: done,
      onMarkDone: () => _toggleDone(ref, task, true),
      onMarkUndone: () => _toggleDone(ref, task, false),
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
                  (task.dueTime ?? '').isEmpty
                      ? task.dueDate.toUpperCase()
                      : task.dueTime!.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
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
                        const SizedBox(height: 4),
                        Text(
                          task.notes.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                      ],
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
    ref.read(focusedTaskIdProvider.notifier).clear();
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
