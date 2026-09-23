import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/button.dart';
import '../../../widgets/result_dialog.dart';

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
  ];
  final out = StringBuffer('${header.join(',')}\n');
  for (final r in rows) {
    out.writeln(header.map((h) => _csvCell('${r[h] ?? ''}')).join(','));
  }
  return out.toString();
}

/// `SEC 03` data vault: JSON+CSV export bundle (native save dialog via
/// file picker), archive import (stub), double-confirm purge.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  bool _exporting = false;
  bool _purging = false;
  bool _armed = false;

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
                    index: 'OPT_01/ DUMP',
                    title: 'EXPORT TO CSV / JSON',
                    hint: 'Schema-compliant records for local analytical work.',
                    actionLabel: _exporting ? 'EXPORTING...' : 'EXPORT BUNDLE',
                    onAction: _exporting ? null : _export,
                  ),
                ),
                Container(width: 1, color: scheme.primary),
                Expanded(
                  child: _VaultCell(
                    index: 'OPT_02/ INGEST',
                    title: 'IMPORT BACKUP',
                    hint: 'Restore serialized state from a verified payload.',
                    actionLabel: 'CHOOSE ARCHIVE',
                    onAction: () => showDialog(
                      context: context,
                      builder: (_) => const ResultDialog(
                        title: 'IMPORT QUEUED',
                        message: 'ARCHIVE RESTORE LANDS NEXT // EXPORT FIRST.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
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
                      'PURGE SCHEMA // RESET ALL DATA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _armed
                    ? 'ARMED // TAP AGAIN TO IRREVERSIBLY ZERO OUT TASKS AND CUSTOM LISTS.'
                    : 'IRREVERSIBLY ZERO OUT ALL LOCAL STORAGE CELLS, LISTS, AND METRICS.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Button(
                label: _purging
                    ? 'PURGING...'
                    : _armed
                        ? '[ TAP AGAIN TO CONFIRM ]'
                        : '[ RESET ALL DATA ]',
                kind: ButtonKind.danger,
                onPressed: _purging ? null : _purge,
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
          title: 'BUNDLE SAVED',
          message: '${tasks.length} TASKS // $jsonUri // $csvUri',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'EXPORT FAILED', message: '$e', isError: true),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _purge() async {
    if (!_armed) {
      setState(() => _armed = true);
      return;
    }
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
          title: 'SCHEMA PURGED',
          message: 'ALL CELLS ZEROED // CORE DIRECTORIES KEPT.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            ResultDialog(title: 'PURGE FAILED', message: '$e', isError: true),
      );
    } finally {
      if (mounted) {
        setState(() {
          _purging = false;
          _armed = false;
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

  const _VaultCell({
    required this.index,
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Button(
            label: actionLabel,
            kind: ButtonKind.secondary,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
