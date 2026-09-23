import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../notifications/reminder_service.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../home/home_providers.dart';
import '../settings/settings_providers.dart';
import '../lists/lists_providers.dart';
import '../upcoming/upcoming_providers.dart';
import 'add_task_sections/action_section.dart';
import 'add_task_sections/category_section.dart';
import 'add_task_sections/datetime_section.dart';
import 'add_task_sections/priority_section.dart';
import 'add_task_sections/subtask_section.dart';
import 'add_task_sections/title_section.dart';

/// Task editor modal (`design/add_task_modal_sheet/code.html`).
/// Always presented via `showAnimatedModalBottomSheet`, never pushed as a
/// route — it is a "page" only in folder structure (`pages/add_task/`).
/// Owns form state + pickers + submit; layout lives in `add_task_sections/`.
///
/// Create mode (`task == null`) inserts; edit mode prefills every field
/// (existing subtasks load with done-toggle, delete and tap-to-edit) and
/// diffs subtasks on save. No delete action — deletion lives on the
/// Upcoming popover.
class AddTaskSheet extends ConsumerStatefulWidget {
  final TodoTask? task;

  const AddTaskSheet({super.key, this.task});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  bool get isEditing => widget.task != null;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _subtaskFocus = FocusNode();
  final _subtaskFormKey = GlobalKey<FormState>();

