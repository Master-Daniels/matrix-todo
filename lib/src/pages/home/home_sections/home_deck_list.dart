import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../data/recurrence.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/done_undo.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/task_cell.dart';
import '../../add_task/add_task_sheet.dart';
import '../../settings/settings_providers.dart';
import '../home_providers.dart';
import '../../upcoming/upcoming_providers.dart';
import 'home_deck.dart';
import 'home_deck_card.dart';
import '../../../widgets/deck_swipe.dart';
import 'reschedule_dialog.dart';
/// Scrollable deck (takes majority of viewport, no tap-to-expand).
/// Deck density = swipeable rounded cards, compact = flat ledger rows.
class HomeDeckList extends ConsumerWidget {
  const HomeDeckList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final density = ref.watch(homeDensityProvider);

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LoadingState(label: 'Loading today'),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ErrorState(
          message: '$e',
          onRetry: () {
            ref.invalidate(todayBaseTasksProvider);
            ref.invalidate(todayTasksProvider);
          },
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: EmptyState(
              index: '[EMPTY // 00]',
              title: 'No tasks here',
              hint: 'Add a task to get started',
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gesture cues flanking the deck.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Cue(icon: Icons.west, label: 'Reschedule'),
                  _Cue(icon: Icons.east, label: 'Complete', trailing: true),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (density == HomeDensity.deck)
              // One continuous deck: vertical scroll pages through
              // the cards inside it. Keyed by length so a shrinking
              // list (e.g. rescheduled away) never strands the pager.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  6,
                  AppSpacing.md,
                  6,
                ),
                child: HomeDeck(
                  key: ValueKey('deck-${tasks.length}'),
                  tasks: tasks,
                  cardBuilder: (i, task) => HomeDeckSwipe(
                    swipeKey: '${task.id ?? 'n'}-$i',
                    done: task.done,
                    onComplete: () =>
                        _completeWithUndo(context, ref, task),
                    onReschedule: () => _pickReschedule(context, task),
                    onTap: () => _openEdit(context, task),
                    child: HomeDeckCard(
                      task: task,
                      index: i + 1,
                      total: tasks.length,
                      height: HomeDeck.fixedCardHeight,
                      onChecked: task.id == null
                          ? null
                          : (v) => _checkWithUndo(context, ref, task, v),
                      onActionTap: () => _openEdit(context, task),
                    ),
                  ),
                ),
              )
            else
              for (var i = 0; i < tasks.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    6,
                    AppSpacing.md,
                    6,
                  ),
                  child: HomeDeckSwipe(
                    swipeKey: 'compact-${tasks[i].id ?? 'n'}-$i',
                    done: tasks[i].done,
                    rotate: false,
                    onComplete: () =>
                        _completeWithUndo(context, ref, tasks[i]),
                    onReschedule: () => _pickReschedule(context, tasks[i]),
                    onTap: () => _openEdit(context, tasks[i]),
                    child: TaskCell(
                      index: (i + 1).toString().padLeft(2, '0'),
                      tag: tasks[i].category,
                      time: _todayStamp(tasks[i]),
                      title: tasks[i].title,
                      description: tasks[i].notes,
                      completed: tasks[i].done,
                      active: tasks[i].focus && !tasks[i].done,
                      checked: tasks[i].done,
                      trailing: tasks[i].focus && !tasks[i].done
                          ? 'Focus'
                          : tasks[i].done
                          ? 'Done'
                          : tasks[i].priority >= 3
                          ? 'High'
                          : '',
                      onChecked: tasks[i].id == null
                          ? null
                          : (v) =>
                              _checkWithUndo(context, ref, tasks[i], v),
                      subtaskTaskId: tasks[i].id,
                      recurrence: tasks[i].recurrence,
                      onSkip: tasks[i].seriesId != null && !tasks[i].done
                          ? () => _skipOccurrence(context, ref, tasks[i])
                          : null,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  void _openEdit(BuildContext context, TodoTask task) {
    showAnimatedModalBottomSheet(
      context: context,
      builder: (_) => AddTaskSheet(task: task),
    );
  }

  /// Skip this occurrence: add its date to the series exceptions and mark it done.
  Future<void> _skipOccurrence(
      BuildContext context, WidgetRef ref, TodoTask task) async {
    if (task.id == null || task.seriesId == null) return;
    final db = ref.read(appDatabaseProvider);
    try {
      await db.insertRecurrenceException(
        RecurrenceException(
          seriesId: task.seriesId!,
          exceptionDate: task.dueDate,
        ),
      );
      await db.setTaskDone(task.id!, true);
      await db.setTaskSnooze(task.id!, null);
      await ref.read(reminderServiceProvider).syncAll(
            await db.getTasks(),
            enabled: ref.read(remindersEnabledProvider),
          );
      ref.invalidate(tasksProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayCountsProvider);
      ref.invalidate(upcomingGroupsProvider);
      ref.invalidate(weekStripProvider);
    } catch (_) {
      // Skip failure is non-fatal.
    }
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
    await ref
        .read(reminderServiceProvider)
        .syncAll(
          await db.getTasks(),
          enabled: ref.read(remindersEnabledProvider),
        );
    _invalidate(ref);
    return cloneId;
  }

  Future<void> _undoComplete(
    WidgetRef ref,
    TodoTask task,
    int? cloneId,
  ) async {
    if (cloneId != null) {
      try {
        await ref.read(appDatabaseProvider).deleteTask(cloneId);
      } catch (_) {}
    }
    await _toggleDone(ref, task, false);
  }

  Future<void> _completeWithUndo(
    BuildContext context,
    WidgetRef ref,
    TodoTask task,
  ) async {
    final cloneId = await _toggleDone(ref, task, true);
    if (!context.mounted) return;
    showDoneUndo(
      context,
      ref,
      task,
      () => _undoComplete(ref, task, cloneId),
    );
  }

  Future<void> _checkWithUndo(
    BuildContext context,
    WidgetRef ref,
    TodoTask task,
    bool done,
  ) async {
    final cloneId = await _toggleDone(ref, task, done);
    if (done && context.mounted) {
      showDoneUndo(
        context,
        ref,
        task,
        () => _undoComplete(ref, task, cloneId),
      );
    }
  }

  Future<void> _pickReschedule(BuildContext context, TodoTask task) async {
    if (task.id == null) return;
    await showRescheduleDialog(context, task);
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(todayBaseTasksProvider);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayCategoryCountsProvider);
    ref.invalidate(todayCountsProvider);
    ref.invalidate(tasksProvider);
  }
}

class _Cue extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool trailing;

