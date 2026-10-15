import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/recurrence.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/button.dart';
import '../../widgets/done_undo.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_cell.dart';
import '../../widgets/deck_swipe.dart';
import '../../data/task_dates.dart';
import '../add_task/add_task_sheet.dart';
import '../home/home_sections/reschedule_dialog.dart';
import '../lists/lists_providers.dart';
import '../upcoming/upcoming_sections/upcoming_format.dart';
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(color: scheme.primary, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                _DetailTaskList(
                  listId: list.id,
                  lockedCategory: list.name,
                  lockedListId: list.id,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              top: false,
              child: Button(
                label: 'Add task to list',
                onPressed: () => showAnimatedModalBottomSheet(
                  context: context,
                  builder: (_) => AddTaskSheet(
                    lockedCategory: list.name,
                    lockedListId: list.id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overdue stamp for folder rows: `DUE YESTERDAY 18:00`-style when the
/// task is past due, plain time when timed, `ANYTIME` otherwise.
String _detailStamp(TodoTask t) {
  final parsed = tryParseDueDate(t.dueDate);
  final overdue = !t.done &&
      parsed != null &&
      isOverdueDay(dayOf(parsed), dayOf(DateTime.now()));
  if ((t.dueTime ?? '').trim().isEmpty && !overdue) return 'ANYTIME';
  return fmtDueStamp(t, showDate: overdue);
}

enum _DetailFilter { all, active, done, high }

enum _DetailSort { time, priority, added }

class _DetailTaskList extends ConsumerStatefulWidget {
  final int? listId;
  final String? lockedCategory;
  final int? lockedListId;

  const _DetailTaskList({
    required this.listId,
    this.lockedCategory,
    this.lockedListId,
  });

  @override
  ConsumerState<_DetailTaskList> createState() => _DetailTaskListState();
}

class _DetailTaskListState extends ConsumerState<_DetailTaskList> {
  _DetailFilter _filter = _DetailFilter.all;
  _DetailSort _sort = _DetailSort.time;
  bool _clearing = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.listId;
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
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: EmptyState(
              title: 'No tasks in this folder',
              hint: 'Add tasks from Today with this category',
              actionLabel: '+ Add task',
              onAction: () => showAnimatedModalBottomSheet(
                context: context,
                builder: (_) => AddTaskSheet(
                  lockedCategory: widget.lockedCategory,
                  lockedListId: widget.lockedListId,
                ),
              ),
            ),
          );
        }
        final filtered = tasks.where((t) {
          switch (_filter) {
            case _DetailFilter.all:
              return true;
            case _DetailFilter.active:
              return !t.done;
            case _DetailFilter.done:
              return t.done;
            case _DetailFilter.high:
              return t.priority >= 3;
          }
        }).toList();
        filtered.sort((a, b) {
          switch (_sort) {
            case _DetailSort.time:
              final t = (a.dueTime ?? '').compareTo(b.dueTime ?? '');
              if (t != 0) return t;
              final d = a.dueDate.compareTo(b.dueDate);
              if (d != 0) return d;
              break;
            case _DetailSort.priority:
              final p = b.priority.compareTo(a.priority);
              if (p != 0) return p;
              break;
            case _DetailSort.added:
              break;
          }
          final s = a.sort.compareTo(b.sort);
          if (s != 0) return s;
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });
        final doneCount = tasks.where((t) => t.done).length;
        final reorderable = _sort == _DetailSort.added &&
            _filter == _DetailFilter.all &&
            filtered.length > 1 &&
            filtered.every((t) => t.id != null);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterBar(
              filter: _filter,
              sort: _sort,
              doneCount: doneCount,
              clearing: _clearing,
              onFilterTap: () => _openFilterSheet(context),
              onClear: doneCount == 0 || _clearing
                  ? null
                  : () => _confirmClear(context, ref),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: EmptyState(
                  title: 'No matches',
                  hint: 'Adjust filter // ${_filter.name.toUpperCase()}',
                ),
              ),
            if (reorderable)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: filtered.length,
                onReorderItem: (o, n) => _reorder(ref, filtered, o, n),
                itemBuilder: (ctx, i) {
                  final scheme = Theme.of(ctx).colorScheme;
                  return Container(
                    key: ValueKey('reorder-${filtered[i].id}'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            top: AppSpacing.lg,
                          ),
                          child: ReorderableDragStartListener(
                            index: i,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: scheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 18,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _row(context, ref, filtered[i], i),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              for (var i = 0; i < filtered.length; i++)
                _row(context, ref, filtered[i], i),
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

  Widget _row(BuildContext context, WidgetRef ref, TodoTask task, int i) {
    return HomeDeckSwipe(
      swipeKey: 'detail-${task.id ?? 'n'}-$i',
      done: task.done,
      rotate: false,
      onComplete: () => _completeWithUndo(context, ref, task),
      onReschedule: () => showRescheduleDialog(context, task),
      onTap: () => _openEdit(context, task),
      child: TaskCell(
        index: (i + 1).toString().padLeft(2, '0'),
        tag: task.category,
        time: _detailStamp(task),
        title: task.title,
        description: task.notes,
        completed: task.done,
        active: task.focus && !task.done,
        checked: task.done,
        trailing: task.focus && !task.done
            ? 'FOCUS'
            : task.done
                ? 'DONE'
                : '',
        priorityBadge: task.priority >= 3 ? 'HIGH PRIORITY' : null,
        onChecked: task.id == null
            ? null
            : (v) => _checkWithUndo(context, ref, task, v),
        subtaskTaskId: task.id,
        recurrence: task.recurrence,
      ),
    );
  }

  /// Manual order (WS13): persists the visible order into `sort`. Handles
  /// show only in ADDED + ALL view so stored order matches the screen.
  /// (`onReorderItem` already adjusts newIndex for the removed item.)
  Future<void> _reorder(
    WidgetRef ref,
    List<TodoTask> visible,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    final order = visible.toList();
    final moved = order.removeAt(oldIndex);
    order.insert(newIndex, moved);
    final db = ref.read(appDatabaseProvider);
    for (var i = 0; i < order.length; i++) {
      final t = order[i];
      if (t.id != null && t.sort != i) {
        await db.updateTask(t.copyWith(sort: i));
      }
    }
    ref.invalidate(tasksProvider);
    ref.invalidate(listTasksProvider);
    ref.invalidate(listCountsProvider);
    ref.invalidate(listsSummaryProvider);
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
    ref.invalidate(listTasksProvider);
    ref.invalidate(listCountsProvider);
    ref.invalidate(listsSummaryProvider);
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

  void _openFilterSheet(BuildContext context) {
    showAnimatedModalBottomSheet(
      context: context,
      builder: (_) => _DetailFilterSheet(
        filter: _filter,
        sort: _sort,
        onFilter: (f) {
          setState(() => _filter = f);
          Navigator.of(context).pop();
        },
        onSort: (s) {
          setState(() => _sort = s);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: scheme.primary, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          elevation: 0,
          backgroundColor: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLEAR COMPLETED?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DELETES DONE TASKS IN THIS FOLDER // UNDONE KEPT.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        label: 'Cancel',
                        kind: ButtonKind.secondary,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Button(
                        label: 'Clear',
                        kind: ButtonKind.danger,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    await _clearCompleted(ref);
  }

  Future<void> _clearCompleted(WidgetRef ref) async {
    final id = widget.listId;
    if (id == null || _clearing) return;
    setState(() => _clearing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final tasks = await ref.read(listTasksProvider(id).future);
      for (final t in tasks.where((t) => t.done)) {
        if (t.id != null) await db.deleteTask(t.id!);
      }
      await ref.read(reminderServiceProvider).syncAll(
            await db.getTasks(),
            enabled: ref.read(remindersEnabledProvider),
          );
      ref.invalidate(tasksProvider);
      ref.invalidate(listTasksProvider);
      ref.invalidate(listCountsProvider);
      ref.invalidate(listsSummaryProvider);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }
}

/// Compact single-row bar: one `FILTER` button opening the filter sheet
/// plus the clear-completed action. Replaces the inline 8-segment toolbar.
class _FilterBar extends StatelessWidget {
  final _DetailFilter filter;
  final _DetailSort sort;
  final int doneCount;
  final bool clearing;
  final VoidCallback onFilterTap;
  final VoidCallback? onClear;

  const _FilterBar({
    required this.filter,
    required this.sort,
    required this.doneCount,
    required this.clearing,
    required this.onFilterTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFilterTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'FILTER: ${filter.name.toUpperCase()} • ${sort.name.toUpperCase()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.expand_more,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: onClear == null ? scheme.secondary : scheme.error,
                  width: 1,
                ),
              ),
              child: Text(
                clearing ? 'CLEARING…' : 'CLEAR ($doneCount)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onClear == null ? scheme.secondary : scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter + sort sheet for folder rows.
class _DetailFilterSheet extends StatelessWidget {
  final _DetailFilter filter;
  final _DetailSort sort;
  final ValueChanged<_DetailFilter> onFilter;
  final ValueChanged<_DetailSort> onSort;

  const _DetailFilterSheet({
    required this.filter,
    required this.sort,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget seg(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            border: Border.all(color: scheme.primary, width: 1),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? scheme.onPrimary : scheme.primary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 2),
          left: BorderSide(color: scheme.primary, width: 2),
          right: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom > 12
            ? MediaQuery.of(context).viewPadding.bottom
            : 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'FILTER // FOLDER',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 1),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SHOW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final f in _DetailFilter.values) ...[
                      Expanded(
                        child: seg(
                          f.name.toUpperCase(),
                          f == filter,
                          () => onFilter(f),
                        ),
                      ),
                      if (f != _DetailFilter.values.last)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SORT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final s in _DetailSort.values) ...[
                      Expanded(
                        child: seg(
                          s.name.toUpperCase(),
                          s == sort,
                          () => onSort(s),
                        ),
                      ),
                      if (s != _DetailSort.values.last)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
