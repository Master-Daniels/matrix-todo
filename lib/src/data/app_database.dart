import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  static const _name = 'todo.db';
  static const version = 2;

  static const tableLists = 'lists';
  static const tableTasks = 'tasks';
  static const tableSubtasks = 'subtasks';
  static const tableSettings = 'settings';

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
  /// persistence (`tasks.snoozed_until`, epoch millis, nullable).
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableTasks ADD COLUMN snoozed_until INTEGER',
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
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'PERSONAL',
        due_date TEXT NOT NULL,
        due_time TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        done INTEGER NOT NULL DEFAULT 0,
        focus INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        snoozed_until INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSubtasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL REFERENCES $tableTasks(id),
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
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

  Future<int> deleteTask(int id) async {
    final db = await open();
    await db.delete(tableSubtasks, where: 'task_id = ?', whereArgs: [id]);
    return db.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
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
