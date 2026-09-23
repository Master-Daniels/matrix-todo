import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';

typedef ListCounts = ({int total, int completed, bool hasHigh});

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

/// Live per-list counts. `listId` is the `TaskList.id`.
final listCountsProvider = FutureProvider.family<ListCounts, int>((
  ref,
  listId,
) async {
  final tasks = await ref.watch(listTasksProvider(listId).future);
  return (
    total: tasks.length,
    completed: tasks.where((t) => t.done).length,
    hasHigh: tasks.any((t) => !t.done && t.priority >= 3),
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