  String _category = 'WORK';
  int? _categoryListId;
  int _priority = 3;
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  final List<DraftSubtask> _drafts = [];
  final List<int> _initialSubtaskIds = [];
  bool _addingSubtask = false;
  int _editingIndex = -1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task == null) return;
    _titleController.text = task.title;
    _category = task.category.toUpperCase();
    _categoryListId = task.listId;
    _priority = task.priority.clamp(1, 3);
    final parsedDate = tryParseDueDate(task.dueDate);
    if (parsedDate != null) _date = parsedDate;
    final parsedTime = parseEventTime(task.dueTime);
    if (parsedTime != null) {
      _time = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    }
    if (task.id != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSubtasks(task.id!),
      );
    }
  }

  Future<void> _loadSubtasks(int taskId) async {
    try {
      final subs = await ref.read(subtasksProvider(taskId).future);
      if (!mounted) return;
      setState(() {
        _drafts.addAll(
          subs.map((s) => DraftSubtask(s.title, id: s.id, done: s.done)),
        );
        _initialSubtaskIds.addAll(
          subs.where((s) => s.id != null).map((s) => s.id!),
        );
      });
    } catch (_) {
      // Ledger stays usable without subtasks; section shows the count as is.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskController.dispose();
    _subtaskFocus.dispose();
    super.dispose();
  }

  /// Focuses the subtask input once it mounts (post-frame: no test timers).
  void _focusSubtaskInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _subtaskFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Sheet(
        title: isEditing ? '[~] Edit Task Entry' : '[+] New Task Entry',
        children: [
          TitleSection(controller: _titleController),
          CategorySection(
            selected: _category,
            onSelect: (name, listId) => setState(() {
              _category = name;
              _categoryListId = listId;
            }),
          ),
          DateTimeSection(
            date: _date,
            time: _time,
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
          PrioritySection(
            priority: _priority,
            onSelect: (p) => setState(() => _priority = p),
          ),
          SubtaskSection(
            drafts: _drafts,
            adding: _addingSubtask,
            editingIndex: _editingIndex,
            controller: _subtaskController,
            focusNode: _subtaskFocus,
            inputFormKey: _subtaskFormKey,
            onToggle: (i, v) => setState(() => _drafts[i].done = v),
            onDelete: (i) => setState(() {
              _drafts.removeAt(i);
              if (_editingIndex == i) {
                _editingIndex = -1;
                _subtaskController.clear();
              } else if (_editingIndex > i) {
                _editingIndex -= 1;
              }
            }),
            onStartEdit: _startEdit,
            onStartAdd: _startAdd,
            onCancelInput: _cancelInput,
            onConfirmAdd: _confirmAdd,
            onConfirmEdit: _confirmEdit,
          ),
          ActionSection(
            saving: _saving,
            onSubmit: _submit,
            submitLabel:
                isEditing ? 'SAVE CHANGES -> [ENTER]' : 'COMMIT & SAVE TASK -> [ENTER]',
          ),
        ],
      ),
    );
  }

  void _startAdd() {
    setState(() {
      _editingIndex = -1;
      _addingSubtask = true;
      _subtaskController.clear();
    });
    _focusSubtaskInput();
  }

  void _startEdit(int i) {
    setState(() {
      _addingSubtask = false;
      _editingIndex = i;
      _subtaskController.text = _drafts[i].title;
    });
    _focusSubtaskInput();
  }

  void _cancelInput() {
    // Dismiss first: removing a focused field lets the scope fall back
    // through focus history (usually the title input).
    FocusScope.of(context).unfocus();
    setState(() {
      _addingSubtask = false;
      _editingIndex = -1;
      _subtaskController.clear();
    });
  }

  void _confirmAdd() {
    if (!(_subtaskFormKey.currentState?.validate() ?? false)) return;
    final title = _subtaskController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _drafts.add(DraftSubtask(title));
      _subtaskController.clear();
      _addingSubtask = false;
    });
  }

  void _confirmEdit() {
    if (!(_subtaskFormKey.currentState?.validate() ?? false)) return;
    final title = _subtaskController.text.trim();
    final i = _editingIndex;
    if (i < 0 || i >= _drafts.length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _drafts[i].title = title;
      _subtaskController.clear();
      _editingIndex = -1;
    });
  }

  Future<void> _pickDate() async {
    // Todos can't target the past: clamp the picker to today onwards.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String get _isoDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  String? get _timeValue => _time == null
      ? null
      : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')} HRS';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final editingId = widget.task?.id;
      if (isEditing && editingId != null) {
        final task = widget.task!;
        final updated = task.copyWith(
          title: _titleController.text.trim().toUpperCase(),
          category: _category,
          listId: _categoryListId,
          dueDate: _isoDate,
          dueTime: _timeValue,
          priority: _priority,
          focus: _priority == 3,
        );
        await db.updateTask(updated);
        final keepIds = <int>{};
        for (final d in _drafts) {
          if (d.id != null) {
            keepIds.add(d.id!);
            await db.updateSubtask(
              Subtask(
                id: d.id,
                taskId: editingId,
                title: d.title.toUpperCase(),
                done: d.done,
              ),
            );
          } else {
            await db.insertSubtask(
              Subtask(
                taskId: editingId,
                title: d.title.toUpperCase(),
                done: d.done,
              ),
            );
          }
        }
        for (final removed in _initialSubtaskIds.where((id) => !keepIds.contains(id))) {
          await db.deleteSubtask(removed);
        }
      } else {
        final created = TodoTask(
          title: _titleController.text.trim().toUpperCase(),
          category: _category,
          listId: _categoryListId,
          dueDate: _isoDate,
          dueTime: _timeValue,
          priority: _priority,
          focus: _priority == 3,
        );
        final id = await db.insertTask(created);
        for (final d in _drafts) {
          await db.insertSubtask(
            Subtask(taskId: id, title: d.title.toUpperCase(), done: d.done),
          );
        }
      }
      // Single schedule rebuild covers pre-reminders and digest mornings.
      // Permissions are requested here — after the user's own dated task —
      // never at app launch (see _ensureReminderPermission).
      if (_timeValue != null && ref.read(remindersEnabledProvider)) {
        await _ensureReminderPermission(ref);
      }
      await ref.read(reminderServiceProvider).syncAll(
            await db.getTasks(),
            enabled: ref.read(remindersEnabledProvider),
          );
      _invalidateSchedule(ref);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// First-task permission gate: if notifications aren't allowed yet and we
  /// haven't asked before, explain why and request (POST_NOTIFICATIONS on
  /// Android 13+, exact alarms, iOS set). Asked-once via the
  /// `notif_permission_asked` setting so denials don't nag on every save.
  Future<void> _ensureReminderPermission(WidgetRef ref) async {
    final reminders = ref.read(reminderServiceProvider);
    try {
      if (await reminders.areNotificationsEnabled()) return;
      final db = ref.read(appDatabaseProvider);
      if (await db.getSetting('notif_permission_asked') == '1') return;
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ENABLE REMINDERS?'),
          content: const Text(
            'THIS TASK HAS A DUE TIME. ALLOW NOTIFICATIONS SO THE '
            '1-HOUR + 30-MINUTE CHIMES CAN FIRE.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('NOT NOW'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ALLOW'),
            ),
          ],
        ),
      );
      await db.setSetting('notif_permission_asked', '1');
      if (proceed == true) await reminders.ensureReady();
    } catch (_) {}
  }

  void _invalidateSchedule(WidgetRef ref) {
    ref.invalidate(tasksProvider);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayCountsProvider);
    ref.invalidate(upcomingGroupsProvider);
    ref.invalidate(weekStripProvider);
    ref.invalidate(upcomingMetricsProvider);
    ref.invalidate(listTasksProvider);
    ref.invalidate(listCountsProvider);
    ref.invalidate(listsSummaryProvider);
  }
}
