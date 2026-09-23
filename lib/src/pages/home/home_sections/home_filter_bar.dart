import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/chip.dart';
import '../home_providers.dart';

/// Chip row bound to [homeFilterProvider]. No strings in UI —
/// labels come from [HomeFilterX.label].
class HomeFilterBar extends ConsumerWidget {
  const HomeFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(homeFilterProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final f in HomeFilter.values)
            CustomChip(
              label: f.label,
              selected: f == active,
              onTap: () =>
                  ref.read(homeFilterProvider.notifier).setFilter(f),
            ),
        ],
      ),
    );
  }
}
