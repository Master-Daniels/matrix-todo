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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final appBar = CustomAppBar(
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
    );

    if (!isLandscape) {
      return Scaffold(
        appBar: appBar,
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

    final sidebarWidth =
        (MediaQuery.sizeOf(context).width * 0.38).clamp(280.0, 320.0);

    return Scaffold(
      appBar: appBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeMetrics(),
                  HomeGuide(),
                  HomeActionBar(),
                ],
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}