  const _Cue({required this.icon, required this.label, this.trailing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!trailing) ...[
          Icon(icon, size: 14, color: scheme.secondary),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.secondary),
        ),
        if (trailing) ...[
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: scheme.secondary),
        ],
      ],
    );
  }
}

/// Today stamp with overdue day (WS10): `ANYTIME` / `HH:MM HRS` normally,
/// `DUE YESTERDAY HH:MM HRS` (or `DUE <ISO> …`) when past due and undone.
String _todayStamp(TodoTask t) {
  final parsed = tryParseDueDate(t.dueDate);
  final nowDay = dayOf(DateTime.now());
  final time = parseEventTime(t.dueTime);
  final norm = time == null
      ? (t.dueTime ?? '').trim().toUpperCase()
      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} HRS';
  if (parsed == null) return norm.isEmpty ? 'ANYTIME' : norm;
  final parsedDay = dayOf(parsed);
  if (t.done || !isOverdueDay(parsedDay, nowDay)) {
    return norm.isEmpty ? 'ANYTIME' : norm;
  }
  final behind = nowDay.difference(parsedDay).inDays;
  final dayPart = behind == 1 ? 'YESTERDAY' : t.dueDate.toUpperCase();
  return norm.isEmpty ? 'DUE $dayPart' : 'DUE $dayPart $norm';
}
