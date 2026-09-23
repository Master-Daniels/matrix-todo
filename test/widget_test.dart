import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_todo/main.dart';
import 'package:flutter_todo/src/data/models.dart';
import 'package:flutter_todo/src/data/providers.dart';
import 'package:flutter_todo/src/notifications/reminder_service.dart';
import 'package:flutter_todo/src/pages/add_task/add_task_sheet.dart';
import 'package:flutter_todo/src/pages/lists/list_form_sheet.dart';
import 'package:flutter_todo/src/pages/lists/lists_page.dart';
import 'package:flutter_todo/src/pages/lists/lists_providers.dart';
import 'package:flutter_todo/src/pages/home/home_providers.dart';
import 'package:flutter_todo/src/pages/settings/settings_page.dart';
import 'package:flutter_todo/src/pages/settings/settings_providers.dart';
import 'package:flutter_todo/src/pages/settings/settings_sections/data_section.dart';
import 'package:flutter_todo/src/pages/upcoming/schedule_export.dart';
import 'package:flutter_todo/src/pages/upcoming/upcoming_page.dart';
import 'package:flutter_todo/src/pages/upcoming/upcoming_providers.dart';
import 'package:flutter_todo/src/theme/app_theme.dart';
import 'package:flutter_todo/src/widgets/task_swipe.dart';

