import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../add_task/add_task_sheet.dart';
import '../home_providers.dart';

/// Quick-action bar: primary ADD TASK opens [AddTaskSheet] as a brutal
/// modal, secondary FILTER resets the enum filter to ALL.
class HomeActionBar extends ConsumerWidget {
  const HomeActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 1),
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Button(
              label: '+ Add Task',
              onPressed: () => showAnimatedModalBottomSheet(
                context: context,
                heightFactor: 0.92,
                builder: (_) => const AddTaskSheet(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Button(
            label: 'Filter',
            kind: ButtonKind.secondary,
            expanded: false,
            onPressed: () =>
                ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.all),
          ),
        ],
      ),
    );
  }
}
