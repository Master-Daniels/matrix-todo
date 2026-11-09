import 'dart:convert';

/// Plain data models mirroring the `AppDatabase` schema.
///
/// Dates/times stay nullable ISO-8601 strings (matching the TEXT columns);
/// `done`/`focus` map to SQLite 0/1 integers. No extra dependencies —
/// keep these dumb so screens + repositories can build on top.
class TaskList {
  final int? id;
  final String name;
  final String code;
  final String description;
  final int sort;

  const TaskList({
    this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.sort = 0,
  });

  factory TaskList.fromMap(Map<String, Object?> map) => TaskList(
    id: map['id'] as int?,
    name: map['name'] as String,
    code: map['code'] as String,
    description: (map['description'] as String?) ?? '',
    sort: (map['sort'] as int?) ?? 0,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'code': code,
    'description': description,
    'sort': sort,
  };

  TaskList copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    int? sort,
  }) => TaskList(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    description: description ?? this.description,
    sort: sort ?? this.sort,
  );
}

/// Recurrence rule for a recurring task series. One rule row is shared by
/// every occurrence in the series via [TodoTask.seriesId].
///
/// Dates are stored as ISO `yyyy-MM-dd` strings; weekdays use 1=Mon … 7=Sun.
/// [times] holds multiple times-per-day entries (loaded separately from
/// `task_recurrence_times`).
class RecurrenceRule {
  final int? id;             // also the series_id
  final String frequency;    // DAILY | WEEKLY | MONTHLY | (YEARLY later)
  final int interval;        // every N units (default 1)
  final List<int> weekdays;  // 1=Mon … 7=Sun (used by WEEKLY; empty = every day)
  final int? monthDay;       // fixed day 1–31 (used by MONTHLY fixed-day)
  final bool monthLastDay;   // last day of month (used by MONTHLY last-day)
  final int? monthNth;       // 1–5 (used by MONTHLY nth-weekday)
  final int? monthNthWeekday;// 1=Mon … 7=Sun (used by MONTHLY nth-weekday)
  final String startDate;    // ISO yyyy-MM-dd — first possible occurrence
  final String? endDate;     // ISO yyyy-MM-dd — only when endCondition == on_date
  final String endCondition; // never | on_date
  final List<RecurrenceTime> times; // multiple times per day (HH:MM)

  const RecurrenceRule({
    this.id,
    this.frequency = 'NONE',
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay,
    this.monthLastDay = false,
    this.monthNth,
    this.monthNthWeekday,
    required this.startDate,
    this.endDate,
    this.endCondition = 'never',
    this.times = const [],
  });

  factory RecurrenceRule.fromMap(Map<String, Object?> map) => RecurrenceRule(
    id: map['id'] as int?,
    frequency: ((map['frequency'] as String?) ?? 'NONE').toUpperCase(),
    interval: (map['interval'] as int?) ?? 1,
    weekdays: _decodeWeekdays(map['weekdays']),
    monthDay: map['month_day'] as int?,
    monthLastDay: ((map['month_last_day'] as int?) ?? 0) == 1,
    monthNth: map['month_nth'] as int?,
    monthNthWeekday: map['month_nth_weekday'] as int?,
    startDate: map['start_date'] as String? ?? DateTime.now().toIso8601String().split('T').first,
    endDate: map['end_date'] as String?,
    endCondition: ((map['end_condition'] as String?) ?? 'never').toLowerCase(),
    times: const [], // loaded separately via getRecurrenceTimes
  );

