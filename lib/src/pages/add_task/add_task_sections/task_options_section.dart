import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models.dart';
import '../../../theme/app_borders.dart';
import '../../../theme/app_spacing.dart';
import 'priority_section.dart';
import 'recurrence_section.dart';
import 'section_label.dart';
import 'subtask_section.dart';

/// Consolidated options toolbar for Priority, Repeat, and Subtasks.
/// Keeps the sheet compact by presenting a 3-segment toolbar that expands
/// each sub-form inline on demand.
class TaskOptionsSection extends StatelessWidget {
  final int priority;
  final ValueChanged<int> onSelectPriority;

  final RecurrenceRule? rule;
  final ValueChanged<RecurrenceRule?> onChangeRule;
  final bool preGenerate;
  final ValueChanged<bool> onTogglePreGenerate;
  final int preGenerateHorizon;
  final ValueChanged<int> onChangePreGenerateHorizon;
  final bool isEditing;
  final List<String> exceptions;
  final ValueChanged<String> onToggleException;
  final VoidCallback onPickSkipDate;

  final List<DraftSubtask> drafts;
  final bool addingSubtask;
  final int editingSubtaskIndex;
  final TextEditingController subtaskController;
  final FocusNode subtaskFocus;
  final GlobalKey<FormState> subtaskFormKey;
  final void Function(int i, bool v) onToggleSubtask;
  final void Function(int i) onDeleteSubtask;
  final void Function(int i) onStartEditSubtask;
  final VoidCallback onStartAddSubtask;
  final VoidCallback onCancelSubtaskInput;
  final VoidCallback onConfirmAddSubtask;
  final VoidCallback onConfirmEditSubtask;

  final String? activeDrawer;
  final ValueChanged<String?> onToggleDrawer;

  const TaskOptionsSection({
    super.key,
    required this.priority,
    required this.onSelectPriority,
    required this.rule,
    required this.onChangeRule,
    required this.preGenerate,
    required this.onTogglePreGenerate,
    required this.preGenerateHorizon,
    required this.onChangePreGenerateHorizon,
    required this.isEditing,
    required this.exceptions,
    required this.onToggleException,
    required this.onPickSkipDate,
    required this.drafts,
    required this.addingSubtask,
    required this.editingSubtaskIndex,
    required this.subtaskController,
    required this.subtaskFocus,
    required this.subtaskFormKey,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
    required this.onStartEditSubtask,
    required this.onStartAddSubtask,
    required this.onCancelSubtaskInput,
    required this.onConfirmAddSubtask,
    required this.onConfirmEditSubtask,
    required this.activeDrawer,
    required this.onToggleDrawer,
  });

