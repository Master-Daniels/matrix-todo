import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/data/providers.dart';
import 'src/data/recurrence.dart';
import 'src/notifications/reminder_service.dart';
import 'src/pages/alarm/alarm_providers.dart';
import 'src/pages/alarm/alarm_ringing_page.dart';
import 'src/pages/home/home_providers.dart';
import 'src/pages/layout/app_shell.dart';
import 'src/pages/settings/settings_providers.dart';
import 'src/pages/upcoming/upcoming_providers.dart';
import 'src/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();

  // Draw first frame immediately using memory defaults so Android dismisses
  // the splash / loading screen in milliseconds without waiting on disk I/O.
  runApp(
    UncontrolledProviderScope(container: container, child: const TodoApp()),
  );

  // Asynchronously load settings and warm up background services after the
  // first frame is painted and interactive.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(settingsControllerProvider.notifier).refresh();
    _warmReminders(container);
  });
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
    reminders.testAlarmReader = () async => int.tryParse(
      await container
              .read(appDatabaseProvider)
              .getSetting('test_alarm_fire_at') ??
          '',
    );
    reminders.testAlarmWriter = (ms) async {
      await container
          .read(appDatabaseProvider)
          .setSetting('test_alarm_fire_at', ms?.toString() ?? '');
    };
    await reminders.init(
      onRoute: (route) => handleReminderRoute(container, route),
    );
    // AppShell already painted default_view; a cold-start route beats it.
    final launch = reminders.consumeLaunchRoute();
    final isAlarmLaunch = launch != null &&
        (launch.isAlarm || launch.nid == testAlarmNotificationId);
    if (launch != null) {
      if (isAlarmLaunch) {
        container.read(ringingAlarmProvider.notifier).trigger(
          RingingAlarmInfo(
            nid: launch.nid ?? testAlarmNotificationId,
            taskId: launch.taskId,
            title: launch.title ??
                (launch.nid == testAlarmNotificationId
                    ? 'TEST ALARM'
                    : 'TASK ALARM'),
            body: launch.body ?? '',
            category: launch.category,
            priority: launch.priority ?? 1,
            notes: launch.notes ?? '',
            dueTime: launch.dueTime,
            isTest: launch.nid == testAlarmNotificationId,
          ),
        );
      } else {
        container.read(navIndexProvider.notifier).updateIndex(1);
        if (launch.taskId != null) {
          container.read(focusedTaskIdProvider.notifier).set(launch.taskId);
        }
      }
    }
    // Defer the heavy task resync so cold start has zero thread contention.
    // Skip delayed resync on alarm launch so we never interfere with an active alarm chime.
    if (!isAlarmLaunch && container.read(remindersEnabledProvider)) {
      Future.delayed(const Duration(milliseconds: 600), () async {
        try {
          await reminders.syncAll(
            await container.read(appDatabaseProvider).getTasks(),
            enabled: true,
            healOnly: true,
          );
        } catch (_) {}
      });
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
  if (route.isAlarm || route.nid == testAlarmNotificationId) {
    if (route.actionId == null) {
      container.read(ringingAlarmProvider.notifier).trigger(
        RingingAlarmInfo(
          nid: route.nid ?? testAlarmNotificationId,
          taskId: route.taskId,
          title: route.title ??
              (route.nid == testAlarmNotificationId
                  ? 'TEST ALARM'
                  : 'TASK ALARM'),
          body: route.body ?? '',
          category: route.category,
          priority: route.priority ?? 1,
          notes: route.notes ?? '',
          dueTime: route.dueTime,
          isTest: route.nid == testAlarmNotificationId,
        ),
      );
      return;
    }
    if (route.actionId == actionDismiss) {
      try {
        if (route.nid != null) {
          await container.read(reminderServiceProvider).dismiss(route.nid!);
        }
        if (route.nid == testAlarmNotificationId) {
          await container.read(reminderServiceProvider).cancelTestAlarm();
        }
      } catch (_) {}
      return;
    }
    if (route.actionId == actionSnooze) {
      try {
        if (route.nid != null) {
          await container.read(reminderServiceProvider).dismiss(route.nid!);
        }
        final db = container.read(appDatabaseProvider);
        final reminders = container.read(reminderServiceProvider);
        if (route.taskId != null) {
          await reminders.snoozeTask(db, route.taskId!);
          await reminders.syncAll(
            await db.getTasks(),
            enabled: container.read(remindersEnabledProvider),
          );
          container.invalidate(tasksProvider);
          container.invalidate(todayTasksProvider);
          container.invalidate(upcomingGroupsProvider);
        } else if (route.nid == testAlarmNotificationId) {
          await reminders.scheduleTestAlarm(delay: snoozeTaskDelay);
        }
      } catch (_) {}
      return;
    }
  }
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
    } else if (route.actionId == actionExtend && route.taskId != null) {
      await reminders.extendTaskEstimate(db, route.taskId!);
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
    final activeAlarm = ref.watch(ringingAlarmProvider);

    return MaterialApp(
      title: 'MATRIX // TODO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: Stack(
        children: [
          const AppShell(),
          if (activeAlarm != null)
            Positioned.fill(
              child: AlarmRingingPage(alarm: activeAlarm),
            ),
        ],
      ),
    );
  }
}