  static List<int> _decodeWeekdays(Object? value) {
    if (value == null) return const [];
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.whereType<int>().toList();
        }
      } catch (_) {
        // fall through to empty
      }
    }
    if (value is List) {
      return value.whereType<int>().toList();
    }
    return const [];
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'frequency': frequency,
    'interval': interval,
    'weekdays': jsonEncode(weekdays),
    'month_day': monthDay,
    'month_last_day': monthLastDay ? 1 : 0,
    'month_nth': monthNth,
    'month_nth_weekday': monthNthWeekday,
    'start_date': startDate,
    'end_date': endDate,
    'end_condition': endCondition,
  };

  RecurrenceRule copyWith({
    int? id,
    String? frequency,
    int? interval,
    List<int>? weekdays,
    int? monthDay,
    bool? monthLastDay,
    int? monthNth,
    int? monthNthWeekday,
    String? startDate,
    String? endDate,
    String? endCondition,
    List<RecurrenceTime>? times,
  }) => RecurrenceRule(
    id: id ?? this.id,
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthDay: monthDay ?? this.monthDay,
    monthLastDay: monthLastDay ?? this.monthLastDay,
    monthNth: monthNth ?? this.monthNth,
    monthNthWeekday: monthNthWeekday ?? this.monthNthWeekday,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    endCondition: endCondition ?? this.endCondition,
    times: times ?? this.times,
  );

  /// Human-readable short summary, e.g. `↻ WEEKLY • Mon/Wed/Fri • 09:00, 17:00 • never`.
  String summary({String? timeHint}) {
    final freqLabel = switch (frequency) {
      'DAILY' => 'DAILY',
      'WEEKLY' => 'WEEKLY',
      'MONTHLY' => 'MONTHLY',
      _ => frequency,
    };
    final parts = <String>['↻ $freqLabel'];
    if (interval > 1) parts.add('every $interval');
    if (frequency == 'WEEKLY' && weekdays.isNotEmpty) {
      final names = weekdays.map((w) => weekdayShort(w)).join('/');
      parts.add(names);
    }
    if (frequency == 'MONTHLY') {
      if (monthLastDay) {
        parts.add('last day');
      } else if (monthNth != null && monthNthWeekday != null) {
        parts.add('${_ordinal(monthNth!)} ${weekdayShort(monthNthWeekday!)}');
      } else if (monthDay != null) {
        parts.add('day $monthDay');
      }
    }
    // Times: prefer explicit times list, fall back to timeHint.
    if (times.isNotEmpty) {
      final timeList = times.map((t) => t.timeOfDay).join(', ');
      parts.add(timeList);
    } else if (timeHint != null && timeHint.isNotEmpty) {
      parts.add(timeHint);
    }
    parts.add(endCondition == 'on_date' && endDate != null ? 'until $endDate' : 'never');
    return parts.join(' • ');
  }

  static String weekdayShort(int w) => switch (w) {
    1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu',
    5 => 'Fri', 6 => 'Sat', 7 => 'Sun',
    _ => '?',
  };

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }
}

/// One time-of-day entry for a recurring series (multiple times per day).
/// Stored as `HH:MM` 24-hour local time.
class RecurrenceTime {
  final int? id;
  final int ruleId;        // references task_recurrence_rules.id (series_id); 0 = not yet saved
  final String timeOfDay;  // HH:MM
  final int sort;

  const RecurrenceTime({
    this.id,
    this.ruleId = 0,
    required this.timeOfDay,
    this.sort = 0,
  });

  factory RecurrenceTime.fromMap(Map<String, Object?> map) => RecurrenceTime(
    id: map['id'] as int?,
    ruleId: map['rule_id'] as int,
    timeOfDay: map['time_of_day'] as String,
    sort: (map['sort'] as int?) ?? 0,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'rule_id': ruleId,
    'time_of_day': timeOfDay,
    'sort': sort,
  };

  RecurrenceTime copyWith({
    int? id,
    int? ruleId,
    String? timeOfDay,
    int? sort,
  }) => RecurrenceTime(
    id: id ?? this.id,
    ruleId: ruleId ?? this.ruleId,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    sort: sort ?? this.sort,
  );
}

/// A skipped occurrence within a recurring series.
/// The date (yyyy-MM-dd) will not generate a recurrence clone.
class RecurrenceException {
  final int? id;
  final int seriesId;
  final String exceptionDate; // yyyy-MM-dd

  const RecurrenceException({
    this.id,
    required this.seriesId,
    required this.exceptionDate,
  });

  factory RecurrenceException.fromMap(Map<String, Object?> map) =>
      RecurrenceException(
        id: map['id'] as int?,
        seriesId: map['series_id'] as int,
        exceptionDate: map['exception_date'] as String,
      );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'series_id': seriesId,
    'exception_date': exceptionDate,
  };

  RecurrenceException copyWith({int? id, int? seriesId, String? exceptionDate}) =>
      RecurrenceException(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        exceptionDate: exceptionDate ?? this.exceptionDate,
      );
}