  String _formatRepeatSubtitle(RecurrenceRule? rule) {
    if (rule == null || rule.frequency == 'NONE') return 'Never';
    final freq = rule.frequency.toUpperCase();
    if (freq == 'DAILY') {
      return rule.interval == 1 ? 'Daily' : 'Every ${rule.interval}d';
    }
    if (freq == 'WEEKLY') {
      if (rule.interval == 1 &&
          rule.weekdays.length == 5 &&
          rule.weekdays.contains(1) &&
          rule.weekdays.contains(2) &&
          rule.weekdays.contains(3) &&
          rule.weekdays.contains(4) &&
          rule.weekdays.contains(5)) {
        return 'Weekdays';
      }
      return rule.interval == 1 ? 'Weekly' : 'Every ${rule.interval}w';
    }
    if (freq == 'MONTHLY') return 'Monthly';
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isPriorityOpen = activeDrawer == 'priority';
    final isRepeatOpen = activeDrawer == 'repeat';
    final isSubtasksOpen = activeDrawer == 'subtasks';

    final priorityLabel = priority == 1
        ? 'Low [1]'
        : priority == 2
            ? 'Med [2]'
            : 'High [3]';
    final repeatLabel = _formatRepeatSubtitle(rule);
    final subtasksLabel =
        '${drafts.length} ${drafts.length == 1 ? 'item' : 'items'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(
          'Task options',
          right: 'Priority · Repeat · Subtasks',
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.primary, width: 1),
            borderRadius: AppBorders.zero,
          ),
          child: Row(
            children: [
              // 1. Priority Tile
              Expanded(
                child: _ToolbarTile(
                  title: 'Priority',
                  subtitle: priorityLabel,
                  isOpen: isPriorityOpen,
                  icon: Icons.bolt,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleDrawer(isPriorityOpen ? null : 'priority');
                  },
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: scheme.primary,
              ),
              // 2. Repeat Tile
              Expanded(
                child: _ToolbarTile(
                  title: 'Repeat',
                  subtitle: repeatLabel,
                  isOpen: isRepeatOpen,
                  icon: Icons.repeat,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleDrawer(isRepeatOpen ? null : 'repeat');
                  },
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: scheme.primary,
              ),
              // 3. Subtasks Tile
              Expanded(
                child: _ToolbarTile(
                  title: 'Subtasks',
                  subtitle: subtasksLabel,
                  isOpen: isSubtasksOpen,
                  icon: Icons.checklist,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleDrawer(isSubtasksOpen ? null : 'subtasks');
                  },
                ),
              ),
            ],
          ),
        ),
        // Active Drawer Content
        if (isPriorityOpen) ...[
          const SizedBox(height: AppSpacing.sm),
          PrioritySection(
            priority: priority,
            onSelect: onSelectPriority,
          ),
        ],
        if (isRepeatOpen) ...[
          const SizedBox(height: AppSpacing.sm),
          RecurrenceSection(
            rule: rule,
            onChange: onChangeRule,
          ),
          if (rule != null && rule!.frequency != 'NONE') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.primary,
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
                        onTap: () => onTogglePreGenerate(!preGenerate),
                        child: Container(
                          width: 44,
                          height: 22,
                          decoration: BoxDecoration(
                            color: preGenerate
                                ? scheme.primary
                                : scheme.surfaceContainerLowest,
                            border: Border.all(
                              color: scheme.primary,
                              width: 1,
                            ),
                            borderRadius: AppBorders.zero,
                          ),
                          child: Align(
                            alignment: preGenerate
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: preGenerate
                                    ? scheme.onPrimary
                                    : scheme.primary,
                                borderRadius: AppBorders.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (preGenerate) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: scheme.primary,
                          width: 1,
                        ),
                        borderRadius: AppBorders.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HorizonButton(
                            icon: Icons.remove,
                            onTap: preGenerateHorizon > 1
                                ? () => onChangePreGenerateHorizon(
                                      preGenerateHorizon - 1,
                                    )
                                : null,
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: scheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$preGenerateHorizon',
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
                            color: scheme.primary,
                          ),
                          _HorizonButton(
                            icon: Icons.add,
                            onTap: preGenerateHorizon < 90
                                ? () => onChangePreGenerateHorizon(
                                      preGenerateHorizon + 1,
                                    )
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
          if (isEditing && rule != null && rule!.frequency != 'NONE') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: scheme.primary,
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
                  if (exceptions.isEmpty)
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
                        for (final exc in exceptions)
                          _ExceptionDateChip(
                            date: exc,
                            onRemove: () => onToggleException(exc),
                          ),
                        GestureDetector(
                          onTap: onPickSkipDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
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
        ],
        if (isSubtasksOpen) ...[
          const SizedBox(height: AppSpacing.sm),
          SubtaskSection(
            drafts: drafts,
            adding: addingSubtask,
            editingIndex: editingSubtaskIndex,
            controller: subtaskController,
            focusNode: subtaskFocus,
            inputFormKey: subtaskFormKey,
            onToggle: onToggleSubtask,
            onDelete: onDeleteSubtask,
            onStartEdit: onStartEditSubtask,
            onStartAdd: onStartAddSubtask,
            onCancelInput: onCancelSubtaskInput,
            onConfirmAdd: onConfirmAddSubtask,
            onConfirmEdit: onConfirmEditSubtask,
          ),
        ],
      ],
    );
  }
}

class _ToolbarTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOpen;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarTile({
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = isOpen ? scheme.primary : scheme.surface;
    final fg = isOpen ? scheme.onPrimary : scheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: fg),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  isOpen ? '▲' : '▼',
                  style: TextStyle(
                    fontSize: 8,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 10,
                color: isOpen ? fg : fg.withValues(alpha: 0.7),
                fontWeight: isOpen ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExceptionDateChip extends StatelessWidget {
  final String date;
  final VoidCallback onRemove;

  const _ExceptionDateChip({required this.date, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const months = [
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
            const Icon(Icons.close, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _HorizonButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HorizonButton({required this.icon, this.onTap});

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
