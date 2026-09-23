import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/button.dart';
import '../../../widgets/progress_bar.dart';
import '../lists_providers.dart';

/// Quad-matrix directory card: index + code badge, title, description,
/// registered/completed metric strip, segmented progress, `OPEN FOLDER ->`.
/// Counts resolve live via [listCountsProvider]; `id == null` renders zeros.
class CoreListCard extends ConsumerWidget {
  final TaskList list;
  final String index;
  final VoidCallback? onOpen;

  const CoreListCard({
    super.key,
    required this.list,
    required this.index,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = list.id == null
        ? null
        : ref.watch(listCountsProvider(list.id!));

    final total = counts?.maybeWhen(data: (c) => c.total, orElse: () => 0) ?? 0;
    final done =
        counts?.maybeWhen(data: (c) => c.completed, orElse: () => 0) ?? 0;
    final hasHigh =
        counts?.maybeWhen(data: (c) => c.hasHigh, orElse: () => false) ?? false;
    final allDone = total > 0 && done == total;
    final pct = total == 0 ? 0 : (done / total * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: allDone
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
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
                '$index/',
                style: AppTypography.indexIndicator(
                  context,
                  color: scheme.secondary,
                ),
              ),
              if (allDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: scheme.primary,
                  child: Text(
                    '[ALL DONE]',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (hasHigh)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: scheme.primary,
                  child: Text(
                    'HIGH PRIORITY // ${list.code.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        border: Border.all(
                          color: scheme.primary,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      list.code.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            list.name.toUpperCase(),
            style: theme.textTheme.headlineLarge?.copyWith(
              decoration: allDone ? TextDecoration.lineThrough : null,
            ),
          ),
          if (list.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              list.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.primary, width: 1),
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$total TASKS REGISTERED',
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  '$done COMPLETED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ProgressBar(total: total == 0 ? 1 : total, completed: done),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% RESOLVED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: allDone ? FontWeight.w700 : null,
                ),
              ),
              GhostButton(label: allDone ? 'Archive log' : 'Open folder', onPressed: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}
