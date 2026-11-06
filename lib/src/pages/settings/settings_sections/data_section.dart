import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/app_database.dart';
import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/button.dart';
import '../../../widgets/result_dialog.dart';
import '../../upcoming/schedule_export.dart';
import '../../upcoming/upcoming_providers.dart';
import '../settings_providers.dart';

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

/// `tasks.csv` body for [rows] of raw task maps.
String buildTasksCsv(List<Map<String, Object?>> rows) {
  const header = [
    'id',
    'list_id',
    'title',
    'notes',
    'category',
    'due_date',
    'due_time',
    'priority',
    'done',
    'focus',
    'sort',
    'recurrence',
  ];
  final out = StringBuffer('${header.join(',')}\n');
  for (final r in rows) {
    out.writeln(header.map((h) => _csvCell('${r[h] ?? ''}')).join(','));
  }
  return out.toString();
}

/// Parsed backup bundle (matches [_DataSectionState._export] output).
/// Throws [FormatException] on invalid payloads. Pure + unit-testable.
typedef BackupBundle = ({
  List<Map<String, Object?>> lists,
  List<Map<String, Object?>> tasks,
  List<Map<String, Object?>> subtasks,
  Map<String, String> settings,
});

BackupBundle parseBackupBundle(String jsonText) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! Map) throw const FormatException('NOT AN OBJECT');
  List<Map<String, Object?>> rows(Object? v, String key) {
    if (v == null) return [];
    if (v is! List) throw FormatException('BAD $key');
    return [
      for (final e in v)
        if (e is Map<String, dynamic>)
          e.map((k, val) => MapEntry(k, val as Object?))
        else
          throw FormatException('BAD $key ROW'),
    ];
  }

  final lists = rows(decoded['lists'], 'LISTS');
  final tasks = rows(decoded['tasks'], 'TASKS');
  final subtasks = rows(decoded['subtasks'], 'SUBTASKS');
  for (final l in lists) {
    if ((l['name'] as String?)?.trim().isEmpty ?? true) {
      throw const FormatException('LIST MISSING NAME');
    }
  }
  for (final t in tasks) {
    if ((t['title'] as String?)?.trim().isEmpty ?? true) {
      throw const FormatException('TASK MISSING TITLE');
    }
    if ((t['due_date'] as String?)?.trim().isEmpty ?? true) {
      throw const FormatException('TASK MISSING DUE_DATE');
    }
  }
  for (final s in subtasks) {
    if ((s['title'] as String?)?.trim().isEmpty ?? true) {
      throw const FormatException('SUBTASK MISSING TITLE');
    }
  }
  final settings = <String, String>{};
  final rawSettings = decoded['settings'];
  if (rawSettings is Map) {
    rawSettings.forEach((k, v) => settings['$k'] = '$v');
  }
  return (lists: lists, tasks: tasks, subtasks: subtasks, settings: settings);
}

/// Splits one CSV line into fields (RFC-4180 quotes). Pure helper.
List<String> _splitCsvLine(String line) {
  final fields = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buf.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      fields.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  fields.add(buf.toString());
  return fields;
}

