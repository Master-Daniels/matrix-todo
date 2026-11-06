import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/task_dates.dart';
import '../pages/add_task/add_task_sheet.dart';
import '../theme/app_spacing.dart';
import 'animated_bottom_sheet.dart';
import 'text_field.dart';

String _normTime(String? raw) {
  final t = parseEventTime(raw);
  if (t != null) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} HRS';
  }
  return ((raw ?? '').trim().isEmpty ? 'ANYTIME' : raw!.trim()).toUpperCase();
}

/// Shared search sheet (WS4/WS7): filters all tasks by title/notes/category.
/// Tap result closes search then opens the task editor.
class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tasksAsync = ref.watch(tasksProvider((listId: null, done: null)));
    final q = _query.trim().toLowerCase();

    return Sheet(
      title: 'Search',
      tag: 'Filter',
      children: [
        CustomTextField(
          label: 'Query',
          hint: 'Title, notes, category',
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          suffixIcon: _query.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: Icon(Icons.close, size: 18, color: scheme.primary),
                ),
        ),
        tasksAsync.when(
          loading: () => Text(
            'LOADING…',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          error: (e, _) => Text(
            'Error: $e',
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
          ),
          data: (tasks) {
            final hits = q.isEmpty
                ? <dynamic>[]
                : tasks.where((t) {
                    final hay =
                        '${t.title} ${t.notes} ${t.category}'.toLowerCase();
                    return hay.contains(q);
                  }).toList();
            if (q.isEmpty) {
              return Text(
                'Type to filter • ${tasks.length} tasks indexed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              );
            }
            if (hits.isEmpty) {
              return Text(
                'No matches for "${_query.trim()}"',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${hits.length} ${hits.length == 1 ? 'match' : 'matches'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < hits.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 1),
                    ),
                    margin: EdgeInsets.only(
                      bottom: i < hits.length - 1 ? AppSpacing.sm : 0,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final task = hits[i];
                        Navigator.of(context).pop();
                        showAnimatedModalBottomSheet(
                          context: context,
                          builder: (_) => AddTaskSheet(task: task),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hits[i].title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${hits[i].category.toUpperCase()} // ${_normTime(hits[i].dueTime)} // ${hits[i].dueDate}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
