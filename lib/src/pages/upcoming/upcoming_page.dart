import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../add_task/add_task_sheet.dart';
import 'upcoming_providers.dart';
import 'upcoming_sections/day_strip.dart';
import 'upcoming_sections/later_week_grid.dart';
import 'upcoming_sections/metric_banner.dart';
import 'upcoming_sections/next_week_accordion.dart';
import 'upcoming_sections/schedule_terminal.dart';
import 'upcoming_sections/timeline_section.dart';
import 'upcoming_sections/upcoming_format.dart';

/// Upcoming // Timeline — static week strip, live KPI banner, tomorrow
/// rows, later-week bento, next-week accordion, schedule terminal.
class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final groupsAsync = ref.watch(upcomingGroupsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Upcoming // Timeline',
        index: 'INDEX // 02',
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border.all(color: scheme.primary, width: 1),
            ),
            child: Text(
              _weekBadge(now),
              style: AppTypography.indexIndicator(
                context,
                color: scheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CustomIconButton(
            icon: Icons.add,
            inverted: true,
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              heightFactor: 0.92,
              builder: (_) => const AddTaskSheet(),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const DayStrip(),
          const MetricBanner(),
          groupsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LoadingState(label: 'LOADING TIMELINE'),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(upcomingGroupsProvider),
              ),
            ),
            data: (g) {
              final tomorrowDate = dayOf(now).add(const Duration(days: 1));
              final sunday = dayOf(
                now,
              ).add(Duration(days: 7 - dayOf(now).weekday));
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (g.today.isNotEmpty)
                    TimelineSection(
                      index: '[00]',
                      title: 'TODAY // ${fmtDayBadge(dayOf(now))}',
                      tasks: g.today,
                    ),
                  if (g.overdue.isNotEmpty)
                    TimelineSection(
                      index: '[!!]',
                      title: 'OVERDUE // PAST DUE',
                      tasks: g.overdue,
                      inverted: false,
                    ),
                  TimelineSection(
                    index: '[01]',
                    title: 'TOMORROW // ${fmtDayBadge(tomorrowDate)}',
                    tasks: g.tomorrow,
                  ),
                  SectionHeader(
                    title:
                        'Later this week // ${fmtRange(tomorrowDate.add(const Duration(days: 1)), sunday)}',
                    index: '[SEC 02]',
                  ),
                  if (g.laterThisWeek.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: EmptyState(
                        title: 'Nothing later this week',
                        hint: 'The rest of the week is clear',
                      ),
                    )
                  else
                    LaterWeekGrid(tasks: g.laterThisWeek),
                  if (g.nextBeyond.isNotEmpty)
                    NextWeekAccordion(tasks: g.nextBeyond),
                ],
              );
            },
          ),
          const ScheduleTerminal(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

String _weekBadge(DateTime now) {
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  final week = ((dayOfYear - now.weekday + 10) / 7).floor();
  return 'WEEK $week // ${now.year}';
}
