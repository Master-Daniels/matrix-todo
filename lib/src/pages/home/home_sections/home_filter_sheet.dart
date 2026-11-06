import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../home_providers.dart';

/// Category filter sheet (declutter): full list of `ALL` + per-list
/// counts with 44px rows. Opened from the metrics `FILTER` button.
class HomeFilterSheet extends ConsumerWidget {
  const HomeFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = ref.watch(homeFilterProvider);
    final pillCounts = ref.watch(todayCategoryCountsProvider);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 2),
          left: BorderSide(color: scheme.primary, width: 2),
          right: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom > 12
            ? MediaQuery.of(context).viewPadding.bottom
            : 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Show tasks by category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 1),
                    ),
                    child: Icon(Icons.close, size: 16, color: scheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: pillCounts.maybeWhen(
                data: (map) {
                  final keys = map.keys.toList()
                    ..sort((a, b) {
                      if (a == null) return -1;
                      if (b == null) return 1;
                      return a.compareTo(b);
                    });
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final k in keys)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _FilterRow(
                            label: '${k ?? 'All'} (${map[k] ?? 0})',
                            selected: k == active,
                            onTap: () {
                              ref
                                  .read(homeFilterProvider.notifier)
                                  .setFilter(k);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.primary, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.indexIndicator(
            context,
            color: selected ? scheme.onPrimary : scheme.primary,
          ).copyWith(fontSize: 11),
        ),
      ),
    );
  }
}
