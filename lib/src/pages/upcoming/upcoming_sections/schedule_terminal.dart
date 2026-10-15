import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../add_task/add_task_sheet.dart';
import '../upcoming_providers.dart';

/// Action footprint: schedule-health line + `NEW TIME BLOCK +`.
/// ICS export lives in Settings → Data & Vault.
class ScheduleTerminal extends ConsumerWidget {
  const ScheduleTerminal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final groupsAsync = ref.watch(upcomingGroupsProvider);
    final health = groupsAsync.maybeWhen(
      data: (g) {
        final all = [
          ...g.today,
          ...g.overdue,
          ...g.tomorrow,
          ...g.laterThisWeek,
          ...g.nextBeyond,
        ];
        final done = all.where((t) => t.done).length;
        return '$done DONE / ${all.length} TOTAL // ${g.overdue.length} OVERDUE';
      },
      orElse: () => null,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (health != null) ...[
            Text(
              health,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Button(
            label: 'New time\nblock +',
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const AddTaskSheet(),
            ),
          ),
        ],
      ),
    );
  }
}
