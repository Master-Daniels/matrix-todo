import 'app_database.dart';
import 'models.dart';
import 'recurrence_engine.dart';
import 'task_dates.dart';

/// Next ISO due date for a legacy recurrence string: `DAILY` +1 day,
/// `WEEKLY` +7. Returns [iso] unchanged for `NONE`/unknown input.
///
/// Kept for backward compatibility; new code should use
/// [nextOccurrenceDate] from `recurrence_engine.dart` via a
/// [RecurrenceRule].
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

/// Completes [task] and, when it is part of a recurring series
/// ([task.seriesId] is set), clones it onto the next valid occurrence date
/// computed by the recurrence engine.
///
/// The clone is undone, unfocused, snooze-cleared, and carries the same
/// recurrence series id. Subtasks are cloned as incomplete.
///
/// Returns the clone id, or null when nothing was cloned (standalone task,
/// series ended, or missing rule).
///
/// Callers still own reminder resync + provider invalidation.
Future<int?> completeTaskWithRecurrence(
  AppDatabase db,
  TodoTask task,
) async {
  final id = task.id;
  if (id == null) return null;

  await db.setTaskDone(id, true);
  await db.setTaskSnooze(id, null);

  final seriesIdOrig = task.seriesId;

  // Legacy path: old tasks with recurrence string but no series_id. Synthesize
  // a rule from the legacy value so they still recur under the new engine.
  RecurrenceRule? rule;
  int? seriesId = seriesIdOrig;
  if (seriesId != null) {
    rule = await db.getRecurrenceRule(seriesId);
  } else {
    final legacy = task.recurrence.trim().toUpperCase();
    if (legacy == 'DAILY' || legacy == 'WEEKLY') {
      final synthesized = legacyRuleFromString(legacy, task.dueDate);
      final newId = await db.insertRecurrenceRule(synthesized);
      rule = synthesized.copyWith(id: newId);
      seriesId = rule.id;
    }
  }

  if (rule == null || seriesId == null) return null;

  // Load exception dates for this series so skipped dates are not cloned.
  final exceptions = await db.getRecurrenceExceptions(seriesId);
  final exceptionDates = exceptions.map((e) => e.exceptionDate).toSet();

  final from = tryParseDueDate(task.dueDate) ?? DateTime.now();
  final nextIso = nextOccurrenceDate(rule, from, exceptions: exceptionDates);
  if (nextIso == null) return null; // series has ended or all remaining dates are skipped

  final cloneId = await db.insertTask(
    TodoTask(
      listId: task.listId,
      seriesId: seriesId,
      title: task.title,
      notes: task.notes,
      category: task.category,
      dueDate: nextIso,
      dueTime: task.dueTime,
      priority: task.priority,
      focus: false,
      sort: task.sort + 1,
      recurrence: rule.frequency,
    ),
  );

  // Clone subtasks as incomplete.
  final subtasks = await db.getSubtasks(id);
  for (final sub in subtasks) {
    await db.insertSubtask(
      Subtask(
        taskId: cloneId,
        title: sub.title,
        done: false,
      ),
    );
  }

  return cloneId;
}

/// Regenerates future undone occurrences for a recurring series after a rule
/// change.
///
/// Deletes all undone occurrences in the series (except [anchorTask] when
/// [regenerateAll] is false), then re-creates them based on [rule] starting
/// from [startDate]. Respects [exceptions] so skipped dates are not cloned.
///
/// Returns the ids of newly created occurrences.
Future<List<int>> regenerateFutureOccurrences(
  AppDatabase db,
  TodoTask anchorTask,
  RecurrenceRule rule, {
  bool regenerateAll = false,
  Set<String>? exceptions,
}) async {
  final seriesId = anchorTask.seriesId;
  if (seriesId == null) return [];

  // Collect undone occurrences in the series.
  final allSeriesTasks = await db.getTasks(done: null);
  final seriesMembers = allSeriesTasks
      .where((t) => t.seriesId == seriesId)
      .toList();

  // Decide which to delete.
  final toDelete = <TodoTask>[];
  if (regenerateAll) {
    // Regenerate every undone occurrence from the rule's start date.
    toDelete.addAll(seriesMembers);
  } else {
    // Keep the anchor task; delete future undone occurrences after it.
    final anchorDate = tryParseDueDate(anchorTask.dueDate);
    for (final t in seriesMembers) {
      if (t.id == anchorTask.id) continue;
      final tDate = tryParseDueDate(t.dueDate);
      if (anchorDate != null &&
          tDate != null &&
          tDate.isAfter(anchorDate)) {
        toDelete.add(t);
      }
    }
  }

  for (final t in toDelete) {
    if (t.id != null) {
      await db.deleteTask(t.id!);
    }
  }

  // Determine start date for generation.
  final start = regenerateAll
      ? (tryParseDueDate(rule.startDate) ?? DateTime.now())
      : (tryParseDueDate(anchorTask.dueDate) ?? DateTime.now());

  // Generate future occurrences (up to 30 days ahead).
  final occs = generateOccurrences(
    rule,
    start,
    horizonDays: 30,
    exceptions: exceptions,
  );

  final created = <int>[];
  for (var i = 0; i < occs.length; i++) {
    final occ = occs[i];
    final iso = isoDay(occ.date);

    // For future scope, skip the anchor's own date (it already exists).
    if (!regenerateAll && iso == anchorTask.dueDate) continue;

    // Skip exception dates.
    if (exceptions != null && exceptions.contains(iso)) continue;

    final id = await db.insertTask(
      TodoTask(
        listId: anchorTask.listId,
        seriesId: seriesId,
        title: anchorTask.title,
        notes: anchorTask.notes,
        category: anchorTask.category,
        dueDate: iso,
        dueTime: occ.time.isNotEmpty ? '${occ.time} HRS' : anchorTask.dueTime,
        priority: anchorTask.priority,
        focus: false,
        sort: anchorTask.sort + 1 + i,
        recurrence: rule.frequency,
      ),
    );

    // Clone subtasks as incomplete.
    final subtasks = await db.getSubtasks(anchorTask.id!);
    for (final sub in subtasks) {
      await db.insertSubtask(
        Subtask(taskId: id, title: sub.title, done: false),
      );
    }
    created.add(id);
  }

  return created;
}
