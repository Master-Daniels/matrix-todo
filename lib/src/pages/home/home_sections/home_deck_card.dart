import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../data/providers.dart';
import '../../../data/task_dates.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/checkbox.dart';

/// Front-most deck card from `today_downward_card_stack/code.html`:
/// rounded-2xl, 2px border, offset shadow. Meta header, title, notes,
/// subtask checklist (when the task has subtasks), `MARK COMPLETE` +
/// action, `CARD 01 OF 04` footer.
class HomeDeckCard extends ConsumerWidget {
  final TodoTask task;
  final int index;
  final int total;
  final ValueChanged<bool>? onChecked;
  final VoidCallback? onActionTap;

  /// Fixed height (deck pages): the card fills its slot and pins the
  /// footer to the bottom. Null sizes to content.
  final double? height;

  const HomeDeckCard({
    super.key,
    required this.task,
    required this.index,
    required this.total,
    this.onChecked,
    this.onActionTap,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.done;
    final focus = task.focus && !done;
    final high = task.priority >= 3;
    final parsed = tryParseDueDate(task.dueDate);
    final parsedDay = parsed == null ? null : dayOf(parsed);
    final overdue =
        !done && parsedDay != null && isOverdueDay(parsedDay, dayOf(DateTime.now()));
    final parsedTime = parseEventTime(task.dueTime);
    final normTime = parsedTime == null
        ? (task.dueTime ?? '').trim().toUpperCase()
        : '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')} HRS';
    final baseDue = normTime.isEmpty ? 'ANYTIME' : normTime;
    // Stored times sometimes already carry the prefix (`DUE 14:00` seeds):
    // never render `DUE DUE …`. Overdue prefixes the missed day.
    final String dueLabel;
    if (parsedDay != null && overdue) {
      final behind = dayOf(DateTime.now()).difference(parsedDay).inDays;
      final dayPart = behind == 1 ? 'YESTERDAY' : task.dueDate.toUpperCase();
      dueLabel = baseDue == 'ANYTIME' ? 'DUE $dayPart' : 'DUE $dayPart $baseDue';
    } else if (baseDue.toUpperCase().startsWith('DUE ')) {
      dueLabel = baseDue.toUpperCase();
    } else {
      dueLabel = 'DUE ${baseDue.toUpperCase()}';
    }

    return Container(
      height: height,
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
          // Meta header.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (focus) _Tag(text: '[NOW // FOCUS]', filled: true),
              _Tag(text: '[${task.category.toUpperCase()}]', filled: false),
              if (task.recurrence.trim().toUpperCase() == 'DAILY' ||
                  task.recurrence.trim().toUpperCase() == 'WEEKLY')
                _Tag(
                  text: '[↻ ${task.recurrence.trim().toUpperCase()}]',
                  filled: false,
                ),
              if (task.estimatedMinutes != null && task.estimatedMinutes! > 0)
                _Tag(
                  text: '[~${task.estimatedMinutes! < 60 ? '${task.estimatedMinutes}M' : '${task.estimatedMinutes! ~/ 60}H${task.estimatedMinutes! % 60 == 0 ? '' : ' ${task.estimatedMinutes! % 60}M'}'}]',
                  filled: false,
                ),
              if (high)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.error, width: 1),
                  ),
                  child: Text(
                    '[HIGH PRIORITY]',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                dueLabel,
                style: AppTypography.indexIndicator(
                  context,
                  color: overdue ? scheme.error : scheme.primary,
                ).copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: scheme.primary.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: done ? scheme.secondary : scheme.primary,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                // Near-black body copy: the secondary gray washes out
                // on light surfaces (thin Megrim strokes).
                color: done ? scheme.secondary : scheme.onSurface,
              ),
            ),
          ],
          if (task.id != null)
            ref.watch(subtasksProvider(task.id!)).maybeWhen(
                  data: (subs) => subs.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final sub in subs.take(2))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: GestureDetector(
                                    onTap: sub.id == null
                                        ? null
                                        : () => _toggleSubtask(
                                              ref,
                                              task.id!,
                                              sub.id!,
                                              !sub.done,
                                            ),
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        CustomCheckbox(
                                          value: sub.done,
                                          onChanged: sub.id == null
                                              ? null
                                              : (v) => _toggleSubtask(
                                                    ref,
                                                    task.id!,
                                                    sub.id!,
                                                    v,
                                                  ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sub.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: sub.done
                                                  ? scheme.secondary
                                                  : scheme.onSurface,
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
                              if (subs.length > 2)
                                Text(
                                  '+${subs.length - 2} MORE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
          const SizedBox(height: 16),
          Container(height: 1, color: scheme.primary.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                // One unified 48px-tall toggle: box + text share a single
                // tap path (the checkbox is display-only here) so taps
                // never double-fire or miss into the card's edit tap.
                child: GestureDetector(
                  onTap: task.id == null
                      ? null
                      : () {
                          if (!done) {
                            HapticFeedback.mediumImpact();
                          } else {
                            HapticFeedback.selectionClick();
                          }
                          onChecked?.call(!done);
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        CustomCheckbox(value: done, onChanged: null),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Mark complete',
                            style: AppTypography.indexIndicator(
                              context,
                              color: scheme.primary,
                            ).copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onActionTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        focus ? 'Open' : 'Edit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Fixed-height mode pins the footer to the bottom edge so
          // every deck card is identical; intrinsic mode keeps a 12px gap.
          if (height == null)
            const SizedBox(height: 12)
          else
            const Expanded(child: SizedBox.shrink()),
          Container(height: 1, color: scheme.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CARD ${index.toString().padLeft(2, '0')} OF ${total.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe or tap for more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubtask(
    WidgetRef ref,
    int taskId,
    int subId,
    bool done,
  ) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSubtaskDone(subId, done);
    ref.invalidate(subtasksProvider(taskId));
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool filled;

  const _Tag({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? scheme.primary : Colors.transparent,
        border: Border.all(color: scheme.primary, width: 1),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: filled ? scheme.onPrimary : scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
