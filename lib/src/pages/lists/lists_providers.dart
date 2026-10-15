import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/task_dates.dart';

typedef ListCounts = ({
  int total,
  int completed,
  bool hasHigh,
  bool hasActionable,
  int? nextId,
  String? nextTitle,
  bool nextDone,
});

/// A task belongs to a list via its explicit `listId` — or, when unset
/// (seeded snapshots, pre-linkage rows), by matching the category string.
bool taskBelongsToList(TodoTask task, TaskList list) {
  if (task.listId == list.id) return true;
  if (task.listId != null) return false;
  final cat = task.category.trim().toUpperCase();
  final name = list.name.trim().toUpperCase();
  if (cat == name) return true;
  // Seed alias: snapshot tasks use HOME while the list is HOME & LIVING.
  return name == 'HOME & LIVING' && cat == 'HOME';
}

TaskList? _resolveList(List<TaskList> lists, int listId) {
  for (final l in lists) {
    if (l.id == listId) return l;
  }
  return null;
}

/// Live tasks for a list, `listId` first then category-name fallback.
/// Single home for the linkage rule — counts and detail both use this.
final listTasksProvider = FutureProvider.family<List<TodoTask>, int>((
  ref,
  listId,
) async {
  final lists = await ref.watch(listsProvider.future);
  final resolved = _resolveList(lists, listId);
  if (resolved == null) return <TodoTask>[];
  final all = await ref.watch(tasksProvider((listId: null, done: null)).future);
  return all.where((t) => taskBelongsToList(t, resolved)).toList();
});

/// Live per-list counts plus queue state. `listId` is the `TaskList.id`.
final listCountsProvider = FutureProvider.family<ListCounts, int>((
  ref,
  listId,
) async {
  final tasks = await ref.watch(listTasksProvider(listId).future);
  final ordered = tasks.toList()
    ..sort((a, b) {
      final sortCmp = a.sort.compareTo(b.sort);
      if (sortCmp != 0) return sortCmp;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  final today = dayOf(DateTime.now());
  bool actionable(TodoTask t) {
    if (t.done) return false;
    final parsed = tryParseDueDate(t.dueDate);
    if (parsed == null) return false;
    final day = dayOf(parsed);
    return isToday(day, today) || isOverdueDay(day, today);
  }

  final undone = ordered.where((t) => !t.done).toList();
  final next = undone.isNotEmpty ? undone.first : ordered.isNotEmpty ? ordered.last : null;
  return (
    total: tasks.length,
    completed: tasks.where((t) => t.done).length,
    hasHigh: tasks.any((t) => !t.done && t.priority >= 3),
    hasActionable: tasks.any(actionable),
    nextId: next?.id,
    nextTitle: next?.title,
    nextDone: next?.done ?? false,
  );
});

typedef ListsSummary = ({int lists, int tasks, int completed});

/// Banner aggregates across all lists + unlisted tasks.
final listsSummaryProvider = FutureProvider<ListsSummary>((ref) async {
  final lists = await ref.watch(listsProvider.future);
  final all = await ref.watch(tasksProvider((listId: null, done: null)).future);
  return (
    lists: lists.length,
    tasks: all.length,
    completed: all.where((t) => t.done).length,
  );
});

/// Seeded directories (`sort` 0–3) render as quad-matrix cards.
final coreListsProvider = FutureProvider<List<TaskList>>((ref) async {
  final lists = await ref.watch(listsProvider.future);
  return lists.where((l) => l.sort < 4).toList();
});

/// User-created lists (`sort` 4+) render as ledger rows.
final customListsProvider = FutureProvider<List<TaskList>>((ref) async {
  final lists = await ref.watch(listsProvider.future);
  return lists.where((l) => l.sort >= 4).toList();
});
