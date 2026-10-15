import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/data/providers.dart';
import 'src/data/recurrence.dart';
import 'src/notifications/reminder_service.dart';
import 'src/pages/home/home_providers.dart';
import 'src/pages/layout/app_shell.dart';
import 'src/pages/settings/settings_providers.dart';
import 'src/pages/upcoming/upcoming_providers.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load settings before the first frame so the saved theme is correct
  // immediately — no launch flash. Single small SQLite read; the heavy
  // work (tz data, plugin init, schedule heal) warms in the background
  // after the first frame so the app opens instantly.
  final container = ProviderContainer();
  try {
    await container.read(settingsControllerProvider.notifier).refresh();
  } catch (_) {}
  runApp(
    UncontrolledProviderScope(container: container, child: const TodoApp()),
  );
  // Fire-and-forget: never blocks first paint. Errors stay silent — a dead
  // plugin must never crash launch.
  _warmReminders(container);
}

/// Background reminder warmup: permission-free init (channels + tap/action
/// routing) plus a heal-only resync when the master switch is on. Never
/// awaited from [main] — first frame paints before this finishes.
///
/// Cold-start taps (app opened from a notification) are applied here as an
/// override: [AppShell] paints the `default_view` tab immediately, then this
/// jumps to Upcoming + focus when a launch route exists. Permissions are
/// NEVER requested here — only from user interaction.
Future<void> _warmReminders(ProviderContainer container) async {
  try {
    final reminders = container.read(reminderServiceProvider);
    reminders.digestSnoozeReader = () async => int.tryParse(
      await container
              .read(appDatabaseProvider)
              .getSetting('digest_snooze_until') ??
          '',
    );
    reminders.dailyPolicyReader = () async => (
      briefing: container.read(briefingProvider),
      streak: container.read(streakReminderProvider),
    );
    await reminders.init(
      onRoute: (route) => handleReminderRoute(container, route),
    );
    if (container.read(remindersEnabledProvider)) {
      // Heal-only: rebuilds when schedules drifted (reboot, clock change)
      // but never wipes a displayed ongoing reminder just for opening app.
      await reminders.syncAll(
        await container.read(appDatabaseProvider).getTasks(),
        enabled: true,
        healOnly: true,
      );
    }
    // AppShell already painted default_view; a cold-start route beats it.
    final launch = reminders.consumeLaunchRoute();
    if (launch != null) {
      container.read(navIndexProvider.notifier).updateIndex(1);
      if (launch.taskId != null) {
        container.read(focusedTaskIdProvider.notifier).set(launch.taskId);
      }
    }
  } catch (_) {}
}

/// Foreground notification router: tap or action button. Navigates to
/// Upcoming focused on the task, then applies SNOOZE / MARK DONE against
/// the DB and rebuilds the schedule.
Future<void> handleReminderRoute(
  ProviderContainer container,
  ReminderRoute route,
) async {
  container.read(navIndexProvider.notifier).updateIndex(1);
  container.read(focusedTaskIdProvider.notifier).set(route.taskId);
  final db = container.read(appDatabaseProvider);
  final reminders = container.read(reminderServiceProvider);
  final enabled = container.read(remindersEnabledProvider);
  try {
    // Ongoing entries are never auto-dismissed: every route dismisses
    // exactly what fired (payload nid) before applying action effects.
    if (route.nid != null) await reminders.dismiss(route.nid!);
    if (route.actionId == actionDone && route.taskId != null) {
      final task = await db.getTask(route.taskId!);
      if (task != null) {
        await completeTaskWithRecurrence(db, task);
      } else {
        await db.setTaskDone(route.taskId!, true);
        await db.setTaskSnooze(route.taskId!, null);
      }
    } else if (route.actionId == actionSnooze && route.taskId != null) {
      await reminders.snoozeTask(db, route.taskId!);
    } else if (route.actionId == actionSnooze) {
      await reminders.snoozeDigest(db);
    } else {
      return;
    }
    await reminders.syncAll(await db.getTasks(), enabled: enabled);
    container.invalidate(tasksProvider);
    container.invalidate(todayTasksProvider);
    container.invalidate(upcomingGroupsProvider);
  } catch (_) {}
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = themeModeFor(ref.watch(themeSettingProvider));
    return MaterialApp(
      title: 'MATRIX // TODO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: const AppShell(),
    );
  }
}
