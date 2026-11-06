import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/recurrence.dart';
import '../../data/recurrence_engine.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_borders.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../home/home_providers.dart';
import '../settings/settings_providers.dart';
import '../lists/lists_providers.dart';
import '../upcoming/upcoming_providers.dart';
import 'add_task_sections/action_section.dart';
import 'add_task_sections/category_section.dart';
import 'add_task_sections/datetime_section.dart';
import 'add_task_sections/notes_section.dart';
import 'add_task_sections/priority_section.dart';
import 'add_task_sections/recurrence_section.dart';
import 'add_task_sections/section_label.dart';
import 'add_task_sections/stack_position_section.dart';
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

  /// Locks the category in create mode (e.g. opened from a list folder):
  /// the pill is display-only and taps explain how to file elsewhere.
  final String? lockedCategory;
  final int? lockedListId;
  final DateTime? initialDate;

  const AddTaskSheet({
    super.key,
    this.task,
    this.lockedCategory,
    this.lockedListId,
    this.initialDate,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  bool get isEditing => widget.task != null;

  /// Category lock applies to create mode only; edits keep full control.
  bool get _locked =>
      !isEditing && (widget.lockedCategory?.trim().isNotEmpty ?? false);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _subtaskFocus = FocusNode();
  final _subtaskFormKey = GlobalKey<FormState>();

  String _category = 'WORK';
  int? _categoryListId;
  int _priority = 3;
  RecurrenceRule? _rule; // null = NONE (no recurrence)
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  List<String> _exceptions = []; // skipped occurrence dates (ISO)
  bool _preGenerate = false; // pre-generate future occurrences
  int _preGenerateHorizon = 30; // days ahead to pre-generate
  final List<DraftSubtask> _drafts = [];
  final List<int> _initialSubtaskIds = [];
  bool _addingSubtask = false;
  int _editingIndex = -1;
  bool _saving = false;
  bool _stackTop = true;

  /// Edit scope when editing a recurring task: 'occurrence', 'future', or 'series'.
  String? _editScope;
  bool _editScopeShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _date = widget.initialDate!;
    }
    if (_locked) {
      _category = widget.lockedCategory!.trim().toUpperCase();
      _categoryListId = widget.lockedListId;
    }
    final task = widget.task;
    if (task == null) return;
    _titleController.text = task.title;
    _notesController.text = task.notes;
    _category = task.category.toUpperCase();
    _categoryListId = task.listId;
    _priority = task.priority.clamp(1, 3);
    if (task.seriesId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadRule(task.seriesId!),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showEditScopeDialog(),
      );
    } else {
      final legacy = task.recurrence.trim().toUpperCase();
      if (legacy == 'DAILY' || legacy == 'WEEKLY') {
        _rule = RecurrenceRule(
          frequency: legacy,
          interval: 1,
          weekdays: legacy == 'WEEKLY'
              ? (tryParseDueDate(task.dueDate) != null
                    ? [tryParseDueDate(task.dueDate)!.weekday]
                    : const [])
              : const [],
          startDate: task.dueDate,
          endCondition: 'never',
        );
      }
    }
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

  Future<void> _loadRule(int seriesId) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final rule = await db.getRecurrenceRule(seriesId);
      if (!mounted) return;
      if (rule == null) return;
      final times = await db.getRecurrenceTimes(seriesId);
      final exceptions = await db.getRecurrenceExceptions(seriesId);
      setState(() {
        _rule = rule.copyWith(times: times);
        _exceptions
          ..clear()
          ..addAll(exceptions.map((e) => e.exceptionDate));
      });
    } catch (_) {
      // Rule load failure is non-fatal; the sheet stays usable.
    }
  }

  /// Toggle an exception date for the current series (skip / un-skip).
  void _toggleException(String isoDate) {
    setState(() {
      if (_exceptions.contains(isoDate)) {
        _exceptions.remove(isoDate);
      } else {
        _exceptions = List<String>.from(_exceptions)..add(isoDate);
        _exceptions.sort();
      }
    });
  }

  /// Pick a date to skip (add as exception).
  Future<void> _pickSkipDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      _toggleException(isoDay(picked));
    }
  }

  /// When editing a recurring task, ask whether the edit applies to this
  /// occurrence, this and future occurrences, or the entire series.
  Future<void> _showEditScopeDialog() async {
    if (_editScopeShown || !mounted) return;
    _editScopeShown = true;
    final scope = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update repeating task'),
        content: const Text('Apply this change to:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('occurrence'),
            child: const Text('This task only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('future'),
            child: const Text('This and future repeats'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('series'),
            child: const Text('Every repeat in this series'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _editScope = scope);
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
    _notesController.dispose();
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
        title: isEditing ? 'Edit task' : 'New task',
        children: [
          TitleSection(controller: _titleController),
          NotesSection(controller: _notesController),
          CategorySection(
            selected: _category,
            locked: _locked,
            onLockedTap: _showLockedDialog,
            onSelect: (name, listId) => setState(() {
              _category = name;
              _categoryListId = listId;
            }),
          ),
          if (!isEditing)
            StackPositionSection(
              top: _stackTop,
              onSelect: (v) => setState(() => _stackTop = v),
            ),
          DateTimeSection(
            date: _date,
            time: _time,
            onPickDate: _pickDate,
            onPickTime: _pickTime,
            onSelectDate: (d) => setState(() => _date = d),
            onClearTime:
                _time == null ? null : () => setState(() => _time = null),
          ),
          PrioritySection(
            priority: _priority,
            onSelect: (p) => setState(() => _priority = p),
          ),
          RecurrenceSection(
            rule: _rule,
            onChange: (rule) => setState(() => _rule = rule),
          ),
          if (_rule != null && _rule!.frequency != 'NONE') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
                borderRadius: AppBorders.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SectionLabel('Create repeats', right: 'Optional'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Text(
                        'Create future repeats',
                        style: TextStyle(
                          fontFamily: 'Space Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _preGenerate = !_preGenerate),
                        child: Container(
                          width: 44,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _preGenerate
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLowest,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                            borderRadius: AppBorders.zero,
                          ),
                          child: Align(
                            alignment: _preGenerate
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _preGenerate
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: AppBorders.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_preGenerate) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                        borderRadius: AppBorders.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IntervalButton(
                            icon: Icons.remove,
                            onTap: _preGenerateHorizon > 1
                                ? () => setState(() => _preGenerateHorizon--)
                                : null,
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_preGenerateHorizon',
                              style: const TextStyle(
                                fontFamily: 'Space Mono',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _IntervalButton(
                            icon: Icons.add,
                            onTap: _preGenerateHorizon < 90
                                ? () => setState(() => _preGenerateHorizon++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (isEditing && _rule != null && _rule!.frequency != 'NONE') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
                borderRadius: AppBorders.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SectionLabel('Skipped dates', right: 'Manage'),
                  const SizedBox(height: AppSpacing.xs),
                  if (_exceptions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: const Text(
                        'No skipped dates',
                        style: TextStyle(
                          fontFamily: 'Space Mono',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.xs.toDouble(),
                      runSpacing: AppSpacing.xs.toDouble(),
                      children: [
                        for (final exc in _exceptions)
                          _ExceptionChip(
                            date: exc,
                            onRemove: () => _toggleException(exc),
                          ),
                        GestureDetector(
                          onTap: _pickSkipDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: AppBorders.zero,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
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
            submitLabel: isEditing ? 'Save changes' : 'Add task',
            onDelete: isEditing ? _confirmDelete : null,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final task = widget.task;
    if (task?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Delete "${task!.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await deleteTask(ref, task!.id!);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(todayCountsProvider);
      if (mounted) Navigator.of(context).pop();
    }
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

  /// Locked-category prompt: filing elsewhere means going back to the
  /// folder you want, or starting from the homepage.
  Future<void> _showLockedDialog() async {
    if (!mounted) return;
    final goBack = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Category locked'),
        content: Text(
          'This task belongs to '
          '${widget.lockedCategory?.trim().toUpperCase() ?? 'THIS LIST'}. '
          'Go back and add it to a list you want, or add it from the homepage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay here'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
    if (goBack == true && mounted) Navigator.of(context).pop();
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

  /// Persists the recurrence rule (if any) and returns its id (the series_id),
  /// or null when there is no recurrence. Handles new rules, updates to
  /// existing rules, and removal (null) of a previously recurring series.
  /// Also persists [rule.times] into `task_recurrence_times`.
  Future<int?> _saveOrUpdateRule(int? existingSeriesId) async {
    final db = ref.read(appDatabaseProvider);
    final rule = _rule;
    if (rule == null) {
      // Removing recurrence: detach the series id (rule row stays for history).
      return null;
    }
    int? ruleId;
    if (rule.id != null) {
      // Editing an existing rule in place.
      await db.updateRecurrenceRule(rule);
      ruleId = rule.id;
    } else {
      // New rule: insert it, then link.
      ruleId = await db.insertRecurrenceRule(rule);
    }
    // Persist times (replace all).
    if (ruleId != null) {
      final rid = ruleId;
      final times = rule.times.map(
        (t) =>
            RecurrenceTime(ruleId: rid, timeOfDay: t.timeOfDay, sort: t.sort),
      );
      await db.setRecurrenceTimes(ruleId, times.toList());
    }
    // Persist exceptions (replace all) for this series.
    if (ruleId != null) {
      final db = ref.read(appDatabaseProvider);
      await db.deleteAllRecurrenceExceptions(ruleId);
      for (final exc in _exceptions) {
        await db.insertRecurrenceException(
          RecurrenceException(seriesId: ruleId, exceptionDate: exc),
        );
      }
    }
    return ruleId;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final editingId = widget.task?.id;
      if (isEditing && editingId != null) {
        final task = widget.task!;
        final scope = _editScope ?? 'occurrence';

        // Save/update the rule (unless scope is occurrence-only and rule unchanged).
        final seriesId = await _saveOrUpdateRule(task.seriesId);

        // Apply edits based on scope.
        if (scope == 'series') {
          // Regenerate all future occurrences from the rule's start date.
          final exceptions = await db.getRecurrenceExceptions(seriesId!);
          final exceptionDates = exceptions.map((e) => e.exceptionDate).toSet();
          await regenerateFutureOccurrences(
            db,
            task,
            _rule!,
            regenerateAll: true,
            exceptions: exceptionDates,
          );
        } else if (scope == 'future') {
          // Update this occurrence + regenerate future occurrences.
          await db.updateTask(
            task.copyWith(
              title: _titleController.text.trim(),
              notes: _notesController.text.trim(),
              category: _category,
              listId: _categoryListId,
              dueDate: _isoDate,
              dueTime: _timeValue,
              priority: _priority,
              focus: _priority == 3,
              recurrence: _rule?.frequency ?? 'NONE',
              seriesId: seriesId,
            ),
          );
          final exceptions = await db.getRecurrenceExceptions(seriesId!);
          final exceptionDates = exceptions.map((e) => e.exceptionDate).toSet();
          await regenerateFutureOccurrences(
            db,
            task,
            _rule!,
            regenerateAll: false,
            exceptions: exceptionDates,
          );
        } else {
          // 'occurrence': update just this task, leave the rule/series as-is.
          await db.updateTask(
            task.copyWith(
              title: _titleController.text.trim(),
              notes: _notesController.text.trim(),
              category: _category,
              listId: _categoryListId,
              dueDate: _isoDate,
              dueTime: _timeValue,
              priority: _priority,
              focus: _priority == 3,
              recurrence: _rule?.frequency ?? 'NONE',
              seriesId: seriesId,
            ),
          );
        }

        // Subtasks: replace for the edited occurrence only.
        final keepIds = <int>{};
        for (final d in _drafts) {
          if (d.id != null) {
            keepIds.add(d.id!);
            await db.updateSubtask(
              Subtask(
                id: d.id,
                taskId: editingId,
                title: d.title.trim(),
                done: d.done,
              ),
            );
          } else {
            await db.insertSubtask(
              Subtask(taskId: editingId, title: d.title.trim(), done: d.done),
            );
          }
        }
        for (final removed in _initialSubtaskIds.where(
          (id) => !keepIds.contains(id),
        )) {
          await db.deleteSubtask(removed);
        }
      } else {
        final existing = await db.getTasks();
        var sort = 0;
        if (existing.isNotEmpty) {
          final sorts = existing.map((t) => t.sort).toList();
          sorts.sort();
          sort = _stackTop ? sorts.first - 1 : sorts.last + 1;
        }
        final seriesId = await _saveOrUpdateRule(null);
        // Multiple times per day: create one occurrence per time on the start date.
        final times = _rule?.times.map((t) => t.timeOfDay).toList() ?? [];
        if (times.isNotEmpty) {
          for (var i = 0; i < times.length; i++) {
            final created = TodoTask(
              title: _titleController.text.trim(),
              notes: _notesController.text.trim(),
              category: _category,
              listId: _categoryListId,
              dueDate: _isoDate,
              dueTime: '${times[i]} HRS',
              priority: _priority,
              focus: _priority == 3,
              recurrence: _rule?.frequency ?? 'NONE',
              seriesId: seriesId,
              sort: sort + i,
            );
            final id = await db.insertTask(created);
            for (final d in _drafts) {
              await db.insertSubtask(
                Subtask(taskId: id, title: d.title.trim(), done: d.done),
              );
            }
          }
        } else {
          final created = TodoTask(
            title: _titleController.text.trim(),
            notes: _notesController.text.trim(),
            category: _category,
            listId: _categoryListId,
            dueDate: _isoDate,
            dueTime: _timeValue,
            priority: _priority,
            focus: _priority == 3,
            recurrence: _rule?.frequency ?? 'NONE',
            seriesId: seriesId,
            sort: sort,
          );
          final id = await db.insertTask(created);
          for (final d in _drafts) {
            await db.insertSubtask(
              Subtask(taskId: id, title: d.title.trim(), done: d.done),
            );
          }
        }
        // Pre-generate future occurrences if enabled.
        if (_preGenerate && seriesId != null && _rule != null) {
          final existingDates = <String>{};
          final seriesTasks = await db.getTasks(done: null);
          for (final t in seriesTasks) {
            if (t.seriesId == seriesId) {
              existingDates.add(t.dueDate);
            }
          }
          final exceptions = await db.getRecurrenceExceptions(seriesId);
          final exceptionDates = exceptions.map((e) => e.exceptionDate).toSet();
          final anchorDate = tryParseDueDate(_isoDate) ?? DateTime.now();
          final rule = _rule!;
          final occs = generateOccurrences(
            rule,
            anchorDate,
            horizonDays: _preGenerateHorizon,
            exceptions: exceptionDates,
            existingDates: existingDates,
          );
          var nextSort = sort + 1;
          for (final occ in occs) {
            final iso = isoDay(occ.date);
            if (existingDates.contains(iso)) continue;
            if (exceptionDates.contains(iso)) continue;
            final created = TodoTask(
              title: _titleController.text.trim(),
              notes: _notesController.text.trim(),
              category: _category,
              listId: _categoryListId,
              dueDate: iso,
              dueTime: occ.time.isNotEmpty ? '${occ.time} HRS' : _timeValue,
              priority: _priority,
              focus: _priority == 3,
              recurrence: _rule!.frequency,
              seriesId: seriesId,
              sort: nextSort++,
            );
            final id = await db.insertTask(created);
            for (final d in _drafts) {
              await db.insertSubtask(
                Subtask(taskId: id, title: d.title.trim(), done: d.done),
              );
            }
          }
        }
      }
      // Single schedule rebuild covers pre-reminders and digest mornings.
      // Permissions are requested here — after the user's own dated task —
      // never at app launch (see _ensureReminderPermission).
      if (_timeValue != null && ref.read(remindersEnabledProvider)) {
        await _ensureReminderPermission(ref);
      }
      await ref
          .read(reminderServiceProvider)
          .syncAll(
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
          title: const Text('Enable reminders?'),
          content: const Text(
            'This task has a time set. Allow notifications so you get a '
            'reminder before and at that time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Allow'),
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
    ref.invalidate(subtasksProvider);
    ref.invalidate(todayTasksProvider);
    ref.invalidate(todayCountsProvider);
    ref.invalidate(upcomingGroupsProvider);
    ref.invalidate(weekStripProvider);
    ref.invalidate(listTasksProvider);
    ref.invalidate(listCountsProvider);
    ref.invalidate(listsSummaryProvider);
  }
}

/// Skipped-date chip for the exceptions manager in AddTaskSheet.
class _ExceptionChip extends StatelessWidget {
  final String date; // yyyy-MM-dd
  final VoidCallback onRemove;

  const _ExceptionChip({required this.date, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final months = const [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final parts = date.split('-');
    final label = '${months[int.parse(parts[1]) - 1]} ${int.parse(parts[2])}';
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: AppBorders.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Space Mono',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small + / - stepper button used for the pre-generation horizon picker.
class _IntervalButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IntervalButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: onTap != null ? scheme.primary : scheme.surfaceContainerLowest,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? scheme.onPrimary
              : scheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
