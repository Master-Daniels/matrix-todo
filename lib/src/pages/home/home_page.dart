import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/section_header.dart';
import 'home_sections/home_action_bar.dart';
import 'home_sections/home_filter_bar.dart';
import 'home_sections/home_hero.dart';
import 'home_sections/home_progress_block.dart';
import 'home_sections/home_task_list.dart';
import './constants/home_constants.dart';

/// Today // My Day — composition of design sections in
/// `design/daily_to_do_focus`. Body only: [AppShell] owns the BottomNav.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Today // My Day',
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              border: Border.all(color: scheme.primary, width: 1),
            ),
            child: Text(
              todayBadge(),
              style: AppTypography.indexIndicator(
                context,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CustomIconButton(icon: Icons.search),
        ],
      ),
      body: ListView(
        children: [
          HomeHero(weekday: weekday()),
          const HomeProgressBlock(),
          const SectionHeader(title: 'Daily checklist', index: '[SEC 01]'),
          const HomeFilterBar(),
          const HomeTaskList(),
          const SizedBox(height: AppSpacing.md),
          const HomeActionBar(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ONE DAY AT A TIME',
                  style: AppTypography.indexIndicator(
                    context,
                    color: scheme.secondary,
                  ),
                ),
                Text(
                  'SYNCED JUST NOW',
                  style: AppTypography.indexIndicator(
                    context,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
