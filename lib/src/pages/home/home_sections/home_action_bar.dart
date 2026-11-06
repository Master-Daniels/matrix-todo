import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../add_task/add_task_sheet.dart';
import '../home_providers.dart';

/// Bottom action row: full-width `ADD TASK` + 48px density toggle.
/// Density switch flips deck <-> compact (no separate grid page).
class HomeActionBar extends ConsumerWidget {
  const HomeActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final density = ref.watch(homeDensityProvider);
    final densityTooltip = density == HomeDensity.deck
        ? 'Switch to compact list'
        : 'Switch to card stack';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Add task',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  showAnimatedModalBottomSheet(
                    context: context,
                    builder: (_) => const AddTaskSheet(),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: scheme.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Add task',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: densityTooltip,
            child: Semantics(
              button: true,
              label: densityTooltip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(homeDensityProvider.notifier).toggle();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: density == HomeDensity.compact
                        ? scheme.primary
                        : scheme.surfaceContainerLowest,
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Icon(
                    density == HomeDensity.deck
                        ? Icons.format_list_bulleted
                        : Icons.view_agenda,
                    size: 20,
                    color: density == HomeDensity.compact
                        ? scheme.onPrimary
                        : scheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