/// Parses a hand-authored `tasks.csv` into task-shaped maps.
///
/// Header (case-insensitive, any order, extras ignored): `title*`,
/// `due_date* (YYYY-MM-DD)`, `due_time`, `notes`, `category`, `priority`
/// (1-3), `recurrence`, `done`, `focus`. Throws [FormatException] with
/// `ROW n: …` details. Pure + unit-testable.
List<Map<String, Object?>> parseTasksCsv(String csvText) {
  final lines = csvText.split(RegExp(r'\r?\n'));
  final rows = <List<String>>[];
  var pending = StringBuffer();
  var open = false;
  for (final line in lines) {
    if (open) pending.write('\n');
    pending.write(line);
    open = _unclosedQuotes(pending.toString());
    if (!open) {
      rows.add(_splitCsvLine(pending.toString()));
      pending.clear();
    }
  }
  if (pending.isNotEmpty) rows.add(_splitCsvLine(pending.toString()));
  final data = rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  if (data.isEmpty) throw const FormatException('EMPTY FILE');
  final header = data.first.map((h) => h.trim().toLowerCase()).toList();
  final titleIdx = header.indexOf('title');
  final dateIdx = header.indexOf('due_date');
  if (titleIdx < 0 || dateIdx < 0) {
    throw const FormatException('HEADER NEEDS title,due_date');
  }
  int col(String name) => header.indexOf(name);
  String cell(List<String> r, int idx) =>
      idx < 0 || idx >= r.length ? '' : r[idx].trim();

  int flag(String v, int line) {
    final t = v.trim().toLowerCase();
    if (t.isEmpty || t == '0' || t == 'false' || t == 'no') return 0;
    if (t == '1' || t == 'true' || t == 'yes') return 1;
    throw FormatException('ROW $line: BAD FLAG "$v"');
  }

  final out = <Map<String, Object?>>[];
  for (var i = 1; i < data.length; i++) {
    final line = i + 1;
    final r = data[i];
    final title = cell(r, titleIdx);
    if (title.isEmpty) throw FormatException('ROW $line: MISSING TITLE');
    final due = cell(r, dateIdx);
    if (due.isEmpty) throw FormatException('ROW $line: MISSING DUE_DATE');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(due)) {
      throw FormatException('ROW $line: BAD DUE_DATE "$due"');
    }
    final priority = int.tryParse(cell(r, col('priority')))?.clamp(1, 3) ?? 1;
    final recurrence = cell(r, col('recurrence')).toUpperCase();
    final category = cell(r, col('category'));
    final time = cell(r, col('due_time'));
    out.add({
      'title': title,
      'notes': cell(r, col('notes')),
      'category': category.isEmpty ? 'PERSONAL' : category.toUpperCase(),
      'due_date': due,
      'due_time': time.isEmpty ? null : time,
      'priority': priority,
      'done': flag(cell(r, col('done')), line),
      'focus': flag(cell(r, col('focus')), line),
      'sort': int.tryParse(cell(r, col('sort'))) ?? 0,
      'recurrence': recurrence == 'DAILY' || recurrence == 'WEEKLY'
          ? recurrence
          : 'NONE',
    });
  }
  if (out.isEmpty) throw const FormatException('NO TASKS FOUND');
  return out;
}

/// True when [text] holds an odd (unclosed) quote count.
bool _unclosedQuotes(String text) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] != '"') continue;
    if (i + 1 < text.length && text[i + 1] == '"') {
      i++;
    } else {
      count++;
    }
  }
  return count.isOdd;
}

