import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../upcoming_providers.dart';

/// `⋮` quick-options popover: bordered square trigger, PAUSE (+1 day)
/// and DELETE (red) entries. Used by every Upcoming task row/cell.
class TaskPopover extends ConsumerWidget {
  final TodoTask task;

  const TaskPopover({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      alignment: Alignment.center,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.primary, width: 1),
        ),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: scheme.primary),
          padding: EdgeInsets.zero,
          tooltip: 'Task options',
          color: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: scheme.primary, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          onSelected: (value) async {
            if (value == 'pause') {
              HapticFeedback.mediumImpact();
              await pauseTask(ref, task);
            } else if (value == 'delete' && task.id != null) {
              HapticFeedback.selectionClick();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete task?'),
                  content: Text(
                    'Delete "${task.title}"? This cannot be undone.',
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
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                HapticFeedback.heavyImpact();
                await deleteTask(ref, task.id!);
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pause',
              child: Text(
                'Snooze 1 day',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete task',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
