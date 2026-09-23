import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../notifications/reminder_service.dart';
import '../../widgets/bottom_nav.dart';
import '../home/home_page.dart';
import '../lists/lists_page.dart';
import '../settings/settings_page.dart';
import '../settings/settings_providers.dart';
import '../upcoming/upcoming_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A cold start from a reminder tap/action beats the default-view
      // setting and carries the focused task for the Upcoming timeline.
      final route =
          ref.read(reminderServiceProvider).consumeLaunchRoute();
      final tab = route != null
          ? 1
          : ref.read(settingsControllerProvider).defaultView.tabIndex;
      ref.read(navIndexProvider.notifier).updateIndex(tab);
      if (route?.taskId != null) {
        ref.read(focusedTaskIdProvider.notifier).set(route!.taskId);
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
