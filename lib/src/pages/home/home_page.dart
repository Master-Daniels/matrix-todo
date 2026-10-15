import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/search_sheet.dart';
import './constants/home_constants.dart';
import 'home_sections/home_action_bar.dart';
import 'home_sections/home_deck_list.dart';
import 'home_sections/home_guide.dart';
import 'home_sections/home_metrics.dart';

/// Today deck — `design/today_downward_card_stack` + swipe state.
/// Body only: [AppShell] owns the BottomNav.
///
/// Layout: metrics on top, scrollable deck middle, guide + action bar
/// pinned to the bottom — deck height changes (pile/strips as you page)
/// never shift the footer.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'TODAY',
        index: todayIndex(),
        leading: const CustomIconButton(icon: Icons.calendar_today),
        actions: [
          CustomIconButton(
            icon: Icons.search,
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const SearchSheet(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const HomeMetrics(),
          // Middle fills the remaining space and vertically centers the
          // deck when it is shorter than the viewport; longer content
          // (compact lists) still scrolls normally.
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: viewport.maxHeight),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HomeDeckList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const HomeGuide(),
          const HomeActionBar(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
