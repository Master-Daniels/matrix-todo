import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../add_task/add_task_sheet.dart';
import '../schedule_export.dart';
import '../upcoming_providers.dart';

/// Action footprint: schedule-health line, `.ICS` download of undone
/// scheduled tasks and `NEW TIME BLOCK +` (add-task).
class ScheduleTerminal extends ConsumerStatefulWidget {
  const ScheduleTerminal({super.key});

  @override
  ConsumerState<ScheduleTerminal> createState() => _ScheduleTerminalState();
}

class _ScheduleTerminalState extends ConsumerState<ScheduleTerminal> {
  bool _exporting = false;

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
            'SCHEDULE HEALTH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ALL FUTURE ALLOCATIONS SATISFY 100% BLUEPRINT DENSITY CHECKS.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Button(
                  label: _exporting
                      ? 'EXPORTING...'
                      : 'Export schedule\n(.ICS)',
                  kind: ButtonKind.secondary,
                  onPressed: _exporting ? null : _export,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Button(
                  label: 'New time\nblock +',
                  onPressed: () => showAnimatedModalBottomSheet(
                    context: context,
                    heightFactor: 0.92,
                    builder: (_) => const AddTaskSheet(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final groups = await ref.read(upcomingGroupsProvider.future);
      final tasks = exportableTasks(groups);
      if (!mounted) return;
      if (tasks.isEmpty) {
        await showDialog(
          context: context,
          builder: (_) => const _ResultDialog(
            title: 'NOTHING TO EXPORT',
            message: 'ALL CLEAR // NO UNDONE TASKS SCHEDULED.',
          ),
        );
        return;
      }
      final path = await saveScheduleIcs(tasks);
      if (!mounted) return;
      if (path == null) {
        await showDialog(
          context: context,
          builder: (_) => const _ResultDialog(
            title: 'EXPORT CANCELLED',
            message: 'NO FILE SAVED // SAVE DIALOG DISMISSED.',
          ),
        );
        return;
      }
      await showDialog(
        context: context,
        builder: (_) => _ResultDialog(
          title: 'SCHEDULE SAVED',
          message: '${tasks.length} TASKS // $path',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            _ResultDialog(title: 'EXPORT FAILED', message: '$e', isError: true),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;

  const _ResultDialog({
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError ? scheme.error : scheme.primary;
    return Dialog(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              message.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
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
    );
  }
}
