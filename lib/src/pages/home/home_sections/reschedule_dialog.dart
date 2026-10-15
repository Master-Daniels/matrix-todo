import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../lists/lists_providers.dart';
import '../../settings/settings_providers.dart';
import '../../upcoming/upcoming_providers.dart';
import '../home_providers.dart';

/// Centered reschedule modal (left-swipe target): date + time pickers
/// that update the task's `dueDate` / `dueTime` on save.
Future<void> showRescheduleDialog(
  BuildContext context,
  TodoTask task,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => RescheduleDialog(task: task),
  );
}

class RescheduleDialog extends ConsumerStatefulWidget {
  final TodoTask task;

  const RescheduleDialog({super.key, required this.task});

  @override
  ConsumerState<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends ConsumerState<RescheduleDialog> {
  late DateTime _date;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = tryParseDueDate(widget.task.dueDate) ?? dayOf(DateTime.now());
    final parsed = parseEventTime(widget.task.dueTime);
    if (parsed != null) {
      _time = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = dayOf(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final id = widget.task.id;
    if (id == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final t = widget.task;
      final updated = TodoTask(
        id: t.id,
        listId: t.listId,
        title: t.title,
        notes: t.notes,
        category: t.category,
        dueDate: isoDay(_date),
        dueTime: _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')} HRS',
        priority: t.priority,
        done: t.done,
        focus: t.focus,
        sort: t.sort,
        snoozedUntil: t.snoozedUntil,
      );
      await db.updateTask(updated);
      await ref.read(reminderServiceProvider).syncAll(
            await db.getTasks(),
            enabled: ref.read(remindersEnabledProvider),
          );
      ref.invalidate(todayBaseTasksProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayCategoryCountsProvider);
      ref.invalidate(todayCountsProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(upcomingGroupsProvider);
      ref.invalidate(weekStripProvider);
      ref.invalidate(listTasksProvider);
      ref.invalidate(listCountsProvider);
      ref.invalidate(listsSummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: scheme.primary, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '[<>] RESCHEDULE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _saving ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 1),
                    ),
                    child: Text(
                      '[X] CLOSE',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _PickerCell(
              header: 'NEW DATE',
              value: isoDay(_date),
              icon: Icons.calendar_today,
              onTap: _saving ? null : _pickDate,
            ),
            const SizedBox(height: 8),
            _PickerCell(
              header: 'NEW TIME',
              value: _time == null
                  ? 'TAP TO SET'
                  : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')} HRS',
              icon: Icons.schedule,
              onTap: _saving ? null : _pickTime,
              onClear: _time == null || _saving
                  ? null
                  : () => setState(() => _time = null),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  _saving ? 'SAVING...' : 'RESCHEDULE ->',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerCell extends StatelessWidget {
  final String header;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _PickerCell({
    required this.header,
    required this.value,
    required this.icon,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.primary, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    header,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'CLEAR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            Icon(icon, size: 18, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
