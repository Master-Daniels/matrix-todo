import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/data/providers.dart';
import 'src/notifications/reminder_service.dart';
import 'src/pages/home/home_providers.dart';
import 'src/pages/layout/app_shell.dart';
import 'src/pages/settings/settings_providers.dart';
import 'src/pages/upcoming/upcoming_providers.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fetch once at startup (instant no-op once fonts are bundled).
  GoogleFonts.config.allowRuntimeFetching = false;
  await AppTypography.precache();
  // Load settings before the first frame so the saved theme is correct
  // immediately — no launch flash. Falls back to defaults on failure.
  final container = ProviderContainer();
  try {
    await container.read(settingsControllerProvider.notifier).refresh();
  } catch (_) {}
  // Reminder backend: permission-free init (channels + tap/action routing).
  // Permissions are NEVER requested here — only after the first dated task
  // is created, from user interaction. On launch we silently rebuild when
  // the master switch is on: this heals reboots when permission is already
  // granted, and is a harmless no-op otherwise. All guarded — a dead
  // plugin never blocks launch.
  try {
    final reminders = container.read(reminderServiceProvider);
    reminders.digestSnoozeReader = () async => int.tryParse(
      await container.read(appDatabaseProvider).getSetting(
            'digest_snooze_until',
          ) ??
          '',
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
  } catch (_) {}
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TodoApp(),
    ),
  );
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
      await db.setTaskDone(route.taskId!, true);
      await db.setTaskSnooze(route.taskId!, null);
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
