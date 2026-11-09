import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/notifications/notification_service.dart';
import 'package:matrix_todo/src/notifications/reminder_service.dart';
import 'package:matrix_todo/src/pages/alarm/alarm_providers.dart';
import 'package:matrix_todo/src/pages/alarm/alarm_ringing_page.dart';
import 'package:matrix_todo/src/pages/settings/notifications_page.dart';
import 'package:matrix_todo/src/pages/settings/settings_page.dart';
import 'package:matrix_todo/src/theme/app_theme.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('timezone initialization with tz.UTC without initializeTimeZones', () {
    expect(tz.UTC, isNotNull);
    tz.setLocalLocation(tz.UTC);
    expect(tz.local, equals(tz.UTC));
    final dt = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, 1700000000000);
    expect(dt.millisecondsSinceEpoch, equals(1700000000000));
  });

  test('NotificationService tzOf returns valid TZDateTime in UTC', () {
    final service = NotificationService();
    final now = DateTime.now();
    final tzNow = service.tzOf(now);
    expect(tzNow.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    expect(tzNow.location, equals(tz.UTC));
  });
  test(
    'testAlarmNotificationId is included in desiredIdsFor when testAlarm is true',
    () {
      final now = DateTime(2026, 4, 15, 12);
      final ids = desiredIdsFor(const [], now, null, testAlarm: true);
      expect(ids.contains(testAlarmNotificationId), isTrue);
    },
  );

  // testWidgets('SettingsPage renders Alarm test button', (WidgetTester tester) async {
  //   tester.view.physicalSize = const Size(800, 3000);
  //   tester.view.devicePixelRatio = 1.0;
  //   addTearDown(tester.view.resetPhysicalSize);

  //   await tester.pumpWidget(
  //     ProviderScope(
  //       child: MaterialApp(
  //         theme: AppTheme.light(),
  //         home: const SettingsPage(),
  //       ),
  //     ),
  //   );
  //   await tester.pump();

  //   expect(find.text('Alarm test'), findsOneWidget);
  //   expect(find.text('Schedule test alarm (2 min)'), findsOneWidget);
  //   expect(find.text('Test sound'), findsOneWidget);
  // });

  testWidgets('NotificationsPage renders Alarm test button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const NotificationsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alarm test'), findsOneWidget);
    expect(find.text('Schedule test alarm (2 min)'), findsOneWidget);
    expect(find.text('Test sound'), findsOneWidget);
  });

  test('payload round-trips alarm attributes correctly', () {
    final payload = reminderPayload(
      taskId: 42,
      nid: 12345,
      isAlarm: true,
      title: 'Complete Project',
      body: 'STARTING NOW',
      category: 'WORK',
      priority: 2,
      notes: 'Urgent task',
      dueTime: '15:00',
    );
    final target = parseReminderPayload(payload);
    expect(target.taskId, 42);
    expect(target.nid, 12345);
    expect(target.isAlarm, isTrue);
    expect(target.title, 'Complete Project');
    expect(target.category, 'WORK');
    expect(target.priority, 2);
    expect(target.notes, 'Urgent task');
    expect(target.dueTime, '15:00');
  });

  test(
    'snoozeTaskDelay is 10 minutes and alarm actions are non-foreground pills',
    () {
      expect(snoozeTaskDelay, equals(const Duration(minutes: 10)));
      final alarmActs = androidReminderActions(ReminderKind.atStart);
      expect(alarmActs.map((a) => a.id).toList(), [
        actionDismiss,
        actionSnooze,
      ]);
      for (final a in alarmActs) {
        expect(a.showsUserInterface, isFalse);
        expect(a.cancelNotification, isTrue);
        expect(a.icon, isNotNull);
      }
    },
  );

  testWidgets(
    'AlarmRingingPage renders task details, swipe affordance, and action buttons',
    (WidgetTester tester) async {
      const alarm = RingingAlarmInfo(
        nid: -900099,
        taskId: 99,
        title: 'MEETING WITH TEAM',
        body: 'STARTING NOW',
        category: 'WORK',
        notes: 'Bring sprint notes',
        isTest: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AlarmRingingPage(alarm: alarm),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('[ MATRIX // ALARM ACTIVATED ]'), findsOneWidget);
      expect(find.text('RINGING'), findsOneWidget);
      expect(find.text('MEETING WITH TEAM'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
      expect(find.text('NOTES: Bring sprint notes'), findsOneWidget);
      expect(find.text('SWIPE UP TO DISMISS'), findsOneWidget);
      expect(find.text('SNOOZE (+10 MIN)'), findsOneWidget);
      expect(find.text('MARK DONE'), findsOneWidget);
    },
  );

  test(
    'estimatedDone reminder scheduled at event start + estimatedMinutes with gentle nudge chime',
    () {
      const task = TodoTask(
        id: 5,
        title: 'Deep Work Session',
        dueDate: '2026-04-15',
        dueTime: '10:00 HRS',
        estimatedMinutes: 45,
      );
      final now = DateTime(2026, 4, 15, 9, 0);
      final fires = remindersFor(task, now);

      final estFire = fires.firstWhere(
        (r) => r.kind == ReminderKind.estimatedDone,
      );
      expect(estFire.fireAt, DateTime(2026, 4, 15, 10, 45));
      expect(estFire.title, 'Deep Work Session');
      expect(
        estFire.body,
        'Target time elapsed: Did you finish Deep Work Session?',
      );

      // Chime verification
      expect(androidSoundFor(ReminderKind.estimatedDone), 'nudge_chime');

      // Action pills verification
      final actions = androidReminderActions(ReminderKind.estimatedDone);
      expect(actions.map((a) => a.id).toList(), [actionDone, actionExtend]);
      for (final a in actions) {
        expect(a.showsUserInterface, isFalse);
        expect(a.cancelNotification, isTrue);
        expect(a.icon, isNotNull);
      }
    },
  );
}
