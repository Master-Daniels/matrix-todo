import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../theme/app_spacing.dart';
import 'checkbox.dart';

/// Expandable subtask slot (WS8): `▢ 2/5 SUBTASKS` summary line, tap to
/// expand into a checklist. Toggling only refreshes [subtasksProvider]
/// (parent task state is unchanged). Renders nothing when the task has
/// no subtasks or no id.
class SubtaskSlot extends ConsumerStatefulWidget {
  final int? taskId;
  final bool initiallyExpanded;

  /// Renders for black/inverted parent backgrounds.
  final bool inverted;

  const SubtaskSlot({
    super.key,
    required this.taskId,
    this.initiallyExpanded = false,
    this.inverted = false,
  });

  @override
  ConsumerState<SubtaskSlot> createState() => _SubtaskSlotState();
}

class _SubtaskSlotState extends ConsumerState<SubtaskSlot> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    if (taskId == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inverted = widget.inverted;
    final fg = inverted ? scheme.onPrimary : scheme.primary;
    final muted = inverted ? scheme.inversePrimary : scheme.secondary;
    final subsAsync = ref.watch(subtasksProvider(taskId));
    return subsAsync.maybeWhen(
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();
        final done = subs.where((s) => s.done).length;
        final allDone = done == subs.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Semantics(
              button: true,
              label:
                  '${_expanded ? "Collapse" : "Expand"} checklist items, $done of ${subs.length} done',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${allDone ? '▣' : '▢'} $done/${subs.length} ${subs.length == 1 ? 'checklist item' : 'checklist items'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              for (final sub in subs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: sub.id == null
                        ? null
                        : () => _toggle(taskId, sub.id!, !sub.done),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CustomCheckbox(
                            value: sub.done,
                            inverted: inverted,
                            semanticLabel: sub.title,
                            onChanged: sub.id == null
                                ? null
                                : (v) => _toggle(taskId, sub.id!, v),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              sub.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: sub.done ? muted : fg,
                                decoration: sub.done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _toggle(int taskId, int subId, bool done) async {
    await ref.read(appDatabaseProvider).setSubtaskDone(subId, done);
    ref.invalidate(subtasksProvider(taskId));
  }
}