/// `SEC 03` data vault: JSON+CSV export bundle (native save dialog via
/// file picker), JSON/CSV task ingestion (single tap, format guide),
/// double-confirm purge.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  bool _exporting = false;
  bool _exportingIcs = false;
  bool _importing = false;
  bool _purging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _VaultCell(
                    index: 'OPT_01 / BACKUP',
                    title: 'Export tasks',
                    hint: 'Save a copy of your tasks as a file',
                    actionLabel: _exporting ? 'Exporting...' : 'Save backup',
                    onAction: _exporting ? null : _export,
                  ),
                ),
                Container(width: 1, color: scheme.primary),
                Expanded(
                  child: _VaultCell(
                    index: 'OPT_02 / IMPORT',
                    title: 'Import tasks',
                    hint:
                        'Pick a JSON backup or CSV task list. New lists are '
                        'created for unknown categories.',
                    actionLabel: _importing
                        ? 'Choosing file...'
                        : 'Choose file',
                    onAction: _importing ? null : _import,
                    secondActionLabel: 'View format',
                    onSecondAction: () => _showFormat(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
          ),
          child: _VaultCell(
            index: 'OPT_03 / CALENDAR',
            title: 'Export to calendar',
            hint: 'Send upcoming tasks to another calendar app.',
            actionLabel: _exportingIcs ? 'Exporting...' : 'Save file',
            onAction: _exportingIcs ? null : _exportIcs,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reset all data',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This permanently deletes all tasks and lists. No undo.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Button(
                label: _purging ? 'Purging...' : 'Reset all data',
                kind: ButtonKind.danger,
                onPressed: _purging ? null : _confirmPurge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final lists = await db.getLists();
      final tasks = await db.getTasks();
      final subtasks = <Map<String, Object?>>[];
      for (final t in tasks) {
        if (t.id == null) continue;
        subtasks.addAll((await db.getSubtasks(t.id!)).map((s) => s.toMap()));
      }
      final settings = await db.getAllSettings();
      final stamp = DateTime.now();
      final tag =
          '${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}';
      final bundle = jsonEncode({
        'exported_at': stamp.toIso8601String(),
        'lists': lists.map((l) => l.toMap()).toList(),
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'subtasks': subtasks,
        'settings': settings,
      });
      final csv = buildTasksCsv(tasks.map((t) => t.toMap()).toList());
      final jsonUri = await FilePicker.saveFile(
        dialogTitle: 'Save backup as JSON',
        fileName: 'matrix-backup-$tag.json',
        bytes: Uint8List.fromList(utf8.encode(bundle)),
        mimeType: 'application/json',
      );
      if (jsonUri == null || !mounted) return;
      final csvUri = await FilePicker.saveFile(
        dialogTitle: 'Save tasks as CSV',
        fileName: 'matrix-tasks-$tag.csv',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
      );
      if (!mounted) return;
      if (csvUri == null) return;
      await showDialog(
        context: context,
        builder: (_) => ResultDialog(
          title: 'Backup saved',
          message: '${tasks.length} tasks saved',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'Export failed', message: '$e', isError: true),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Schedule export (moved from Upcoming terminal): undone scheduled
  /// tasks as `.ics` via the native save dialog.
  Future<void> _exportIcs() async {
    setState(() => _exportingIcs = true);
    try {
      final groups = await ref.read(upcomingGroupsProvider.future);
      final tasks = exportableTasks(groups);
      if (!mounted) return;
      if (tasks.isEmpty) {
        await showDialog(
          context: context,
          builder: (_) => const ResultDialog(
            title: 'Nothing to export',
            message: 'All clear. No undone tasks scheduled.',
          ),
        );
        return;
      }
      final path = await saveScheduleIcs(tasks);
      if (!mounted) return;
      if (path == null) {
        await showDialog(
          context: context,
          builder: (_) => const ResultDialog(
            title: 'Export cancelled',
            message: 'No file was saved. Save dialog dismissed.',
          ),
        );
        return;
      }
      await showDialog(
        context: context,
        builder: (_) => ResultDialog(
          title: 'Schedule saved',
          message: '${tasks.length} tasks saved',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'Export failed', message: '$e', isError: true),
      );
    } finally {
      if (mounted) setState(() => _exportingIcs = false);
    }
  }

  /// Task ingestion: single tap picks a `.json` backup or `.csv` task list.
  /// JSON restores lists + tasks + subtasks + settings (id-remapped merge);
  /// CSV inserts tasks only, resolving `category` to lists (auto-created).
  /// Additive in both cases — never deletes.
  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose backup file',
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );
      if (file == null) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => const ResultDialog(
            title: 'Import cancelled',
            message: 'No file was chosen. Nothing changed.',
          ),
        );
        return;
      }
      final name = file.name.toLowerCase();
      final bytes = await file.readAsBytes();
      if (name.endsWith('.csv')) {
        await _importCsv(utf8.decode(bytes));
      } else {
        await _importJson(utf8.decode(bytes));
      }
    } on FormatException catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => ResultDialog(
          title: 'Import rejected',
          message: e.message,
          isError: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'Import failed', message: '$e', isError: true),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Existing list id for [name] (case-insensitive), or inserts a custom
  /// list and returns the new id. [known] caches both pre-existing and
  /// just-created lists; returns the created count via [added].
  Future<int> _resolveListId(
    AppDatabase db,
    List<TaskList> known,
    String name,
    List<int> added,
  ) async {
    final upper = name.trim().toUpperCase();
    for (final l in known) {
      if (l.name.trim().toUpperCase() == upper && l.id != null) {
        return l.id!;
      }
    }
    final id = await db.insertList(
      TaskList(name: name.trim(), code: 'CUSTOM', sort: 4),
    );
    known.add(TaskList(id: id, name: name.trim(), code: 'CUSTOM', sort: 4));
    added.add(1);
    return id;
  }

  /// Shared finish: reminder resync, root invalidation, result dialog.
  Future<void> _finishImport({
    required int tasksAdded,
    required int subsAdded,
    required int listsAdded,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await ref
        .read(reminderServiceProvider)
        .syncAll(
          await db.getTasks(),
          enabled: ref.read(remindersEnabledProvider),
        );
    ref.invalidate(tasksProvider);
    ref.invalidate(listsProvider);
    ref.invalidate(subtasksProvider);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => ResultDialog(
        title: 'Import complete',
        message:
            '$tasksAdded tasks, $subsAdded subtasks, $listsAdded lists added.',
      ),
    );
  }

  Future<void> _importJson(String text) async {
    final bundle = parseBackupBundle(text);
    final db = ref.read(appDatabaseProvider);
    final known = await db.getLists();
    final listIds = <Object?, int>{};
    final listsAdded = <int>[];
    for (final raw in bundle.lists) {
      final name = (raw['name'] as String?)?.trim() ?? '';
      TaskList? match;
      for (final l in known) {
        if (l.name.trim().toUpperCase() == name.toUpperCase()) {
          match = l;
          break;
        }
      }
      if (match != null) {
        if (match.id != null) listIds[raw['id']] = match.id!;
      } else {
        final id = await db.insertList(
          TaskList(
            name: name,
            code: ((raw['code'] as String?)?.trim().isEmpty ?? true)
                ? 'CUSTOM'
                : (raw['code'] as String).trim(),
            description: (raw['description'] as String?) ?? '',
            sort: (raw['sort'] as int?) ?? 4,
          ),
        );
        known.add(TaskList(id: id, name: name, code: 'CUSTOM', sort: 4));
        listIds[raw['id']] = id;
        listsAdded.add(1);
      }
    }
    var tasksAdded = 0;
    final taskIds = <Object?, int>{};
    for (final raw in bundle.tasks) {
      final id = await db.insertTask(
        TodoTask(
          listId: listIds[raw['list_id']],
          title: (raw['title'] as String).trim(),
          notes: (raw['notes'] as String?) ?? '',
          category: ((raw['category'] as String?)?.trim().isEmpty ?? true)
              ? 'PERSONAL'
              : (raw['category'] as String).trim().toUpperCase(),
          dueDate: (raw['due_date'] as String).trim(),
          dueTime: raw['due_time'] as String?,
          priority: (raw['priority'] as int?) ?? 1,
          done: ((raw['done'] as int?) ?? 0) == 1,
          focus: ((raw['focus'] as int?) ?? 0) == 1,
          sort: (raw['sort'] as int?) ?? 0,
          recurrence: ((raw['recurrence'] as String?) ?? 'NONE'),
        ),
      );
      taskIds[raw['id']] = id;
      tasksAdded++;
    }
    var subsAdded = 0;
    for (final raw in bundle.subtasks) {
      final newTaskId = taskIds[raw['task_id']];
      if (newTaskId == null) continue;
      await db.insertSubtask(
        Subtask(
          taskId: newTaskId,
          title: (raw['title'] as String).trim(),
          done: ((raw['done'] as int?) ?? 0) == 1,
        ),
      );
      subsAdded++;
    }
    for (final e in bundle.settings.entries) {
      await db.setSetting(e.key, e.value);
    }
    await ref.read(settingsControllerProvider.notifier).refresh();
    await _finishImport(
      tasksAdded: tasksAdded,
      subsAdded: subsAdded,
      listsAdded: listsAdded.length,
    );
  }

  /// CSV task ingestion: each row becomes a task, `category` resolved to a
  /// list (auto-created when missing). No subtasks or settings.
  Future<void> _importCsv(String text) async {
    final rows = parseTasksCsv(text);
    final db = ref.read(appDatabaseProvider);
    final known = await db.getLists();
    final listsAdded = <int>[];
    var tasksAdded = 0;
    for (final raw in rows) {
      final listId = await _resolveListId(
        db,
        known,
        (raw['category'] as String?)?.trim().isEmpty ?? true
            ? 'PERSONAL'
            : (raw['category'] as String),
        listsAdded,
      );
      await db.insertTask(
        TodoTask(
          listId: listId,
          title: (raw['title'] as String).trim(),
          notes: (raw['notes'] as String?) ?? '',
          category: (raw['category'] as String?) ?? 'PERSONAL',
          dueDate: (raw['due_date'] as String).trim(),
          dueTime: raw['due_time'] as String?,
          priority: (raw['priority'] as int?) ?? 1,
          done: ((raw['done'] as int?) ?? 0) == 1,
          focus: ((raw['focus'] as int?) ?? 0) == 1,
          sort: (raw['sort'] as int?) ?? 0,
          recurrence: (raw['recurrence'] as String?) ?? 'NONE',
        ),
      );
      tasksAdded++;
    }
    await _finishImport(
      tasksAdded: tasksAdded,
      subsAdded: 0,
      listsAdded: listsAdded.length,
    );
  }

  /// Format guide: JSON schema (full backup) + CSV spec (easy task list).
  void _showFormat(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const body =
        'JSON — FULL BACKUP (EXPORT BUNDLE SHAPE)\n'
        '{"lists":[{"name*","code","description","sort"}],\n'
        ' "tasks":[{"title*","due_date* YYYY-MM-DD","due_time",\n'
        '  "notes","category","priority 1-3","recurrence",\n'
        '  "done 0/1","focus 0/1","sort","list_id"}],\n'
        ' "subtasks":[{"title*","task_id","done 0/1"}],\n'
        ' "settings":{...}}\n'
        '* = REQUIRED. LISTS MATCHED BY NAME.\n'
        '\n'
        'CSV — EASY TASK LIST (SPREADSHEET)\n'
        'title*,due_date* YYYY-MM-DD,due_time,notes,\n'
        'category,priority 1-3,recurrence,done,focus\n'
        '* = REQUIRED. UNKNOWN categories BECOME NEW LISTS.\n'
        'QUOTE FIELDS WITH COMMAS: "Fix sink, now".';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        elevation: 0,
        backgroundColor: scheme.surface,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File format',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                label: 'Close',
                kind: ButtonKind.secondary,
                expanded: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPurge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConfirmResetDialog(),
    );
    if (confirmed != true || !mounted) return;
    await _executePurge();
  }

  Future<void> _executePurge() async {
    setState(() => _purging = true);
    try {
      await ref.read(appDatabaseProvider).purgeUserData();
      await ref.read(reminderServiceProvider).cancelAll();
      // Root invalidation cascades through every derived provider.
      ref.invalidate(tasksProvider);
      ref.invalidate(listsProvider);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => const ResultDialog(
          title: 'Data reset',
          message: 'All tasks and lists were deleted.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'Reset failed', message: '$e', isError: true),
      );
    } finally {
      if (mounted) {
        setState(() {
          _purging = false;
        });
      }
    }
  }
}

