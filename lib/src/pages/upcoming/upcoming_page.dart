import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/state_views.dart';
import '../add_task/add_task_sheet.dart';
import 'upcoming_providers.dart';
import 'upcoming_sections/day_strip.dart';
import 'upcoming_sections/later_week_grid.dart';
import 'upcoming_sections/next_week_accordion.dart';
import 'upcoming_sections/schedule_terminal.dart';
import 'upcoming_sections/timeline_section.dart';
import 'upcoming_sections/upcoming_format.dart';

/// Upcoming timeline — week strip, `THIS WEEK | LATER` segment, timeline
/// sections, later-week rows, next-week accordion, schedule terminal.
class UpcomingPage extends ConsumerStatefulWidget {
  const UpcomingPage({super.key});

  @override
  ConsumerState<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends ConsumerState<UpcomingPage> {
  /// 0 = this week (today/overdue/tomorrow), 1 = later this week + beyond.
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final groupsAsync = ref.watch(upcomingGroupsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'UPCOMING',
        index: 'INDEX // 02 — ${_weekBadge(now)}',
        leading: const CustomIconButton(icon: Icons.calendar_month),
        actions: [
          CustomIconButton(
            icon: Icons.add,
            inverted: true,
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const AddTaskSheet(),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const DayStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 1),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 2; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _segment = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _segment == i
                                ? scheme.primary
                                : scheme.surfaceContainerLowest,
                            border: i == 0
                                ? Border(
                                    right: BorderSide(
                                      color: scheme.primary,
                                      width: 1,
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(
                            '[ ${i == 0 ? 'THIS WEEK' : 'LATER'} ]${_segment == i ? ' ■' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _segment == i
                                  ? scheme.onPrimary
                                  : scheme.primary,
                              fontWeight: _segment == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
              if (_segment == 1) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TimelineHeader(
                      index: '[02]',
                      title:
                          'Later this week // ${fmtRange(tomorrowDate.add(const Duration(days: 1)), sunday)}',
                      count: g.laterThisWeek.length,
                    ),
                    if (g.laterThisWeek.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: EmptyState(
                          title: 'Nothing later this week',
                          hint: 'The rest of the week is clear',
                          actionLabel: '+ Plan time block',
                          onAction: () => showAnimatedModalBottomSheet(
                            context: context,
                            builder: (_) => const AddTaskSheet(),
                          ),
                        ),
                      )
                    else
                      LaterWeekGrid(tasks: g.laterThisWeek),
                    if (g.nextBeyond.isNotEmpty)
                      NextWeekAccordion(tasks: g.nextBeyond),
                  ],
                );
              }
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
                      showDueDate: true,
                    ),
                  TimelineSection(
                    index: '[01]',
                    title: 'TOMORROW // ${fmtDayBadge(tomorrowDate)}',
                    tasks: g.tomorrow,
                  ),
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
