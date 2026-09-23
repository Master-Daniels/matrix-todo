import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'models.dart';

/// Foundation providers. Screen-specific notifiers get added per-screen;
/// mutate via `appDatabaseProvider` then `ref.invalidate(...)` to refresh.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// All lists, sort order. Refresh with `ref.invalidate(listsProvider)`.
final listsProvider = FutureProvider<List<TaskList>>((ref) async {
  return ref.watch(appDatabaseProvider).getLists();
});

/// Tasks for [listId], or all tasks when null. Filter by `done` optionally.
final tasksProvider =
    FutureProvider.family<List<TodoTask>, ({int? listId, bool? done})>((
      ref,
      args,
    ) async {
      return ref
          .watch(appDatabaseProvider)
          .getTasks(listId: args.listId, done: args.done);
    });

/// Subtasks for a single task.
final subtasksProvider = FutureProvider.family<List<Subtask>, int>((
  ref,
  taskId,
) async {
  return ref.watch(appDatabaseProvider).getSubtasks(taskId);
});

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void updateIndex(int newIndex) {
    state = newIndex;
  }
}
