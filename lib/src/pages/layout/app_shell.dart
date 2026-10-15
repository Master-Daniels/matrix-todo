import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    // Settings are synchronous now, so this is a plain read — deferred
    // past mount because notifier writes are not allowed during build.
    // Post-frame callbacks create no test timers.
    // Cold-start notification taps are applied by main()'s background
    // warmup (it owns the single-shot launch route); here we only paint
    // the default_view tab immediately so first frame never waits.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = ref.read(settingsControllerProvider).defaultView.tabIndex;
      ref.read(navIndexProvider.notifier).updateIndex(tab);
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
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: navIndex,
        children: const [
          HomePage(),
          UpcomingPage(),
          ListsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: navIndex,
        onTap: (i) => ref.read(navIndexProvider.notifier).updateIndex(i),
        items: const [
          NavItem(label: 'Today', icon: Icons.check_box_outlined),
          NavItem(label: 'Upcoming', icon: Icons.calendar_month_outlined),
          NavItem(label: 'Lists', icon: Icons.format_list_bulleted),
          NavItem(label: 'Settings', icon: Icons.tune),
        ],
      ),
    );
  }
}
