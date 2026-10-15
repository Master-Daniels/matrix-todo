import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'checkbox.dart';
import 'subtask_slot.dart';

/// `↻` chip visibility: DAILY or WEEKLY only.
bool _showsRecurrence(String rule) => rule == 'DAILY' || rule == 'WEEKLY';

/// Contiguous task row: shared 1px rules (no outer margin), index header
/// (`01/`), mono tag + time, Megrim title, optional description.
///
/// * completed → concrete fill + strikethrough + `DONE`
/// * active/focus → full black inversion + `FOCUS`
class TaskCell extends StatelessWidget {
  final String index;
  final String tag;
  final String time;
  final String title;
  final String? description;
  final bool completed;
  final bool active;
  final bool checked;
  final String? trailing;
  final ValueChanged<bool>? onChecked;

  /// Optional second-row actions (e.g. `HIGH PRIORITY` + `OPEN SLIDES ->`).
  /// Rendered only when non-null, so plain rows stay unchanged.
  final String? priorityBadge;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  /// Task id for the expandable subtask slot (WS8). Null hides the slot.
  final int? subtaskTaskId;

  /// Recurrence rule (`NONE` hides). Renders a `↻ DAILY` chip.
  final String recurrence;

  const TaskCell({
    super.key,
    required this.index,
    required this.tag,
    required this.time,
    required this.title,
    this.description,
    this.completed = false,
    this.active = false,
    this.checked = false,
    this.trailing,
    this.onChecked,
    this.priorityBadge,
    this.actionLabel,
    this.onActionTap,
    this.subtaskTaskId,
    this.recurrence = 'NONE',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rule = recurrence.trim().toUpperCase();

    final bg = active
        ? scheme.primary
        : completed
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerLowest;
    final fg = active ? scheme.onPrimary : scheme.primary;
    final muted = active ? scheme.inversePrimary : scheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomCheckbox(
                value: checked || completed,
                inverted: active,
                onChanged: onChecked,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        active ? '[NOW] $index' : index,
                        style: AppTypography.indexIndicator(
                          context,
                          color: muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: active ? scheme.onPrimary : scheme.primary,
                          ),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          time.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: completed ? muted : fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 1.5,
                      decorationColor: fg,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                  if (subtaskTaskId != null)
                    SubtaskSlot(taskId: subtaskTaskId, inverted: active),
                  if (_showsRecurrence(rule) ||
                      priorityBadge != null ||
                      actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_showsRecurrence(rule))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: muted),
                            ),
                            child: Text(
                              '↻ $rule',
                              style: AppTypography.indexIndicator(
                                context,
                                color: muted,
                              ),
                            ),
                          ),
                        if (_showsRecurrence(rule) &&
                            (priorityBadge != null || actionLabel != null))
                          const SizedBox(width: 8),
                        if (priorityBadge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: active
                                    ? scheme.onPrimary
                                    : scheme.primary,
                              ),
                            ),
                            child: Text(
                              priorityBadge!.toUpperCase(),
                              style: AppTypography.indexIndicator(
                                context,
                                color: fg,
                              ),
                            ),
                          ),
                        if (priorityBadge != null && actionLabel != null)
                          const SizedBox(width: 8),
                        if (actionLabel != null)
                          GestureDetector(
                            onTap: onActionTap,
                            child: Text(
                              '${actionLabel!.toUpperCase()} ->',
                              style: AppTypography.indexIndicator(
                                context,
                                color: fg,
                              ).copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              (trailing ?? (completed ? 'DONE' : '')).toUpperCase(),
              style: AppTypography.indexIndicator(context, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