class TodoTask {
  final int? id;
  final int? listId;
  final int? seriesId;          // null = standalone; rule id for recurring series
  final String title;
  final String notes;
  final String category;
  final String dueDate;
  final String? dueTime;
  final int priority;
  final bool done;
  final bool focus;
  final int sort;

  /// Recurrence rule: `NONE`, `DAILY` or `WEEKLY`. Completing a recurring
  /// task clones it onto the next due date (see `completeTaskWithRecurrence`).
  /// Kept as a legacy display hint; source of truth is [seriesId].
  final String recurrence;

  /// Epoch millis until which regular pre-reminders are replaced by a
  /// single deferred fire (notification SNOOZE action). Null = no snooze.
  final int? snoozedUntil;

  /// Optional estimated duration in minutes (e.g. 15, 30, 45, 60).
  /// When set on a timed task, a gentle "target elapsed" ping fires at
  /// `dueTime + estimatedMinutes`.
  final int? estimatedMinutes;

  const TodoTask({
    this.id,
    this.listId,
    this.seriesId,
    required this.title,
    this.notes = '',
    this.category = 'PERSONAL',
    required this.dueDate,
    this.dueTime,
    this.priority = 1,
    this.done = false,
    this.focus = false,
    this.sort = 0,
    this.recurrence = 'NONE',
    this.snoozedUntil,
    this.estimatedMinutes,
  });

  factory TodoTask.fromMap(Map<String, Object?> map) => TodoTask(
    id: map['id'] as int?,
    listId: map['list_id'] as int?,
    seriesId: map['series_id'] as int?,
    title: map['title'] as String,
    notes: (map['notes'] as String?) ?? '',
    category: (map['category'] as String?) ?? 'PERSONAL',
    dueDate: map['due_date'] as String,
    dueTime: map['due_time'] as String?,
    priority: (map['priority'] as int?) ?? 1,
    done: ((map['done'] as int?) ?? 0) == 1,
    focus: ((map['focus'] as int?) ?? 0) == 1,
    sort: (map['sort'] as int?) ?? 0,
    recurrence: ((map['recurrence'] as String?) ?? 'NONE').toUpperCase(),
    snoozedUntil: map['snoozed_until'] as int?,
    estimatedMinutes: map['estimated_minutes'] as int?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'list_id': listId,
    'series_id': seriesId,
    'title': title,
    'notes': notes,
    'category': category,
    'due_date': dueDate,
    'due_time': dueTime,
    'priority': priority,
    'done': done ? 1 : 0,
    'focus': focus ? 1 : 0,
    'sort': sort,
    'recurrence': recurrence,
    'snoozed_until': snoozedUntil,
    'estimated_minutes': estimatedMinutes,
  };

  TodoTask copyWith({
    int? id,
    int? listId,
    int? seriesId,
    String? title,
    String? notes,
    String? category,
    String? dueDate,
    String? dueTime,
    int? priority,
    bool? done,
    bool? focus,
    int? sort,
    String? recurrence,
    int? snoozedUntil,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
  }) => TodoTask(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    seriesId: seriesId ?? this.seriesId,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    category: category ?? this.category,
    dueDate: dueDate ?? this.dueDate,
    dueTime: dueTime ?? this.dueTime,
    priority: priority ?? this.priority,
    done: done ?? this.done,
    focus: focus ?? this.focus,
    sort: sort ?? this.sort,
    recurrence: recurrence ?? this.recurrence,
    snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    estimatedMinutes: clearEstimatedMinutes
        ? null
        : (estimatedMinutes ?? this.estimatedMinutes),
  );
}

class Subtask {
  final int? id;
  final int taskId;
  final String title;
  final bool done;

  const Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.done = false,
  });

  factory Subtask.fromMap(Map<String, Object?> map) => Subtask(
    id: map['id'] as int?,
    taskId: map['task_id'] as int,
    title: map['title'] as String,
    done: ((map['done'] as int?) ?? 0) == 1,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'task_id': taskId,
    'title': title,
    'done': done ? 1 : 0,
  };

  Subtask copyWith({int? id, int? taskId, String? title, bool? done}) =>
      Subtask(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        done: done ?? this.done,
      );
}
