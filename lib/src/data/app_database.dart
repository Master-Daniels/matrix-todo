import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  static const _name = 'todo.db';
  static const version = 7;

  static const tableLists = 'lists';
  static const tableTasks = 'tasks';
  static const tableSubtasks = 'subtasks';
  static const tableSettings = 'settings';
  static const tableRecurrenceRules = 'task_recurrence_rules';
  static const tableRecurrenceTimes = 'task_recurrence_times';
  static const tableRecurrenceExceptions = 'task_recurrence_exceptions';

  Database? _db;

  Future<Database> open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, _name),
      version: version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return _db!;
  }

  /// Future schema migrations go here. v2 adds the notification SNOOZE
  /// persistence (`tasks.snoozed_until`, epoch millis, nullable); v3 adds
  /// the recurrence rule (`tasks.recurrence`, `NONE` default); v4 adds
  /// the `task_recurrence_rules` table and `tasks.series_id` column; v5 adds
  /// multiple times per day (`task_recurrence_times`) and skipped-occurrence
  /// exceptions (`task_recurrence_exceptions`); v6 adds composite query indexes.
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableTasks ADD COLUMN snoozed_until INTEGER',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE $tableTasks ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'NONE'",
      );
    }
    if (oldVersion < 4) {
      // Add series_id to tasks (nullable; standalone tasks keep null).
      await db.execute(
        'ALTER TABLE $tableTasks ADD COLUMN series_id INTEGER',
      );
      // Create the recurrence rules table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableRecurrenceRules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          frequency TEXT NOT NULL DEFAULT 'NONE',
          interval INTEGER NOT NULL DEFAULT 1,
          weekdays TEXT NOT NULL DEFAULT '[]',
          month_day INTEGER,
          month_last_day INTEGER NOT NULL DEFAULT 0,
          month_nth INTEGER,
          month_nth_weekday INTEGER,
          start_date TEXT NOT NULL,
          end_date TEXT,
          end_condition TEXT NOT NULL DEFAULT 'never'
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_series_id ON $tableTasks(series_id)',
      );
    }
    if (oldVersion < 5) {
      // Multiple times per day for a recurring series.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableRecurrenceTimes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rule_id INTEGER NOT NULL REFERENCES $tableRecurrenceRules(id),
          time_of_day TEXT NOT NULL,
          sort INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recurrence_times_rule_id ON $tableRecurrenceTimes(rule_id)',
      );
      // Skipped occurrences: dates within a series that should not recur.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableRecurrenceExceptions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          series_id INTEGER NOT NULL REFERENCES $tableRecurrenceRules(id),
          exception_date TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recurrence_exceptions_series ON $tableRecurrenceExceptions(series_id)',
      );
    }
    if (oldVersion < 6) {
      // Query performance indexes for filtering tasks and subtasks.
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON $tableSubtasks(task_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_due_done ON $tableTasks(due_date, done)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_list_id ON $tableTasks(list_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_category ON $tableTasks(category)',
      );
    }
    if (oldVersion < 7) {
      // Estimated duration in minutes for target-done reminders.
      await db.execute(
        'ALTER TABLE $tableTasks ADD COLUMN estimated_minutes INTEGER',
      );
    }
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableLists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER REFERENCES $tableLists(id),
        series_id INTEGER,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'PERSONAL',
        due_date TEXT NOT NULL,
        due_time TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        done INTEGER NOT NULL DEFAULT 0,
        focus INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        recurrence TEXT NOT NULL DEFAULT 'NONE',
        snoozed_until INTEGER,
        estimated_minutes INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRecurrenceRules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequency TEXT NOT NULL DEFAULT 'NONE',
        interval INTEGER NOT NULL DEFAULT 1,
        weekdays TEXT NOT NULL DEFAULT '[]',
        month_day INTEGER,
        month_last_day INTEGER NOT NULL DEFAULT 0,
        month_nth INTEGER,
        month_nth_weekday INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT,
        end_condition TEXT NOT NULL DEFAULT 'never'
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_series_id ON $tableTasks(series_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRecurrenceTimes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rule_id INTEGER NOT NULL REFERENCES $tableRecurrenceRules(id),
        time_of_day TEXT NOT NULL,
        sort INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurrence_times_rule_id ON $tableRecurrenceTimes(rule_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableRecurrenceExceptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        series_id INTEGER NOT NULL REFERENCES $tableRecurrenceRules(id),
        exception_date TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurrence_exceptions_series ON $tableRecurrenceExceptions(series_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSubtasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL REFERENCES $tableTasks(id),
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON $tableSubtasks(task_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_due_done ON $tableTasks(due_date, done)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_list_id ON $tableTasks(list_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_category ON $tableTasks(category)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed the four core directories from the Lists design.
    await db.insert(tableLists, {
      'name': 'PERSONAL',
      'code': 'PER-SYS',
      'description': 'Daily physical maintenance, self-ops, routines.',
      'sort': 0,
    });
    await db.insert(tableLists, {
      'name': 'WORK',
      'code': 'CRIT',
      'description': 'Architecture deliverables and client contracts.',
      'sort': 1,
    });
    await db.insert(tableLists, {
      'name': 'HOME & LIVING',
      'code': 'DOMICILE',
      'description': 'Studio maintenance, inventory, utilities.',
      'sort': 2,
    });
    await db.insert(tableLists, {
      'name': 'ERRANDS',
      'code': 'LOG',
      'description': 'Logistics, transport cycles, pickups.',
      'sort': 3,
    });
    await db.insert(tableSettings, {'key': 'theme', 'value': 'light'});
    await db.insert(tableSettings, {'key': 'default_view', 'value': 'today'});
    await db.insert(tableSettings, {'key': 'week_start', 'value': 'monday'});
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---- Lists ----

  Future<List<TaskList>> getLists() async {
    final db = await open();
    final rows = await db.query(tableLists, orderBy: 'sort ASC, id ASC');
    return rows.map(TaskList.fromMap).toList();
  }

  Future<int> insertList(TaskList list) async {
    final db = await open();
    return db.insert(tableLists, list.toMap());
  }

  Future<int> updateList(TaskList list) async {
    final db = await open();
    return db.update(
      tableLists,
      list.toMap(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<int> deleteList(int id) async {
    final db = await open();
    // Manual cascade: subtasks -> tasks -> list.
    final tasks = await db.query(
      tableTasks,
      columns: ['id'],
      where: 'list_id = ?',
      whereArgs: [id],
    );
    for (final row in tasks) {
      await db.delete(
        tableSubtasks,
        where: 'task_id = ?',
        whereArgs: [row['id']],
      );
    }
    await db.delete(tableTasks, where: 'list_id = ?', whereArgs: [id]);
    return db.delete(tableLists, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Tasks ----

  Future<List<TodoTask>> getTasks({int? listId, bool? done}) async {
    final db = await open();
    final where = [
      if (listId != null) 'list_id = ?',
      if (done != null) 'done = ?',
    ].join(' AND ');
    final rows = await db.query(
      tableTasks,
      where: where.isEmpty ? null : where,
      whereArgs: [?listId, if (done != null) (done ? 1 : 0)],
      orderBy: 'sort ASC, id ASC',
    );
    return rows.map(TodoTask.fromMap).toList();
  }

  Future<int> insertTask(TodoTask task) async {
    final db = await open();
    return db.insert(tableTasks, task.toMap());
  }

  /// Single task by id, or null when missing.
  Future<TodoTask?> getTask(int id) async {
    final db = await open();
    final rows = await db.query(
      tableTasks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TodoTask.fromMap(rows.first);
  }

  Future<int> updateTask(TodoTask task) async {
    final db = await open();
    return db.update(
      tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> setTaskDone(int id, bool done) async {
    final db = await open();
    return db.update(
      tableTasks,
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setTaskFocus(int id, bool focus) async {
    final db = await open();
    return db.update(
      tableTasks,
      {'focus': focus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Persists a notification snooze (epoch millis) or clears it (null).
  /// Completing a task should clear its snooze via this method.
  Future<int> setTaskSnooze(int id, int? epochMillis) async {
    final db = await open();
    return db.update(
      tableTasks,
      {'snoozed_until': epochMillis},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Sets or updates a task's estimated duration in minutes, or clears it (null).
  Future<int> setTaskEstimatedMinutes(int id, int? minutes) async {
    final db = await open();
    return db.update(
      tableTasks,
      {'estimated_minutes': minutes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await open();
    await db.delete(tableSubtasks, where: 'task_id = ?', whereArgs: [id]);
    return db.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Recurrence rules ----

  Future<List<RecurrenceRule>> getRecurrenceRules() async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceRules,
      orderBy: 'id ASC',
    );
    return rows.map(RecurrenceRule.fromMap).toList();
  }

  /// Single rule by id (which doubles as the series_id).
  Future<RecurrenceRule?> getRecurrenceRule(int ruleId) async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceRules,
      where: 'id = ?',
      whereArgs: [ruleId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecurrenceRule.fromMap(rows.first);
  }

  /// Rules for tasks belonging to a given list (via tasks.series_id).
  Future<List<RecurrenceRule>> getRecurrenceRulesForList(int listId) async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceRules,
      where: 'id IN (SELECT series_id FROM $tableTasks WHERE list_id = ? AND series_id IS NOT NULL)',
      whereArgs: [listId],
      orderBy: 'id ASC',
    );
    return rows.map(RecurrenceRule.fromMap).toList();
  }

  Future<int> insertRecurrenceRule(RecurrenceRule rule) async {
    final db = await open();
    return db.insert(tableRecurrenceRules, rule.toMap());
  }

  Future<int> updateRecurrenceRule(RecurrenceRule rule) async {
    if (rule.id == null) return 0;
    final db = await open();
    return db.update(
      tableRecurrenceRules,
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRecurrenceRule(int ruleId) async {
    final db = await open();
    return db.delete(tableRecurrenceRules, where: 'id = ?', whereArgs: [ruleId]);
  }

  // ---- Recurrence times (multiple times per day) ----

  Future<List<RecurrenceTime>> getRecurrenceTimes(int ruleId) async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceTimes,
      where: 'rule_id = ?',
      whereArgs: [ruleId],
      orderBy: 'sort ASC, time_of_day ASC',
    );
    return rows.map(RecurrenceTime.fromMap).toList();
  }

  Future<int> insertRecurrenceTime(RecurrenceTime time) async {
    final db = await open();
    return db.insert(tableRecurrenceTimes, time.toMap());
  }

  Future<int> updateRecurrenceTime(RecurrenceTime time) async {
    if (time.id == null) return 0;
    final db = await open();
    return db.update(
      tableRecurrenceTimes,
      time.toMap(),
      where: 'id = ?',
      whereArgs: [time.id],
    );
  }

  Future<int> deleteRecurrenceTime(int timeId) async {
    final db = await open();
    return db.delete(tableRecurrenceTimes, where: 'id = ?', whereArgs: [timeId]);
  }

  /// Replace all times for a rule (used when editing the time list).
  Future<void> setRecurrenceTimes(int ruleId, List<RecurrenceTime> times) async {
    final db = await open();
    await db.delete(tableRecurrenceTimes, where: 'rule_id = ?', whereArgs: [ruleId]);
    for (final t in times) {
      await db.insert(tableRecurrenceTimes, t.toMap());
    }
  }

  // ---- Recurrence exceptions (skipped occurrences) ----

  Future<List<RecurrenceException>> getRecurrenceExceptions(int seriesId) async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceExceptions,
      where: 'series_id = ?',
      whereArgs: [seriesId],
      orderBy: 'exception_date ASC',
    );
    return rows.map(RecurrenceException.fromMap).toList();
  }

  Future<int> insertRecurrenceException(RecurrenceException exception) async {
    final db = await open();
    return db.insert(tableRecurrenceExceptions, exception.toMap());
  }

  Future<int> deleteRecurrenceException(int exceptionId) async {
    final db = await open();
    return db.delete(tableRecurrenceExceptions, where: 'id = ?', whereArgs: [exceptionId]);
  }

  /// Delete all exception dates for a series (used when replacing exceptions).
  Future<int> deleteAllRecurrenceExceptions(int seriesId) async {
    final db = await open();
    return db.delete(tableRecurrenceExceptions, where: 'series_id = ?', whereArgs: [seriesId]);
  }

  /// Check whether a given date is skipped for a series.
  Future<bool> isExceptionDate(int seriesId, String date) async {
    final db = await open();
    final rows = await db.query(
      tableRecurrenceExceptions,
      where: 'series_id = ? AND exception_date = ?',
      whereArgs: [seriesId, date],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ---- Subtasks ----

  Future<List<Subtask>> getSubtasks(int taskId) async {
    final db = await open();
    final rows = await db.query(
      tableSubtasks,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );
    return rows.map(Subtask.fromMap).toList();
  }

  Future<int> insertSubtask(Subtask subtask) async {
    final db = await open();
    return db.insert(tableSubtasks, subtask.toMap());
  }

  Future<int> updateSubtask(Subtask subtask) async {
    final db = await open();
    return db.update(
      tableSubtasks,
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> setSubtaskDone(int id, bool done) async {
    final db = await open();
    return db.update(
      tableSubtasks,
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubtask(int id) async {
    final db = await open();
    return db.delete(tableSubtasks, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Settings ----

  Future<Map<String, String>> getAllSettings() async {
    final db = await open();
    final rows = await db.query(tableSettings);
    return {for (final r in rows) (r['key'] as String): r['value'] as String};
  }

  Future<String?> getSetting(String key) async {
    final db = await open();
    final rows = await db.query(
      tableSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await open();
    await db.insert(tableSettings, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Reset-all-data: wipes tasks + subtasks and user-created lists
  /// (`sort >= 4`). Seeded core directories and settings survive.
  Future<void> purgeUserData() async {
    final db = await open();
    await db.delete(tableSubtasks);
    await db.delete(tableTasks);
    await db.delete(tableLists, where: 'sort >= ?', whereArgs: [4]);
  }
}
