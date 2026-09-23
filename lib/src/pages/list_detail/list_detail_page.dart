import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_cell.dart';
import '../../widgets/task_swipe.dart';
import '../add_task/add_task_sheet.dart';
import '../lists/lists_providers.dart';
import '../settings/settings_providers.dart';

/// Folder view pushed from [ListsPage]: list header with live counts plus
/// its tasks as [TaskCell] rows. Back via the app-bar leading button.
class ListDetailPage extends ConsumerWidget {
  final TaskList list;

  const ListDetailPage({super.key, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = list.id == null
        ? null
        : ref.watch(listCountsProvider(list.id!));
    final total = counts?.maybeWhen(data: (c) => c.total, orElse: () => 0) ?? 0;
    final done =
        counts?.maybeWhen(data: (c) => c.completed, orElse: () => 0) ?? 0;

    return Scaffold(
      appBar: CustomAppBar(
        leading: CustomIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: list.name,
        index: list.code,
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (list.description.isNotEmpty)
                  Text(
                    list.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '$done OF $total DONE',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ProgressBar(total: total == 0 ? 1 : total, completed: done),
              ],
            ),
          ),
          const SectionHeader(title: 'Tasks // Entries', index: '[SEC 01]'),
          _DetailTaskList(listId: list.id),
        ],
      ),
    );
  }
}

class _DetailTaskList extends ConsumerWidget {
  final int? listId;

  const _DetailTaskList({required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = listId;
    if (id == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          title: 'No folder selected',
          hint: 'Go back and pick a list',
        ),
      );
    }
    final tasksAsync = ref.watch(listTasksProvider(id));
    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LoadingState(label: 'LOADING FOLDER'),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(listTasksProvider),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: EmptyState(
              title: 'No tasks in this folder',
              hint: 'Add tasks from Today with this category',
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tasks.length; i++)
              TaskSwipe(
                swipeKey: 'detail-${tasks[i].id ?? 'n'}-$i',
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
                    : '',
                priorityBadge: tasks[i].priority >= 2 ? 'HIGH PRIORITY' : null,
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
    ref.invalidate(tasksProvider);
    ref.invalidate(listTasksProvider);
    ref.invalidate(listCountsProvider);
    ref.invalidate(listsSummaryProvider);
  }
}
