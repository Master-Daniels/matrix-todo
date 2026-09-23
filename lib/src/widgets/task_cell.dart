import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'checkbox.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomCheckbox(
                value: checked || completed,
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
                  const SizedBox(height: 4),
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
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                  if (priorityBadge != null || actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
