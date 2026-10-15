import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/button.dart';
import '../../../widgets/progress_bar.dart';
import '../lists_providers.dart';

/// Directory card: `01 / CODE` index + status badge (`CRITICAL` filled /
/// `RESOLVED` / `QUEUED` / `ACTIVE` outlined), title + description,
/// `X OF Y TASKS COMPLETED` + percent + progress bar, `OPEN ->` entry.
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
    final hasActionable =
        counts?.maybeWhen(data: (c) => c.hasActionable, orElse: () => false) ??
            false;
    final allDone = total > 0 && done == total;
    final pct = total == 0 ? 0 : (done / total * 100).round();

    final String badge;
    final bool badgeFilled;
    if (hasHigh) {
      badge = 'CRITICAL';
      badgeFilled = true;
    } else if (allDone) {
      badge = 'RESOLVED';
      badgeFilled = false;
    } else if (!hasActionable) {
      badge = 'QUEUED';
      badgeFilled = false;
    } else {
      badge = 'ACTIVE';
      badgeFilled = false;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
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
              Text(
                '$index / ${list.code.toUpperCase()}',
                style: AppTypography.indexIndicator(
                  context,
                  color: scheme.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeFilled ? scheme.primary : Colors.transparent,
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeFilled ? scheme.onPrimary : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            list.name.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          if (list.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              list.description.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done OF $total TASKS COMPLETED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              ),
              Text(
                '$pct%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(total: total == 0 ? 1 : total, completed: done),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                allDone ? 'ARCHIVED' : '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                ),
              ),
              GhostButton(label: 'Open', onPressed: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}
