import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/search_sheet.dart';
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
/// Also supports filtering to a single day tapped on the week strip.
class UpcomingPage extends ConsumerStatefulWidget {
  const UpcomingPage({super.key});

  @override
  ConsumerState<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends ConsumerState<UpcomingPage> {
  /// 0 = this week (today/overdue/tomorrow), 1 = later this week + beyond.
  int _segment = 0;

  /// Optional day filter activated by tapping a cell in [DayStrip].
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final groupsAsync = ref.watch(upcomingGroupsProvider);

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final dayStrip = DayStrip(
      selectedDay: _selectedDay,
      onSelectDay: (day) {
        setState(() {
          if (_selectedDay != null &&
              dayOf(_selectedDay!).isAtSameMomentAs(dayOf(day))) {
            _selectedDay = null; // Toggle filter off
          } else {
            _selectedDay = day;
          }
        });
      },
    );

    final appBar = CustomAppBar(
      title: 'Upcoming',
      index: 'INDEX // 02 — ${_weekBadge(now)}',
      leading: const CustomIconButton(icon: Icons.calendar_month),
      actions: [
        CustomIconButton(
          icon: Icons.search,
          tooltip: 'Search tasks',
          onPressed: () => showAnimatedModalBottomSheet(
            context: context,
            builder: (_) => const SearchSheet(),
          ),
        ),
        CustomIconButton(
          icon: Icons.add,
          inverted: true,
          tooltip: 'Add task',
          onPressed: () => showAnimatedModalBottomSheet(
            context: context,
            builder: (_) => AddTaskSheet(initialDate: _selectedDay),
          ),
        ),
      ],
    );

    if (!isLandscape) {
      return Scaffold(
        appBar: appBar,
        body: ListView(
          children: [
            dayStrip,
            if (_selectedDay != null) ...[
              _buildDayFilterBanner(context, scheme, theme),
              const SizedBox(height: AppSpacing.sm),
              _buildDayTasks(context, ref, scheme, theme),
            ] else ...[
              _buildSegmentSelector(context, scheme, theme),
              const SizedBox(height: AppSpacing.sm),
              _buildGroupsTasks(context, ref, groupsAsync, now),
            ],
            const ScheduleTerminal(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    }

    final sidebarWidth =
        (MediaQuery.sizeOf(context).width * 0.36).clamp(280.0, 320.0);

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          dayStrip,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: scheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedDay != null)
                          _buildDayFilterBanner(context, scheme, theme)
                        else
                          _buildSegmentSelector(context, scheme, theme),
                        const ScheduleTerminal(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      if (_selectedDay != null)
                        _buildDayTasks(context, ref, scheme, theme)
                      else
                        _buildGroupsTasks(context, ref, groupsAsync, now),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilterBanner(
    BuildContext context,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          border: Border.all(color: scheme.primary, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'FILTER // ${weekdayShort[_selectedDay!.weekday - 1].toUpperCase()} ${fmtDayBadge(_selectedDay!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: 'Clear day filter',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedDay = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.onPrimary, width: 1),
                  ),
                  child: Text(
                    '[ CLEAR × ]',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentSelector(
    BuildContext context,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return Padding(
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
                child: Semantics(
                  button: true,
                  selected: _segment == i,
                  label: '${i == 0 ? 'This week' : 'Later'} segment',
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
                        '[ ${i == 0 ? 'This week' : 'Later'} ]${_segment == i ? ' ■' : ''}',
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTasks(
    BuildContext context,
    WidgetRef ref,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return ref.watch(tasksProvider((listId: null, done: null))).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LoadingState(label: 'Loading day tasks'),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(tasksProvider),
        ),
      ),
      data: (allTasks) {
        final iso = isoDay(_selectedDay!);
        final dayTasks = allTasks.where((t) => t.dueDate == iso).toList()
          ..sort(taskOrder);
        if (dayTasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: EmptyState(
              title: 'No tasks on this day',
              hint:
                  'Nothing scheduled for ${weekdayShort[_selectedDay!.weekday - 1]}, ${fmtDayBadge(_selectedDay!)}',
              actionLabel: 'Add task for this day',
              onAction: () => showAnimatedModalBottomSheet(
                context: context,
                builder: (_) => AddTaskSheet(initialDate: _selectedDay),
              ),
            ),
          );
        }
        return TimelineSection(
          index: '[01]',
          title:
              '${weekdayShort[_selectedDay!.weekday - 1]} // ${fmtDayBadge(_selectedDay!)}',
          tasks: dayTasks,
          showDueDate: false,
        );
      },
    );
  }

  Widget _buildGroupsTasks(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UpcomingGroups> groupsAsync,
    DateTime now,
  ) {
    return groupsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LoadingState(label: 'Loading timeline'),
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
              if (g.laterThisWeek.isNotEmpty)
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
                    actionLabel: 'Plan time block',
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
                title: 'Today // ${fmtDayBadge(dayOf(now))}',
                tasks: g.today,
              ),
            if (g.overdue.isNotEmpty)
              TimelineSection(
                index: '[!!]',
                title: 'Overdue',
                tasks: g.overdue,
                inverted: false,
                showDueDate: true,
              ),
            TimelineSection(
              index: '[01]',
              title: 'Tomorrow // ${fmtDayBadge(tomorrowDate)}',
              tasks: g.tomorrow,
            ),
          ],
        );
      },
    );
  }
}

String _weekBadge(DateTime now) {
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  final week = ((dayOfYear - now.weekday + 10) / 7).floor();
  return 'WEEK $week // ${now.year}';
}
