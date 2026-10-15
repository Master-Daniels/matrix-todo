import 'app_database.dart';
import 'models.dart';
import 'task_dates.dart';

/// Next ISO due date for a recurrence rule: `DAILY` +1 day, `WEEKLY` +7.
/// Returns [iso] unchanged for `NONE`/unknown or unparseable input.
/// Pure + unit-testable.
String nextDueDate(String iso, String recurrence) {
  final day = tryParseDueDate(iso);
  if (day == null) return iso;
  final rule = recurrence.trim().toUpperCase();
  final next = switch (rule) {
    'DAILY' => day.add(const Duration(days: 1)),
    'WEEKLY' => day.add(const Duration(days: 7)),
    _ => null,
  };
  if (next == null) return iso;
  return isoDay(next);
}

/// Completes [task] and, when it recurs (`DAILY`/`WEEKLY`), clones it onto
/// the next due date (undone, unfocused, snooze cleared, subtasks NOT
/// cloned). Returns the clone id, or null when nothing cloned.
/// Callers still own reminder resync + provider invalidation.
Future<int?> completeTaskWithRecurrence(
  AppDatabase db,
  TodoTask task,
) async {
  final id = task.id;
  if (id == null) return null;
  await db.setTaskDone(id, true);
  await db.setTaskSnooze(id, null);
  final rule = task.recurrence.trim().toUpperCase();
  if (rule != 'DAILY' && rule != 'WEEKLY') return null;
  return db.insertTask(
    TodoTask(
      listId: task.listId,
      title: task.title,
      notes: task.notes,
      category: task.category,
      dueDate: nextDueDate(task.dueDate, rule),
      dueTime: task.dueTime,
      priority: task.priority,
      focus: false,
      sort: task.sort + 1,
      recurrence: rule,
    ),
  );
}
