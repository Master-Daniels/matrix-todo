import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../lists_providers.dart';

/// `SEC 02` ledger row: index, name, description, `N ITEMS` badge, chevron.
/// Whole row taps through to the detail page via [onTap].
class CustomListRow extends ConsumerWidget {
  final TaskList list;
  final String index;
  final VoidCallback? onTap;

  const CustomListRow({
    super.key,
    required this.list,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = list.id == null
        ? null
        : ref.watch(listCountsProvider(list.id!));
    final total = counts?.maybeWhen(data: (c) => c.total, orElse: () => 0) ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Text(
              '$index/',
              style: AppTypography.indexIndicator(
                context,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    list.name.toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (list.description.isNotEmpty)
                    Text(
                      list.description.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border.all(color: scheme.primary, width: 1),
              ),
              child: Text(
                '$total ITEMS',
                style: theme.textTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
