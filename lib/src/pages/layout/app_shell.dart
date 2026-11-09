import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../widgets/bottom_nav.dart';
import '../home/home_page.dart';
import '../lists/lists_page.dart';
import '../settings/settings_page.dart';
import '../settings/settings_providers.dart';
import '../upcoming/upcoming_page.dart';
import 'onboarding_sheet.dart';

/// Single app scaffold owning the [BottomNav] so individual pages never
/// duplicate it. Content switches via [navIndexProvider] + [IndexedStack]
/// (state preserved across tabs). The launch tab comes from the
/// `default_view` setting, applied once — user taps win after that.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Orientation? _lastOrientation;
  final Set<int> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(settingsControllerProvider).defaultView.tabIndex;
    _loadedTabs.add(initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navIndexProvider.notifier).updateIndex(initialTab);
      if (!ref.read(onboardingSeenProvider)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingSheet(),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      if (orientation == Orientation.landscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);
    _loadedTabs.add(navIndex);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    const navItems = [
      NavItem(label: 'Today', icon: Icons.check_box_outlined),
      NavItem(label: 'Upcoming', icon: Icons.calendar_month_outlined),
      NavItem(label: 'Lists', icon: Icons.format_list_bulleted),
      NavItem(label: 'Settings', icon: Icons.tune),
    ];

    final content = IndexedStack(
      index: navIndex,
      children: [
        _loadedTabs.contains(0) ? const HomePage() : const SizedBox.shrink(),
        _loadedTabs.contains(1) ? const UpcomingPage() : const SizedBox.shrink(),
        _loadedTabs.contains(2) ? const ListsPage() : const SizedBox.shrink(),
        _loadedTabs.contains(3) ? const SettingsPage() : const SizedBox.shrink(),
      ],
    );

    if (isLandscape) {
      final media = MediaQuery.of(context);
      return Scaffold(
        body: Row(
          children: [
            SideNavRail(
              currentIndex: navIndex,
              onTap: (i) => ref.read(navIndexProvider.notifier).updateIndex(i),
              items: navItems,
            ),
            Expanded(
              child: MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(left: 0),
                  viewPadding: media.viewPadding.copyWith(left: 0),
                ),
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNav(
        currentIndex: navIndex,
        onTap: (i) => ref.read(navIndexProvider.notifier).updateIndex(i),
        items: navItems,
      ),
    );
  }
}
