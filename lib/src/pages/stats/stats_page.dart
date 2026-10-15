import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/task_dates.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../home/home_providers.dart';
import '../lists/lists_providers.dart';
import '../settings/settings_providers.dart';

/// Stats // Ledger — streak hero, today + week cells, per-list progress.
/// Opened by tapping the streak in Today metrics (no bottom-nav slot).
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final streak = ref.watch(streakProvider).maybeWhen(
          data: (s) => s,
          orElse: () => 0,
        );
    final counts = ref.watch(todayCountsProvider);
    final total = counts.maybeWhen(data: (d) => d.total, orElse: () => 0);
    final completed =
        counts.maybeWhen(data: (d) => d.completed, orElse: () => 0);
    final listsAsync = ref.watch(listsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        leading: CustomIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: 'Stats // Ledger',
        index: 'INDEX // 05',
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STREAK // CONSECUTIVE FULL DAYS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak ${streak == 1 ? 'DAY' : 'DAYS'}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EMPTY DAYS SKIPPED // TODAY IN PROGRESS SPARED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Today // Week', index: '[SEC 01]'),
          _WeekCells(),
          const SectionHeader(title: 'Per list', index: '[SEC 02]'),
          listsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LoadingState(label: 'LOADING LEDGER'),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(listsProvider),
              ),
            ),
            data: (lists) {
              if (lists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: EmptyState(
                    title: 'No lists',
                    hint: 'Create one from the Lists tab',
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _TodayCell(total: total, completed: completed),
                  ),
                  for (var i = 0; i < lists.length; i++)
                    _ListRow(
                      list: lists[i],
                      index: (i + 1).toString().padLeft(2, '0'),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TodayCell extends StatelessWidget {
  final int total;
  final int completed;

  const _TodayCell({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = total == 0 ? 0 : (completed / total * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.primary, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completed / $total • $pct%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(total: total == 0 ? 1 : total, completed: completed),
        ],
      ),
    );
  }
}

class _WeekCells extends ConsumerWidget {
  const _WeekCells();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allAsync = ref.watch(tasksProvider((listId: null, done: null)));
    final weekStart = ref.watch(weekStartProvider);
    return allAsync.maybeWhen(
      data: (all) {
        final start = weekStartOf(DateTime.now(), weekStart.weekday);
        final end = start.add(const Duration(days: 6));
        final due = all.where((t) {
          final parsed = tryParseDueDate(t.dueDate);
          if (parsed == null) return false;
          final day = dayOf(parsed);
          return !day.isBefore(start) && !day.isAfter(end);
        }).toList();
        final done = due.where((t) => t.done).length;
        final pct = due.isEmpty ? 0 : (done / due.length * 100).round();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border.all(color: scheme.primary, width: 1),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'THIS WEEK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$done / ${due.length} • $pct%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  total: due.isEmpty ? 1 : due.length,
                  completed: done,
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ListRow extends ConsumerWidget {
  final TaskList list;
  final String index;

  const _ListRow({required this.list, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (list.id == null) return const SizedBox.shrink();
    final counts = ref.watch(listCountsProvider(list.id!));
    final total = counts.maybeWhen(data: (c) => c.total, orElse: () => 0);
    final done =
        counts.maybeWhen(data: (c) => c.completed, orElse: () => 0);
    final pct = total == 0 ? 0 : (done / total * 100).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.primary, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$index / ${list.name.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$done / $total • $pct%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(total: total == 0 ? 1 : total, completed: done),
        ],
      ),
    );
  }
}
