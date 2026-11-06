import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/task_dates.dart';
import '../../notifications/reminder_service.dart';
import '../settings/settings_providers.dart';

export '../../data/task_dates.dart';

int taskOrder(TodoTask a, TodoTask b) {
  if (a.done != b.done) return a.done ? 1 : -1;
  final t = (a.dueTime ?? '').compareTo(b.dueTime ?? '');
  if (t != 0) return t;
  final s = a.sort.compareTo(b.sort);
  if (s != 0) return s;
  return (a.id ?? 0).compareTo(b.id ?? 0);
}

typedef UpcomingGroups = ({
  List<TodoTask> today,
  List<TodoTask> overdue,
  List<TodoTask> tomorrow,
  List<TodoTask> laterThisWeek,
  List<TodoTask> nextBeyond,
});

/// Pure date bucketing — takes [now] for testability. [weekStart] follows
/// the calendar-cadence setting (week runs start … start+6).
/// * today: due today, undone only — still upcoming, heads the timeline.
/// * overdue: past dates, undone only.
/// * tomorrow / laterThisWeek (…week-end) / nextBeyond: any status —
///   done rows stay visible struck-through so they can be deleted.
/// * done-today + done-past rows are excluded (history lives on Today).
UpcomingGroups bucketTasks(
  List<TodoTask> tasks,
  DateTime now, {
  int weekStart = DateTime.monday,
}) {
  final today = dayOf(now);
  final tomorrow = today.add(const Duration(days: 1));
  final sunday = weekEndOf(now, weekStart);
  final todayTasks = <TodoTask>[];
  final overdue = <TodoTask>[];
  final tomorrowTasks = <TodoTask>[];
  final later = <TodoTask>[];
  final next = <TodoTask>[];
  for (final t in tasks) {
    final parsed = tryParseDueDate(t.dueDate);
    if (parsed == null) continue;
    final day = dayOf(parsed);
    if (!t.done && day.isAtSameMomentAs(today)) {
      todayTasks.add(t);
    } else if (!t.done && day.isBefore(today)) {
      overdue.add(t);
    } else if (day.isAtSameMomentAs(tomorrow)) {
      tomorrowTasks.add(t);
    } else if (day.isAfter(tomorrow) && !day.isAfter(sunday)) {
      later.add(t);
    } else if (day.isAfter(sunday)) {
      next.add(t);
    }
  }
  todayTasks.sort(taskOrder);
  overdue.sort(taskOrder);
  tomorrowTasks.sort(taskOrder);
  later.sort(taskOrder);
  next.sort(taskOrder);
  return (
    today: todayTasks,
    overdue: overdue,
    tomorrow: tomorrowTasks,
    laterThisWeek: later,
    nextBeyond: next,
  );
}

final upcomingGroupsProvider = FutureProvider<UpcomingGroups>((ref) async {
  final all = await ref.watch(
    tasksProvider((listId: null, done: null)).future,
  );
  final start = ref.watch(weekStartProvider);
  return bucketTasks(all, DateTime.now(), weekStart: start.weekday);
});

typedef StripDay = ({DateTime day, int count});

/// Current week (cadence-setting start … +6) with per-day task counts.
/// Static display.
final weekStripProvider = FutureProvider<List<StripDay>>((ref) async {
  final all = await ref.watch(
    tasksProvider((listId: null, done: null)).future,
  );
  final start = ref.watch(weekStartProvider);
  final monday = weekStartOf(DateTime.now(), start.weekday);
  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
    final iso = isoDay(day);
    return (
      day: day,
      count: all.where((t) => t.dueDate == iso).length,
    );
  });
});

/// Push [task] one day forward, then rebuilds the whole reminder schedule
/// (pre-reminders shift with it; digest mornings recompute).
Future<void> pauseTask(WidgetRef ref, TodoTask task) async {
  final db = ref.read(appDatabaseProvider);
  final base = tryParseDueDate(task.dueDate) ?? dayOf(DateTime.now());
  final next = isoDay(base.add(const Duration(days: 1)));
  await db.updateTask(task.copyWith(dueDate: next));
  await ref.read(reminderServiceProvider).syncAll(
        await db.getTasks(),
        enabled: ref.read(remindersEnabledProvider),
      );
  _invalidateSchedule(ref);
}

/// Delete [taskId] (cascades subtasks), then rebuilds the whole reminder
/// schedule so digests drop it. The explicit [cancelTask] is required:
// displayed ongoing entries are NOT auto-dismissed and the sweep only
/// covers pending ids.
Future<void> deleteTask(WidgetRef ref, int taskId) async {
  final db = ref.read(appDatabaseProvider);
  await db.deleteTask(taskId);
  final reminders = ref.read(reminderServiceProvider);
  await reminders.cancelTask(taskId);
  await reminders.syncAll(
        await db.getTasks(),
        enabled: ref.read(remindersEnabledProvider),
      );
  _invalidateSchedule(ref);
}

void _invalidateSchedule(WidgetRef ref) {
  ref.invalidate(tasksProvider);
  ref.invalidate(upcomingGroupsProvider);
  ref.invalidate(weekStripProvider);
}