class _VaultCell extends StatelessWidget {
  final String index;
  final String title;
  final String hint;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Optional second ghost entry (e.g. format guide) under the button.
  final String? secondActionLabel;
  final VoidCallback? onSecondAction;

  const _VaultCell({
    required this.index,
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
    this.secondActionLabel,
    this.onSecondAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index.toUpperCase(),
            style: AppTypography.indexIndicator(
              context,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Button(
            label: actionLabel,
            kind: ButtonKind.secondary,
            onPressed: onAction,
          ),
          if (secondActionLabel != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSecondAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${secondActionLabel!.toUpperCase()} ->',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// Type-to-confirm dialog for the destructive "reset all data" action.
/// The user must type DELETE (case-insensitive) to unlock the confirm button.
class _ConfirmResetDialog extends StatefulWidget {
  const _ConfirmResetDialog();

  @override
  State<_ConfirmResetDialog> createState() => _ConfirmResetDialogState();
}

class _ConfirmResetDialogState extends State<_ConfirmResetDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final match = _controller.text.trim().toUpperCase() == 'DELETE';
      if (match != _canConfirm) setState(() => _canConfirm = match);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.error, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, size: 22, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delete all data',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete every task, subtask, and list. '
              'This action cannot be undone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type DELETE to confirm',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: scheme.secondary.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: scheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: scheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: scheme.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Button(
                    label: 'Cancel',
                    kind: ButtonKind.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Button(
                    label: 'Delete everything',
                    kind: ButtonKind.danger,
                    onPressed: _canConfirm
                        ? () => Navigator.of(context).pop(true)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
