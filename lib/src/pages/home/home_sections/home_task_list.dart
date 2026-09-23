import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/task_cell.dart';
import '../../../widgets/task_swipe.dart';
import '../../add_task/add_task_sheet.dart';
import '../../settings/settings_providers.dart';
import '../home_providers.dart';

/// Today task list wired to live DB:
/// checkbox persists via `setTaskDone`, errors/empty use shared states.
class HomeTaskList extends ConsumerWidget {
  const HomeTaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LoadingState(label: 'LOADING TODAY // PLEASE WAIT'),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(todayTasksProvider),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: EmptyState(
              index: '[EMPTY // 00]',
              title: 'No tasks for this filter',
              hint: 'Add a task dated today or seed the design snapshot',
              actionLabel: '+ Seed demo tasks',
              onAction: () => _seedDemo(ref),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tasks.length; i++)
              TaskSwipe(
                swipeKey: '${tasks[i].id ?? 'n'}-$i',
                done: tasks[i].done,
                onMarkDone: () => _toggleDone(ref, tasks[i], true),
                onMarkUndone: () => _toggleDone(ref, tasks[i], false),
                onTap: () => _openEdit(context, tasks[i]),
                child: TaskCell(
                  index: (i + 1).toString().padLeft(2, '0'),
                tag: tasks[i].category,
                time: (tasks[i].dueTime ?? '').isEmpty
                    ? 'ANYTIME'
                    : tasks[i].dueTime!,
                title: tasks[i].title,
                description: tasks[i].notes,
                completed: tasks[i].done,
                active: tasks[i].focus && !tasks[i].done,
                checked: tasks[i].done,
                trailing: tasks[i].focus && !tasks[i].done
                    ? 'FOCUS'
                    : tasks[i].done
                        ? 'DONE'
                        : tasks[i].priority >= 2
                            ? 'HIGH'
                            : '',
                priorityBadge:
                    tasks[i].priority >= 2 ? 'HIGH PRIORITY' : null,
                actionLabel: tasks[i].focus && !tasks[i].done
                    ? 'OPEN SLIDES'
                    : null,
                onChecked: tasks[i].id == null
                    ? null
                    : (v) => _toggleDone(ref, tasks[i], v),
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
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayCountsProvider);
    ref.invalidate(tasksProvider);
  }

  Future<void> _seedDemo(WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    for (final t in todaySeedTasks()) {
      await db.insertTask(t);
    }
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayCountsProvider);
    ref.invalidate(tasksProvider);
    try {
      await ref.read(reminderServiceProvider).syncAll(
            await db.getTasks(),
            enabled: ref.read(remindersEnabledProvider),
          );
    } catch (_) {}
  }
}
