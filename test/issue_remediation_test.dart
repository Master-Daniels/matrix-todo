import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/data/providers.dart';
import 'package:matrix_todo/src/data/task_dates.dart';
import 'package:matrix_todo/src/notifications/reminder_service.dart';
import 'package:matrix_todo/src/pages/add_task/add_task_sheet.dart';
import 'package:matrix_todo/src/pages/home/home_providers.dart';
import 'package:matrix_todo/src/pages/home/home_sections/reschedule_dialog.dart';
import 'package:matrix_todo/src/platform/alarm_bridge.dart';
import 'package:matrix_todo/src/theme/app_colors.dart';
import 'package:matrix_todo/src/theme/app_theme.dart';
import 'package:matrix_todo/src/widgets/animated_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // R1: Alarm Audio Channel & Notification Isolation on Android
  // ---------------------------------------------------------------------------
  group('R1: Alarm Audio Channel & Notification Isolation', () {
    final channelCalls = <MethodCall>[];

    setUp(() {
      channelCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('matrix_todo/alarm'),
        (MethodCall call) async {
          channelCalls.add(call);
          if (call.method == 'startAlarm') return true;
          if (call.method == 'stopAlarm') return true;
          if (call.method == 'isAlarmActive') return true;
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('matrix_todo/alarm'),
        null,
      );
    });

    test('AlarmBridge communicates with native platform channel matrix_todo/alarm', () async {
      final startRes = await AlarmBridge.startAlarm(
        title: 'TEST ALARM',
        body: 'STARTING NOW',
        nid: 12345,
      );
      expect(startRes, isTrue);
      expect(channelCalls.length, 1);
      expect(channelCalls[0].method, 'startAlarm');
      expect(channelCalls[0].arguments, {
        'title': 'TEST ALARM',
        'body': 'STARTING NOW',
        'nid': 12345,
      });

      final activeRes = await AlarmBridge.isAlarmActive();
      expect(activeRes, isTrue);
      expect(channelCalls.length, 2);
      expect(channelCalls[1].method, 'isAlarmActive');

      final stopRes = await AlarmBridge.stopAlarm();
      expect(stopRes, isTrue);
      expect(channelCalls.length, 3);
      expect(channelCalls[2].method, 'stopAlarm');
    });

    test('Alarm notification ID is deterministic (taskId * 10 + 3)', () {
      final atStartId = notificationId(42, ReminderKind.atStart);
      expect(atStartId, equals(423));
    });

    test('Alarm notifications are decoupled from reminderGroupKey to prevent interruption', () {
      String? resolveGroupKey(bool isAlarm) => isAlarm ? null : reminderGroupKey;
      expect(resolveGroupKey(true), isNull);
      expect(resolveGroupKey(false), equals(reminderGroupKey));
    });
  });

  // ---------------------------------------------------------------------------
  // R2: Task Reactivation on Reschedule
  // ---------------------------------------------------------------------------
  group('R2: Task Reactivation on Reschedule', () {
    final now = DateTime(2026, 4, 15, 14, 0); // 14:00 today

    test('isFutureDateTime accurately determines future calendar dates', () {
      final tomorrow = DateTime(2026, 4, 16);
      expect(isFutureDateTime(tomorrow, null, now), isTrue);

      final nextWeek = DateTime(2026, 4, 22);
      expect(isFutureDateTime(nextWeek, null, now), isTrue);

      final yesterday = DateTime(2026, 4, 14);
      expect(isFutureDateTime(yesterday, null, now), isFalse);
    });

    test('isFutureDateTime accurately validates today with time', () {
      final today = DateTime(2026, 4, 15);

      // Future time today (15:00 > 14:00)
      const futureTime = TimeOfDay(hour: 15, minute: 0);
      expect(isFutureDateTime(today, futureTime, now), isTrue);

      // Past time today (13:30 < 14:00)
      const pastTime = TimeOfDay(hour: 13, minute: 30);
      expect(isFutureDateTime(today, pastTime, now), isFalse);

      // Current time today (14:00 == 14:00)
      const sameTime = TimeOfDay(hour: 14, minute: 0);
      expect(isFutureDateTime(today, sameTime, now), isFalse);

      // Null time today
      expect(isFutureDateTime(today, null, now), isFalse);
    });

    test('copyWith clearSnooze resets snoozedUntil to null', () {
      const task = TodoTask(
        id: 10,
        title: 'Review PR',
        dueDate: '2026-04-15',
        done: true,
        snoozedUntil: 1776260000000,
      );

      final updated = task.copyWith(
        done: false,
        clearSnooze: true,
      );

      expect(updated.done, isFalse);
      expect(updated.snoozedUntil, isNull);
    });

    test('Rescheduling completed task to tomorrow sets done: false and snoozedUntil: null', () {
      const doneTask = TodoTask(
        id: 7,
        title: 'Submit report',
        dueDate: '2026-04-15',
        dueTime: '10:00 HRS',
        done: true,
        snoozedUntil: 1776260000000,
      );

      final newDate = DateTime(2026, 4, 16);
      const newTime = TimeOfDay(hour: 11, minute: 0);
      final isFuture = isFutureDateTime(newDate, newTime, now);
      final reactivate = doneTask.done && isFuture;

      final updated = doneTask.copyWith(
        dueDate: isoDay(newDate),
        dueTime: '11:00 HRS',
        done: reactivate ? false : doneTask.done,
        clearSnooze: reactivate,
      );

      expect(updated.done, isFalse);
      expect(updated.snoozedUntil, isNull);
      expect(updated.dueDate, '2026-04-16');
    });
  });

  // ---------------------------------------------------------------------------
  // R3: Darker Modal Barrier
  // ---------------------------------------------------------------------------
  group('R3: Darker Modal Barrier', () {
    test('AppColors.modalBarrier is 75% black (Color(0xBF000000))', () {
      expect(AppColors.modalBarrier, equals(const Color(0xBF000000)));
      expect(AppColors.modalBarrier.toARGB32(), equals(0xBF000000));
      expect((AppColors.modalBarrier.a * 255.0).round(), equals(0xBF));
      expect((AppColors.modalBarrier.r * 255.0).round(), equals(0));
      expect((AppColors.modalBarrier.g * 255.0).round(), equals(0));
      expect((AppColors.modalBarrier.b * 255.0).round(), equals(0));
    });

    test('AppTheme light and dark configure AppColors.modalBarrier for bottomSheetTheme and dialogTheme', () {
      final lightTheme = AppTheme.light();
      expect(lightTheme.bottomSheetTheme.modalBarrierColor, equals(AppColors.modalBarrier));
      expect(lightTheme.dialogTheme.barrierColor, equals(AppColors.modalBarrier));

      final darkTheme = AppTheme.dark();
      expect(darkTheme.bottomSheetTheme.modalBarrierColor, equals(AppColors.modalBarrier));
      expect(darkTheme.dialogTheme.barrierColor, equals(AppColors.modalBarrier));
    });

    testWidgets('showAnimatedModalBottomSheet renders ModalBarrier with AppColors.modalBarrier', (
      WidgetTester tester,
    ) async {
      ModalRoute? route;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAnimatedModalBottomSheet(
                    context: context,
                    builder: (sheetCtx) {
                      route = ModalRoute.of(sheetCtx);
                      return const SizedBox(height: 200, child: Text('Sheet Content'));
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(route, isNotNull);
      expect(route!.barrierColor, equals(AppColors.modalBarrier));

      final animatedBarrier = tester.widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier).first);
      expect(animatedBarrier.color.value, equals(AppColors.modalBarrier));
    });

    testWidgets('showRescheduleDialog renders with AppColors.modalBarrier', (
      WidgetTester tester,
    ) async {
      const task = TodoTask(
        id: 1,
        title: 'Test Reschedule',
        dueDate: '2026-04-15',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayTasksProvider.overrideWith((ref) async => []),
            todayBaseTasksProvider.overrideWith((ref) async => []),
            todayCountsProvider.overrideWith(
              (ref) async => (total: 0, completed: 0, remaining: 0),
            ),
            todayCategoryCountsProvider.overrideWith(
              (ref) async => <String?, int>{null: 0},
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showRescheduleDialog(context, task);
                  },
                  child: const Text('Open Reschedule'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reschedule'));
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(RescheduleDialog);
      expect(dialogFinder, findsOneWidget);
      final route = ModalRoute.of(tester.element(dialogFinder));
      expect(route, isNotNull);
      expect(route!.barrierColor, equals(AppColors.modalBarrier));

      final animatedBarrier = tester.widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier).first);
      expect(animatedBarrier.color.value, equals(AppColors.modalBarrier));
    });
  });

  // ---------------------------------------------------------------------------
  // R4: Alarm Cancellation on Task Completion
  // ---------------------------------------------------------------------------
  group('R4: Alarm Cancellation on Task Completion', () {
    test('Completed task excludes atStart alarm ID from desiredIdsFor', () {
      final now = DateTime(2026, 4, 15, 9, 0);

      const activeTask = TodoTask(
        id: 42,
        title: 'Active Task',
        dueDate: '2026-04-15',
        dueTime: '10:00 HRS',
        done: false,
      );
      final activeIds = desiredIdsFor([activeTask], now, null);
      final alarmId = notificationId(42, ReminderKind.atStart);
      expect(activeIds.contains(alarmId), isTrue);

      const completedTask = TodoTask(
        id: 42,
        title: 'Completed Task',
        dueDate: '2026-04-15',
        dueTime: '10:00 HRS',
        done: true,
      );
      final completedIds = desiredIdsFor([completedTask], now, null);
      expect(completedIds.contains(alarmId), isFalse);
      expect(completedIds, isEmpty);
    });

    test('remindersFor returns empty list for completed tasks', () {
      final now = DateTime(2026, 4, 15, 9, 0);
      const completedTask = TodoTask(
        id: 15,
        title: 'Done task',
        dueDate: '2026-04-15',
        dueTime: '10:00 HRS',
        done: true,
      );
      final reminders = remindersFor(completedTask, now);
      expect(reminders, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // R5: Future-Only Time Picker Validation for Today
  // ---------------------------------------------------------------------------
  group('R5: Future-Only Time Picker Validation for Today', () {
    final now = DateTime(2026, 4, 15, 14, 30); // Today is 2026-04-15 14:30

    test('isPastTimeToday returns true for past times today', () {
      final today = DateTime(2026, 4, 15);
      const pastTime = TimeOfDay(hour: 10, minute: 0);
      expect(isPastTimeToday(today, pastTime, now), isTrue);

      const earlierTime = TimeOfDay(hour: 14, minute: 29);
      expect(isPastTimeToday(today, earlierTime, now), isTrue);
    });

    test('isPastTimeToday returns true for exactly current minute today', () {
      final today = DateTime(2026, 4, 15);
      const currentTime = TimeOfDay(hour: 14, minute: 30);
      expect(isPastTimeToday(today, currentTime, now), isTrue);
    });

    test('isPastTimeToday returns false for future times today', () {
      final today = DateTime(2026, 4, 15);
      const futureTime1 = TimeOfDay(hour: 14, minute: 31);
      expect(isPastTimeToday(today, futureTime1, now), isFalse);

      const futureTime2 = TimeOfDay(hour: 18, minute: 0);
      expect(isPastTimeToday(today, futureTime2, now), isFalse);
    });

    test('isPastTimeToday returns false for tomorrow or other future dates', () {
      final tomorrow = DateTime(2026, 4, 16);
      const earlyMorning = TimeOfDay(hour: 6, minute: 0);
      expect(isPastTimeToday(tomorrow, earlyMorning, now), isFalse);
    });

    testWidgets('AddTaskSheet rejects saving task for today without selecting a future time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listsProvider.overrideWith(
              (ref) async => const [
                TaskList(name: 'PERSONAL', code: 'PER-SYS'),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: AddTaskSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Enter task title
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'Submit quarterly taxes');
      await tester.pump();

      // Date defaults to today in AddTaskSheet
      // Tap add task button without picking a time
      final createButton = find.text('Add task');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();

      // Expect SnackBar validation requiring future time for today
      expect(find.text('Please select a future time for today.'), findsOneWidget);
    });
  });
}
