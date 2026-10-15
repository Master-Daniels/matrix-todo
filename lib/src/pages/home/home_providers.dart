import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/task_dates.dart';

/// Category filter for the Today page: `null` shows everything (ALL),
/// otherwise an uppercase list/category key resolved live from the
/// directory lists (seeded four + user custom). No hardcoded pills —
/// filters always mirror the available lists.
final homeFilterProvider = NotifierProvider<HomeFilterNotifier, String?>(
  HomeFilterNotifier.new,
);

class HomeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? filter) {
    final v = filter?.trim().toUpperCase();
    state = (v == null || v.isEmpty) ? null : v;
  }
}

/// Matches a [TodoTask.category] value (stored uppercase in DB) against a
/// [homeFilterProvider] key. `HOME & LIVING` also matches the seeded
/// `HOME` category alias.
bool homeFilterMatches(String? filter, TodoTask task) {
  if (filter == null || filter.isEmpty) return true;
  final cat = task.category.trim().toUpperCase();
  if (cat == filter) return true;
  return filter == 'HOME & LIVING' && cat == 'HOME';
}

/// Density switch for the Today deck (grid button re-added as toggle).
/// `deck` = rounded cards with swipe physics, `compact` = flat ledger rows.
enum HomeDensity { deck, compact }

final homeDensityProvider =
    NotifierProvider<HomeDensityNotifier, HomeDensity>(
  HomeDensityNotifier.new,
);

class HomeDensityNotifier extends Notifier<HomeDensity> {
  @override
  HomeDensity build() => HomeDensity.deck;

  void toggle() =>
      state = state == HomeDensity.deck ? HomeDensity.compact : HomeDensity.deck;

  void setDensity(HomeDensity density) => state = density;
}

/// Unfiltered Today base (due-today any status + overdue undone).
/// Client-side filter deck builds on top of this — no refetch on filter.
final todayBaseTasksProvider = FutureProvider<List<TodoTask>>((ref) async {
  final all = await ref.watch(tasksProvider((listId: null, done: null)).future);
  final today = dayOf(DateTime.now());
  final filtered = all.where((t) {
    final parsed = tryParseDueDate(t.dueDate);
    if (parsed == null) return false;
    final day = dayOf(parsed);
    if (isToday(day, today)) return true;
    return !t.done && isOverdueDay(day, today);
  }).toList()
    ..sort((a, b) {
      if (a.focus != b.focus) return a.focus ? -1 : 1;
      if (a.done != b.done) return a.done ? 1 : -1;
      final sortCmp = a.sort.compareTo(b.sort);
      if (sortCmp != 0) return sortCmp;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  return filtered;
});

/// Today = due-today (any status, done struck-through) plus overdue undone.
/// Done-past and future rows are hidden. Sorted: focus first, undone,
/// done last, sort ASC. Client-side filter over [todayBaseTasksProvider].
final todayTasksProvider = FutureProvider<List<TodoTask>>((ref) async {
  final filter = ref.watch(homeFilterProvider);
  final base = await ref.watch(todayBaseTasksProvider.future);
  if (filter == null) return base;
  return base.where((t) => homeFilterMatches(filter, t)).toList();
});

/// Per-filter counts for the deck pills, derived from the unfiltered base.
/// Keys are uppercase list names; `null` is ALL.
final todayCategoryCountsProvider = FutureProvider<Map<String?, int>>((
  ref,
) async {
  final base = await ref.watch(todayBaseTasksProvider.future);
  final lists = await ref.watch(listsProvider.future);
  return {
    null: base.length,
    for (final l in lists)
      l.name.trim().toUpperCase(): base
          .where((t) => homeFilterMatches(l.name.trim().toUpperCase(), t))
          .length,
  };
});

/// {total, completed, remaining} derived from the filtered today list.
final todayCountsProvider =
    FutureProvider<({int total, int completed, int remaining})>((ref) async {
      final tasks = await ref.watch(todayTasksProvider.future);
      final completed = tasks.where((t) => t.done).length;
      return (
        total: tasks.length,
        completed: completed,
        remaining: tasks.length - completed,
      );
    });

/// Consecutive fully-completed days (WS14): counts back over days that have
/// due tasks while all are done. Days with no due tasks are skipped
/// (neither count nor break). An in-progress today doesn't break the run
/// (count starts yesterday). Zero history = 0.
/// Pure + unit-testable.
int computeStreak(List<TodoTask> tasks, DateTime now) {
  List<TodoTask> dueOn(DateTime day) => tasks.where((t) {
    final parsed = tryParseDueDate(t.dueDate);
    return parsed != null && dayOf(parsed).isAtSameMomentAs(day);
  }).toList();

  final today = dayOf(now);
  final todayDue = dueOn(today);
  var day = todayDue.isNotEmpty && todayDue.any((t) => !t.done)
      ? today.subtract(const Duration(days: 1))
      : today;
  var streak = 0;
  for (var i = 0; i < 3700; i++) {
    final due = dueOn(day);
    if (due.isEmpty) {
      day = day.subtract(const Duration(days: 1));
      continue;
    }
    if (due.any((t) => !t.done)) break;
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Live streak for the Today metrics header.
final streakProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(
    tasksProvider((listId: null, done: null)).future,
  );
  return computeStreak(all, DateTime.now());
});

/// ISO `yyyy-MM-dd` for [offset] days from today. Seeds spread across the
/// week so Upcoming has content on first launch.
String _isoDay(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Design snapshot (daily_to_do_focus/screen.png) used as seed fallback
/// when the DB is empty on first launch.
List<TodoTask> todaySeedTasks() => [
  TodoTask(
    title: 'Morning run & 20 min stretch',
    notes: '3.5 km outdoor run around the park + morning hydration.',
    category: 'PERSONAL',
    dueDate: _isoDay(0),
    dueTime: '07:30 AM',
    done: true,
    sort: 0,
  ),
  TodoTask(
    title: 'Prep presentation for team sync',
    notes:
        'Outline key milestones, review budget slide, and check demo slides.',
    category: 'WORK',
    dueDate: _isoDay(0),
    dueTime: 'DUE 14:00',
    priority: 2,
    focus: true,
    sort: 1,
  ),
  TodoTask(
    title: 'Grocery run: oat milk, sourdough, fresh fruit',
    notes: "Stop by local bakery and farmer's market on way home.",
    category: 'ERRANDS',
    dueDate: _isoDay(1),
    dueTime: 'AFTERNOON',
    sort: 2,
  ),
  TodoTask(
    title: 'Water the indoor plants',
    notes: 'Monstera, ferns in living room, and balcony herbs.',
    category: 'HOME',
    dueDate: _isoDay(0),
    dueTime: '09:00 AM',
    done: true,
    sort: 3,
  ),
  TodoTask(
    title: 'Call Mom for her birthday',
    notes: '',
    category: 'FAMILY',
    dueDate: _isoDay(3),
    dueTime: '18:00',
    sort: 4,
  ),
  TodoTask(
    title: 'Read 15 pages of book',
    notes: 'Wind down without screens before sleeping.',
    category: 'PERSONAL',
    dueDate: _isoDay(8),
    dueTime: 'NIGHT ROUTINE',
    sort: 5,
  ),
];
