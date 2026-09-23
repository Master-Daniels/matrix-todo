import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/task_dates.dart';

/// Category filter for the Today page. Enum (not strings) so chips and
/// matching logic stay in sync. `all` shows everything.
enum HomeFilter { all, personal, home, work, errands, family }

extension HomeFilterX on HomeFilter {
  String get label {
    switch (this) {
      case HomeFilter.all:
        return 'ALL';
      case HomeFilter.personal:
        return 'PERSONAL';
      case HomeFilter.home:
        return 'HOME';
      case HomeFilter.work:
        return 'WORK';
      case HomeFilter.errands:
        return 'ERRANDS';
      case HomeFilter.family:
        return 'FAMILY';
    }
  }

  /// Matches a [TodoTask.category] value (stored uppercase in DB).
  /// `HOME` also matches the seeded `HOME & LIVING` list name.
  bool matches(TodoTask task) {
    if (this == HomeFilter.all) return true;
    final cat = task.category.trim().toUpperCase();
    switch (this) {
      case HomeFilter.all:
        return true;
      case HomeFilter.personal:
        return cat == 'PERSONAL';
      case HomeFilter.home:
        return cat == 'HOME' || cat == 'HOME & LIVING';
      case HomeFilter.work:
        return cat == 'WORK';
      case HomeFilter.errands:
        return cat == 'ERRANDS';
      case HomeFilter.family:
        return cat == 'FAMILY';
    }
  }
}

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => HomeFilter.all;

  void setFilter(HomeFilter filter) => state = filter;
}

/// Today = due-today (any status, done struck-through) plus overdue undone.
/// Done-past and future rows are hidden. Sorted: focus first, undone,
/// done last, sort ASC.
final todayTasksProvider = FutureProvider<List<TodoTask>>((ref) async {
  final filter = ref.watch(homeFilterProvider);
  final all = await ref.watch(tasksProvider((listId: null, done: null)).future);
  final today = dayOf(DateTime.now());
  final filtered = all.where((t) {
    if (!filter.matches(t)) return false;
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