void main() {
  testWidgets('TodoApp boots home shell', (WidgetTester tester) async {
    // Override async DB-backed providers so the widget test never touches
    // sqflite (no plugins in the test env).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTasksProvider.overrideWith((ref) async => []),
          todayCountsProvider.overrideWith(
            (ref) async => (total: 0, completed: 0, remaining: 0),
          ),
          // Settings are synchronous with built-in defaults: no DB,
          // no overrides needed for theme/tabs/strip.
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pump();

    // App bar from HomePage (CustomAppBar uppercases title).
    expect(find.text('TODAY // MY DAY'), findsOneWidget);
    // Hero copy.
    expect(
      find.text(
        'FOCUS ON WHAT MATTERS. KEEP IT SIMPLE, MAKE IT COUNT.',
      ),
      findsOneWidget,
    );
    // Bottom nav from AppShell.
    expect(find.text('TODAY'), findsWidgets);
    expect(find.text('UPCOMING'), findsOneWidget);
  });

  testWidgets('AddTaskSheet renders all design sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [
              TaskList(name: 'PERSONAL', code: 'PER-SYS'),
              TaskList(name: 'WORK', code: 'CRIT'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: AddTaskSheet()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('[+] NEW TASK ENTRY'), findsOneWidget);
    expect(find.text('01 // TASK NAME // WHAT NEEDS DOING?'), findsOneWidget);
    expect(find.text('02 // TAXONOMY CATEGORY'), findsOneWidget);
    expect(find.textContaining('PERSONAL'), findsWidgets);
    expect(find.text('03A // TARGET DATE'), findsOneWidget);
    expect(find.text('03B // EXEC TIME'), findsOneWidget);
    expect(find.text('04 // PRIORITY SEVERITY'), findsOneWidget);
    expect(find.text('05 // SUB-EXECUTION NODES'), findsOneWidget);
    expect(find.text('COMMIT & SAVE TASK -> [ENTER]'), findsOneWidget);
    expect(find.text('DISCARD CHANGES'), findsOneWidget);
  });

  testWidgets('Subtask add/cancel dismisses keyboard without focus jump', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [
              TaskList(name: 'PERSONAL', code: 'PER-SYS'),
              TaskList(name: 'WORK', code: 'CRIT'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: AddTaskSheet()),
          ),
        ),
      ),
    );
    await tester.pump();

    // Establish focus history: type the title first, like a real user.
    await tester.enterText(find.byType(TextFormField).first, 'My task');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    // Cancel path: open the row, type, then X — keyboard hides, row closes.
    await tester.tap(find.text('+ ADD SUBTASK NODE'));
    await tester.pump();
    // Opening the row autofocuses the input: keyboard up, no extra tap.
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(TextFormField).last, 'Draft one');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('+ ADD SUBTASK NODE'), findsOneWidget);

    // Confirm path: reopen, type, tap ADD — draft added, keyboard hides,
    // trigger returns, and the title input never regains focus.
    await tester.tap(find.text('+ ADD SUBTASK NODE'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'First sub');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('FIRST SUB'), findsOneWidget);
    expect(find.text('+ ADD SUBTASK NODE'), findsOneWidget);
  });

  testWidgets('TaskSwipe flings toggle state, snaps back, taps through', (
    WidgetTester tester,
  ) async {
    final marks = <bool>[];
    var tapped = false;
    Widget frame(bool done) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TaskSwipe(
              swipeKey: 'u1',
              done: done,
              onMarkDone: () async => marks.add(true),
              onMarkUndone: () async => marks.add(false),
              onTap: () => tapped = true,
              child: const SizedBox(
                height: 64,
                child: Center(child: Text('ROW')),
              ),
            ),
          ),
        );

    await tester.pumpWidget(frame(false));
    await tester.tap(find.text('ROW'));
    await tester.pump();
    expect(tapped, isTrue);

    // Left swipe marks done; row stays mounted (confirmDismiss false).
    await tester.fling(find.text('ROW'), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(marks, [true]);
    expect(find.text('ROW'), findsOneWidget);

    // Right swipe on an undone row is a no-op.
    await tester.fling(find.text('ROW'), const Offset(300, 0), 800);
    await tester.pumpAndSettle();
    expect(marks, [true]);

    // Right swipe on a done row marks undone.
    await tester.pumpWidget(frame(true));
    await tester.fling(find.text('ROW'), const Offset(300, 0), 800);
    await tester.pumpAndSettle();
    expect(marks, [true, false]);
    expect(find.text('ROW'), findsOneWidget);
  });

  testWidgets('TaskSwipe travel clamps to half the row width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TaskSwipe(
            swipeKey: 'clamp',
            done: false,
            onMarkDone: () async {},
            onMarkUndone: () async {},
            child: const SizedBox(
              height: 64,
              child: Center(child: Text('ROW')),
            ),
          ),
        ),
      ),
    );
    // 800px surface → clamp at -400 despite a -500 drag, pre-release.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('ROW')),
    );
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(container.transform!.storage[12], -400.0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('ROW'), findsOneWidget);
  });

  testWidgets('AddTaskSheet edit mode prefills task and subtasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [
              TaskList(name: 'PERSONAL', code: 'PER-SYS'),
              TaskList(name: 'WORK', code: 'CRIT'),
            ],
          ),
          subtasksProvider.overrideWith(
            (ref, taskId) async => const [
              Subtask(id: 11, taskId: 5, title: 'First sub', done: true),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: AddTaskSheet(
                task: TodoTask(
                  id: 5,
                  title: 'Fix sink',
                  category: 'HOME',
                  dueDate: '2026-04-16',
                  dueTime: '10:00 AM',
                  priority: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('[~] EDIT TASK ENTRY'), findsOneWidget);
    expect(find.text('2026-04-16'), findsOneWidget);
    expect(find.text('10:00 HRS'), findsOneWidget);
    expect(find.text('FIRST SUB'), findsOneWidget);
    expect(find.text('SAVE CHANGES -> [ENTER]'), findsOneWidget);
  });

  testWidgets('Empty subtask confirm shows red REQ error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [
              TaskList(name: 'PERSONAL', code: 'PER-SYS'),
              TaskList(name: 'WORK', code: 'CRIT'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: AddTaskSheet()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('+ ADD SUBTASK NODE'));
    await tester.pump();
    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(find.text('REQUIRED*'), findsOneWidget);
    // Row stays open for correction.
    expect(find.text('+ ADD SUBTASK NODE'), findsNothing);
  });

  testWidgets('ListsPage renders ledgers with pinned create footer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [
              TaskList(
                id: 1,
                name: 'PERSONAL',
                code: 'PER-SYS',
                description: 'Daily ops.',
                sort: 0,
              ),
              TaskList(
                id: 2,
                name: 'WORK',
                code: 'CRIT',
                description: 'Contracts.',
                sort: 1,
              ),
              TaskList(
                id: 3,
                name: 'READING LIST',
                code: 'READ',
                description: 'Papers.',
                sort: 4,
              ),
            ],
          ),
          tasksProvider.overrideWith((ref, args) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ListsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LISTS // FOLDERS'), findsOneWidget);
    expect(find.text('PERSONAL'), findsWidgets);
    expect(find.text('WORK'), findsWidgets);
    expect(find.text('READING LIST'), findsOneWidget);
    expect(find.text('[SEC 01]'), findsOneWidget);
    expect(find.text('[SEC 02]'), findsOneWidget);
    expect(find.text('+ CREATE NEW CATEGORY'), findsOneWidget);
  });

  test('deriveListCode shortens names to ledger tags', () {
    expect(deriveListCode('Reading List'), 'READ');
    expect(deriveListCode('a'), 'A');
    expect(deriveListCode('!!!'), 'LIST');
  });

  test('listCountsProvider matches tasks by listId or category', () async {
    final container = ProviderContainer(
      overrides: [
        listsProvider.overrideWith(
          (ref) async => const [
            TaskList(id: 1, name: 'WORK', code: 'CRIT', sort: 1),
          ],
        ),
        // One linked by listId, one by category string only, one foreign.
        tasksProvider.overrideWith(
          (ref, args) async => const [
            TodoTask(
              title: 'A',
              listId: 1,
              category: 'WORK',
              dueDate: '2026-04-14',
              done: true,
            ),
            TodoTask(title: 'B', category: 'WORK', dueDate: '2026-04-15'),
            TodoTask(
              title: 'C',
              listId: 9,
              category: 'WORK',
              dueDate: '2026-04-15',
            ),
            TodoTask(
              title: 'D',
              category: 'PERSONAL',
              dueDate: '2026-04-15',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final counts = await container.read(listCountsProvider(1).future);
    expect(counts.total, 2);
    expect(counts.completed, 1);
    expect(counts.hasHigh, false);
  });

  test('bucketTasks groups by date, heads undone-today, drops done history',
      () {
    // Wednesday 2026-04-15: tomorrow Thu 16, Sunday 19.
    final now = DateTime(2026, 4, 15);
    final groups = bucketTasks(const [
      TodoTask(title: 'past undone', category: 'WORK', dueDate: '2026-04-13'),
      TodoTask(
        title: 'past done',
        category: 'WORK',
        dueDate: '2026-04-13',
        done: true,
      ),
      TodoTask(title: 'today', category: 'WORK', dueDate: '2026-04-15'),
      TodoTask(
        title: 'today done',
        category: 'WORK',
        dueDate: '2026-04-15',
        done: true,
      ),
      TodoTask(title: 'tomorrow', category: 'WORK', dueDate: '2026-04-16'),
      TodoTask(
        title: 'tomorrow done',
        category: 'WORK',
        dueDate: '2026-04-16',
        done: true,
      ),
      TodoTask(title: 'friday', category: 'WORK', dueDate: '2026-04-17'),
      TodoTask(title: 'later', category: 'WORK', dueDate: '2026-04-25'),
    ], now);

    expect(groups.today.map((t) => t.title), ['today']);
    expect(groups.overdue.map((t) => t.title), ['past undone']);
    expect(
      groups.tomorrow.map((t) => t.title).toList(),
      ['tomorrow', 'tomorrow done'],
    );
    expect(groups.laterThisWeek.map((t) => t.title), ['friday']);
    expect(groups.nextBeyond.map((t) => t.title), ['later']);
  });

  testWidgets('UpcomingPage renders strip, tomorrow and terminal', (
    WidgetTester tester,
  ) async {
    // Tall surface so the whole lazy list builds without scrolling.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final base = dayOf(DateTime.now());
    final tomorrow = isoDay(base.add(const Duration(days: 1)));
    // today+2 lands in later-this-week or next-beyond depending on the
    // real weekday; the title renders in either section.
    final later = isoDay(base.add(const Duration(days: 2)));
    final sunday = weekEndOf(base, DateTime.monday);
    final next = isoDay(sunday.add(const Duration(days: 3)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith(
            (ref, args) async => [
              TodoTask(
                title: 'Today task',
                category: 'WORK',
                dueDate: isoDay(base),
              ),
              TodoTask(
                title: 'Tomorrow task',
                category: 'WORK',
                dueDate: tomorrow,
                dueTime: '10:00 AM',
              ),
              TodoTask(
                title: 'Later task',
                category: 'HOME',
                dueDate: later,
              ),
              TodoTask(
                title: 'Next task',
                category: 'WORK',
                dueDate: next,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const UpcomingPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('UPCOMING // TIMELINE'), findsOneWidget);
    expect(find.textContaining('TOMORROW'), findsWidgets);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.textContaining('TODAY //'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsOneWidget);
    expect(find.text('Later task'), findsOneWidget);
    expect(find.text('[SEC 02]'), findsOneWidget);
    // Terminal buttons use intentional two-line labels.
    expect(find.text('NEW TIME\nBLOCK +'), findsOneWidget);
  });

  test('todayTasksProvider shows due-today plus overdue undone', () async {
    final today = isoDay(dayOf(DateTime.now()));
    final yesterday =
        isoDay(dayOf(DateTime.now()).subtract(const Duration(days: 1)));
    final tomorrow =
        isoDay(dayOf(DateTime.now()).add(const Duration(days: 1)));
    final container = ProviderContainer(
      overrides: [
        tasksProvider.overrideWith(
          (ref, args) async => [
            TodoTask(title: 'today', category: 'WORK', dueDate: today),
            TodoTask(
              title: 'today done',
              category: 'WORK',
              dueDate: today,
              done: true,
            ),
            TodoTask(
              title: 'overdue',
              category: 'WORK',
              dueDate: yesterday,
            ),
            TodoTask(
              title: 'past done',
              category: 'WORK',
              dueDate: yesterday,
              done: true,
            ),
            TodoTask(title: 'future', category: 'WORK', dueDate: tomorrow),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(todayTasksProvider.future);
    expect(
      tasks.map((t) => t.title).toSet(),
      {'today', 'today done', 'overdue'},
    );
  });

  test('buildIcs maps timed, all-day and escaped content', () {
    final ics = buildIcs(
      const [
        TodoTask(
          id: 7,
          title: 'Review, sync; ship',
          notes: 'Room 4B',
          category: 'WORK',
          dueDate: '2026-04-16',
          dueTime: '10:00 AM',
          priority: 3,
        ),
        TodoTask(
          title: 'No time task',
          category: 'HOME',
          dueDate: '2026-04-17',
        ),
      ],
      now: DateTime.utc(2026, 4, 14, 12),
    );

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('UID:task-7@matrix-todo'));
    expect(ics, contains('DTSTART:20260416T100000'));
    expect(ics, contains('DTEND:20260416T110000'));
    expect(ics, contains('SUMMARY:Review\\, sync\\; ship'));
    expect(ics, contains('DTSTART;VALUE=DATE:20260417'));
    expect(ics, contains('STATUS:NEEDS-ACTION'));
    expect(ics, contains('DTSTAMP:20260414T120000Z'));
  });

  test('exportableTasks keeps undone scheduled rows in order', () {
    final groups = bucketTasks(const [
      TodoTask(title: 'past', category: 'WORK', dueDate: '2026-04-13'),
      TodoTask(
        title: 'past done',
        category: 'WORK',
        dueDate: '2026-04-13',
        done: true,
      ),
      TodoTask(title: 'next', category: 'WORK', dueDate: '2026-04-16'),
      TodoTask(
        title: 'next done',
        category: 'WORK',
        dueDate: '2026-04-16',
        done: true,
      ),
    ], DateTime(2026, 4, 15));

    expect(
      exportableTasks(groups).map((t) => t.title).toList(),
      ['past', 'next'],
    );
  });

  testWidgets('SettingsPage renders prefs without profile chrome', (
    WidgetTester tester,
  ) async {
    // Tall surface so the whole lazy list builds without scrolling.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SETTINGS // PREFERENCES'), findsOneWidget);
    expect(find.text('THEME ENGINE'), findsOneWidget);
    expect(find.text('DEFAULT VIEW MATRIX'), findsOneWidget);
    expect(find.text('CALENDAR CADENCE'), findsOneWidget);
    expect(find.text('USER'), findsOneWidget);
    expect(find.text('TASK REMINDERS'), findsOneWidget);
    expect(find.text('FREE TIER'), findsNothing);
    expect(find.byIcon(Icons.account_circle), findsNothing);
    expect(find.textContaining('ID:'), findsNothing);
    // Data vault sits below the fold: scroll it into view first.
    await tester.scrollUntilVisible(
      find.text('[ RESET ALL DATA ]'),
      500,
    );
    expect(find.text('[ RESET ALL DATA ]'), findsOneWidget);
  });

  test('settings writes apply instantly without DB round-trip', () async {
    // sqflite is unreachable here: persistence fails silently while the
    // optimistic state — the old reload-flash scenario — still updates.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeSettingProvider), ThemeSetting.light);
    await container
        .read(settingsControllerProvider.notifier)
        .setTheme(ThemeSetting.dark);
    expect(container.read(themeSettingProvider), ThemeSetting.dark);
    expect(
      container.read(settingsControllerProvider).theme,
      ThemeSetting.dark,
    );
    await container
        .read(settingsControllerProvider.notifier)
        .setBriefing(false);
    expect(container.read(briefingProvider), isFalse);
  });

  test('settings mappings resolve stored values', () {
    expect(themeSettingFrom('dark'), ThemeSetting.dark);
    expect(themeSettingFrom('system'), ThemeSetting.system);
    expect(themeSettingFrom('nope'), ThemeSetting.light);
    expect(themeModeFor(ThemeSetting.dark), ThemeMode.dark);
    expect(DefaultViewX.from('upcoming'), DefaultView.upcoming);
    expect(DefaultView.upcoming.tabIndex, 1);
    expect(WeekStartX.from('sunday').weekday, DateTime.sunday);
    expect(WeekStartX.from('monday').value, 'monday');
  });

  test('buildTasksCsv emits header plus quoted rows', () {
    final csv = buildTasksCsv([
      {
        'id': 1,
        'list_id': null,
        'title': 'Say "hi", now',
        'notes': '',
        'category': 'WORK',
        'due_date': '2026-04-16',
        'due_time': null,
        'priority': 1,
        'done': 0,
        'focus': 0,
        'sort': 0,
      },
    ]);
    final lines = csv.trim().split('\n');
    expect(lines.first.startsWith('id,list_id,title'), isTrue);
    expect(lines[1], contains('"Say ""hi"", now"'));
  });

  group('reminders', () {
    test('notificationId is stable and unique per kind', () {
      expect(notificationId(7, ReminderKind.hourBefore), 70);
      expect(notificationId(7, ReminderKind.halfHourBefore), 71);
      expect(notificationId(7, ReminderKind.overdue), 72);
      expect(notificationId(8, ReminderKind.hourBefore), 80);
    });

    test('timed task schedules 1h + 30m pre-reminders only', () {
      final now = DateTime(2026, 4, 15, 12);
      final reminders = remindersFor(
        const TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
        ),
        now,
      );
      expect(reminders.map((r) => r.kind).toList(), [
        ReminderKind.hourBefore,
        ReminderKind.halfHourBefore,
      ]);
      expect(reminders[0].fireAt, DateTime(2026, 4, 15, 14));
      expect(reminders[1].fireAt, DateTime(2026, 4, 15, 14, 30));
      expect(reminders[0].body, contains('DUE IN 1 HOUR'));
      expect(reminders[1].body, contains('DUE IN 30 MINUTES'));
    });

    test('past event and untimed tasks schedule no pre-reminders', () {
      final past = remindersFor(
        const TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
        ),
        DateTime(2026, 4, 15, 16),
      );
      expect(past, isEmpty);
      final untimed = remindersFor(
        const TodoTask(
          id: 7,
          title: 'Groceries',
          category: 'ERRANDS',
          dueDate: '2026-04-16',
          dueTime: 'AFTERNOON',
        ),
        DateTime(2026, 4, 15, 12),
      );
      expect(untimed, isEmpty);
    });

    test('one digest per morning lists every overdue task', () {
      final now = DateTime(2026, 4, 15, 12);
      const tasks = [
        TodoTask(id: 1, title: 'Alpha', category: 'WORK', dueDate: '2026-04-13'),
        TodoTask(id: 2, title: 'Beta', category: 'HOME', dueDate: '2026-04-14'),
        TodoTask(
          id: 3,
          title: 'Finished',
          category: 'WORK',
          dueDate: '2026-04-13',
          done: true,
        ),
      ];
      final mornings = digestMornings(tasks, now);
      // Both land on the same overdue morning: tomorrow 08:00.
      expect(mornings, [DateTime(2026, 4, 16, 8)]);
      final digest = overdueDigest(mornings.single, tasks)!;
      expect(digest.id, isNegative);
      expect(digest.kind, ReminderKind.overdue);
      expect(digest.fireAt, DateTime(2026, 4, 16, 8));
      expect(digest.title, '2 OVERDUE // OPEN TO REVIEW');
      expect(digest.body, contains('Alpha'));
      expect(digest.body, contains('Beta'));
      expect(digest.body.contains('Finished'), isFalse);
    });

    test('staggered dues produce one digest per morning', () {
      final now = DateTime(2026, 4, 15, 12);
      const tasks = [
        TodoTask(id: 1, title: 'Old', category: 'WORK', dueDate: '2026-04-13'),
        TodoTask(id: 2, title: 'Later', category: 'WORK', dueDate: '2026-04-20'),
      ];
      expect(digestMornings(tasks, now), [
        DateTime(2026, 4, 16, 8),
        DateTime(2026, 4, 21, 8),
      ]);
      expect(digestId(DateTime(2026, 4, 16, 8)), isNegative);
      expect(
        digestId(DateTime(2026, 4, 16, 8)),
        isNot(digestId(DateTime(2026, 4, 21, 8))),
      );
    });

    test('no overdue tasks means no digest', () {
      final now = DateTime(2026, 4, 15, 12);
      expect(digestMornings(const [], now), isEmpty);
      expect(
        overdueDigest(
          DateTime(2026, 4, 16, 8),
          const [
            TodoTask(
              id: 1,
              title: 'Future',
              category: 'WORK',
              dueDate: '2026-04-20',
            ),
          ],
        ),
        isNull,
      );
    });

    test('done and id-less tasks schedule nothing', () {
      final now = DateTime(2026, 4, 15, 12);
      expect(
        remindersFor(
          const TodoTask(
            id: 7,
            title: 'Done',
            category: 'WORK',
            dueDate: '2026-04-16',
            dueTime: '10:00 AM',
            done: true,
          ),
          now,
        ),
        isEmpty,
      );
      expect(
        remindersFor(
          const TodoTask(
            title: 'Draft',
            category: 'WORK',
            dueDate: '2026-04-16',
            dueTime: '10:00 AM',
          ),
          now,
        ),
        isEmpty,
      );
    });

    test('sound mapping follows reminder kind per platform', () {
      expect(androidSoundFor(ReminderKind.hourBefore), 'nudge_chime');
      expect(androidSoundFor(ReminderKind.halfHourBefore), 'nudge_chime');
      expect(androidSoundFor(ReminderKind.overdue), 'overdue_tone');
      expect(iosSoundFor(ReminderKind.hourBefore), 'nudge_chime.aiff');
      expect(iosSoundFor(ReminderKind.overdue), 'overdue_tone.aiff');
    });

    test('payload round-trips task and digest targets', () {
      final taskTarget = parseReminderPayload(
        reminderPayload(taskId: 42, nid: 420),
      );
      expect(taskTarget.taskId, 42);
      expect(taskTarget.nid, 420);
      expect(taskTarget.digest, isNull);
      final digestTarget = parseReminderPayload(
        reminderPayload(digest: '2026-04-16', nid: -20260416),
      );
      expect(digestTarget.taskId, isNull);
      expect(digestTarget.digest, '2026-04-16');
      expect(digestTarget.nid, -20260416);
      expect(parseReminderPayload(null).taskId, isNull);
      expect(parseReminderPayload('upcoming').taskId, isNull);
      expect(parseReminderPayload('{bad json').digest, isNull);
    });

    test('pre-reminders carry task payloads', () {
      final now = DateTime(2026, 4, 15, 12);
      final reminders = remindersFor(
        const TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
        ),
        now,
      );
      expect(reminders, hasLength(2));
      for (final r in reminders) {
        expect(parseReminderPayload(r.payload).taskId, 7);
      }
    });

    test('live task snooze suppresses regular fires', () {
      final now = DateTime(2026, 4, 15, 12);
      final snoozedUntil = DateTime(2026, 4, 15, 13, 30);
      final reminders = remindersFor(
        TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
          snoozedUntil: snoozedUntil.millisecondsSinceEpoch,
        ),
        now,
      );
      expect(reminders, hasLength(1));
      expect(reminders.single.fireAt, snoozedUntil);
      expect(reminders.single.body, contains('SNOOZED'));
      expect(
        parseReminderPayload(reminders.single.payload).taskId,
        7,
      );
    });

    test('expired snooze resumes regular fires', () {
      final now = DateTime(2026, 4, 15, 12);
      final reminders = remindersFor(
        TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
          snoozedUntil: DateTime(2026, 4, 15, 11).millisecondsSinceEpoch,
        ),
        now,
      );
      expect(reminders.map((r) => r.kind).toList(), [
        ReminderKind.hourBefore,
        ReminderKind.halfHourBefore,
      ]);
    });

    test('digest snooze shifts only covered mornings', () {
      final digest = (
        id: -20260416,
        kind: ReminderKind.overdue,
        fireAt: DateTime(2026, 4, 16, 8),
        title: 'T',
        body: 'B',
        payload: null as String?,
      );
      final shifted = applyDigestSnooze(
        digest,
        DateTime(2026, 4, 16, 11).millisecondsSinceEpoch,
      );
      expect(shifted.fireAt, DateTime(2026, 4, 16, 11));
      expect(shifted.id, digest.id);
      // Snooze already past the fire: unchanged.
      final untouched = applyDigestSnooze(
        digest,
        DateTime(2026, 4, 15, 11).millisecondsSinceEpoch,
      );
      expect(untouched.fireAt, digest.fireAt);
      expect(applyDigestSnooze(digest, null).fireAt, digest.fireAt);
    });

    test('action buttons split by kind', () {
      final pre = androidReminderActions(ReminderKind.hourBefore);
      expect(pre.map((a) => a.id).toList(), [actionSnooze, actionDone]);
      final digestActs = androidReminderActions(ReminderKind.overdue);
      expect(digestActs.map((a) => a.id).toList(), [actionSnooze]);
      // Every action carries an icon: HyperOS/MIUI skins skip icon-less
      // actions even in the expanded shade.
      for (final a in [...pre, ...digestActs]) {
        expect(a.icon, isNotNull);
        expect(a.showsUserInterface, isTrue);
      }
    });

    test('desiredIdsFor covers slots, digests and summary', () {
      final now = DateTime(2026, 4, 15, 12);
      const tasks = [
        TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
        ),
        TodoTask(id: 1, title: 'Old', category: 'WORK', dueDate: '2026-04-13'),
      ];
      final ids = desiredIdsFor(tasks, now, null);
      expect(
        ids,
        {70, 71, digestId(DateTime(2026, 4, 16, 8)), reminderGroupSummaryId},
      );
      // Done tasks contribute nothing — not even a summary.
      final doneIds = desiredIdsFor(
        const [
          TodoTask(
            id: 7,
            title: 'Done',
            category: 'WORK',
            dueDate: '2026-04-15',
            dueTime: '15:00 HRS',
            done: true,
          ),
        ],
        now,
        null,
      );
      expect(doneIds, isEmpty);
    });

    test('groupSummaryLines lists fires, capped', () {
      final now = DateTime(2026, 4, 15, 12);
      final lines = groupSummaryLines(const [
        TodoTask(
          id: 7,
          title: 'Deploy',
          category: 'WORK',
          dueDate: '2026-04-15',
          dueTime: '15:00 HRS',
        ),
        TodoTask(id: 1, title: 'Old', category: 'WORK', dueDate: '2026-04-13'),
      ], now);
      expect(lines.length, 2);
      expect(lines[0], contains('Deploy'));
      expect(lines.last, contains('OVERDUE'));
      expect(groupSummaryLines(const [], now), isEmpty);
    });
  });

  test('listTasksProvider returns category-matched tasks for detail', () async {
    final container = ProviderContainer(
      overrides: [
        listsProvider.overrideWith(
          (ref) async => const [
            TaskList(id: 1, name: 'WORK', code: 'CRIT', sort: 1),
          ],
        ),
        tasksProvider.overrideWith(
          (ref, args) async => const [
            TodoTask(
              title: 'A',
              category: 'WORK',
              dueDate: '2026-04-14',
              done: true,
            ),
            TodoTask(title: 'B', category: 'WORK', dueDate: '2026-04-15'),
            TodoTask(
              title: 'C',
              category: 'PERSONAL',
              dueDate: '2026-04-15',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(listTasksProvider(1).future);
    expect(tasks.map((t) => t.title).toList(), ['A', 'B']);
  });
}
