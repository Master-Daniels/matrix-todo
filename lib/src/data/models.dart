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

class TodoTask {
  final int? id;
  final int? listId;
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
  final String recurrence;

  /// Epoch millis until which regular pre-reminders are replaced by a
  /// single deferred fire (notification SNOOZE action). Null = no snooze.
  final int? snoozedUntil;

  const TodoTask({
    this.id,
    this.listId,
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
  });

  factory TodoTask.fromMap(Map<String, Object?> map) => TodoTask(
    id: map['id'] as int?,
    listId: map['list_id'] as int?,
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
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'list_id': listId,
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
  };

  TodoTask copyWith({
    int? id,
    int? listId,
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
  }) => TodoTask(
    id: id ?? this.id,
    listId: listId ?? this.listId,
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
