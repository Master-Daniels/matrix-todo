import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matrix_todo/main.dart';
import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/data/providers.dart';
import 'package:matrix_todo/src/data/recurrence.dart';
import 'package:matrix_todo/src/notifications/reminder_service.dart';
import 'package:matrix_todo/src/pages/add_task/add_task_sheet.dart';
import 'package:matrix_todo/src/pages/layout/app_shell.dart';
import 'package:matrix_todo/src/pages/lists/list_form_sheet.dart';
import 'package:matrix_todo/src/pages/lists/lists_page.dart';
import 'package:matrix_todo/src/pages/list_detail/list_detail_page.dart';
import 'package:matrix_todo/src/pages/lists/lists_providers.dart';
import 'package:matrix_todo/src/pages/lists/lists_sections/core_list_card.dart';
import 'package:matrix_todo/src/pages/home/home_page.dart';
import 'package:matrix_todo/src/pages/home/home_providers.dart';
import 'package:matrix_todo/src/pages/home/home_sections/home_deck_list.dart';
import 'package:matrix_todo/src/widgets/deck_swipe.dart';
import 'package:matrix_todo/src/pages/home/home_sections/reschedule_dialog.dart';
import 'package:matrix_todo/src/pages/settings/appearance_page.dart';
import 'package:matrix_todo/src/pages/settings/data_page.dart';
import 'package:matrix_todo/src/pages/settings/notifications_page.dart';
import 'package:matrix_todo/src/pages/settings/settings_page.dart';
import 'package:matrix_todo/src/pages/settings/settings_providers.dart';
import 'package:matrix_todo/src/pages/settings/settings_sections/data_section.dart';
import 'package:matrix_todo/src/pages/upcoming/schedule_export.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_page.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_providers.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_sections/day_strip.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_sections/timeline_section.dart';
import 'package:matrix_todo/src/theme/app_theme.dart';
import 'package:matrix_todo/src/widgets/animated_bottom_sheet.dart';
import 'package:matrix_todo/src/widgets/bottom_nav.dart';

void main() {
  testWidgets('TodoApp boots home shell', (WidgetTester tester) async {
    // Override async DB-backed providers so the widget test never touches
    // sqflite (no plugins in the test env).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTasksProvider.overrideWith((ref) async => []),
          todayBaseTasksProvider.overrideWith((ref) async => []),
          todayCategoryCountsProvider.overrideWith(
            (ref) async => <String?, int>{null: 0},
          ),
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

    // App bar from HomePage (CustomAppBar uppercases title, Option 1).
    expect(find.text('TODAY'), findsWidgets);
    // Deck metrics + action bar.
    expect(find.textContaining('completed'), findsWidgets);
    expect(find.text('Add task'), findsOneWidget);
    // Pinned footer guide (outside the scrollable, always visible).
    expect(find.textContaining('SWIPE RIGHT'), findsOneWidget);
    // Bottom nav from AppShell.
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

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('Task name'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.textContaining('PERSONAL'), findsWidgets);
    expect(find.text('Target date & time'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Repeat'), findsOneWidget);
    expect(find.text('Subtasks'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });

  testWidgets('AddTaskSheet docks flush to the bottom edge', (
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showAnimatedModalBottomSheet(
                    context: context,
                    builder: (_) => const AddTaskSheet(),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    final box = tester.getRect(find.byType(Sheet));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Flush with the screen bottom (no floating daylight)…
    expect(box.bottom, moreOrLessEquals(size.height, epsilon: 2));
    // …and hugging content, capped at 85% (tall form ⇒ exactly capped).
    expect(box.height, moreOrLessEquals(size.height * 0.85, epsilon: 4));
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
    await tester.ensureVisible(find.text('Subtasks'));
    await tester.pump();
    await tester.tap(find.text('Subtasks'));
    await tester.pump();
    await tester.ensureVisible(find.text('+ Add subtask'));
    await tester.tap(find.text('+ Add subtask'));
    await tester.pump();
    // Opening the row autofocuses the input: keyboard up, no extra tap.
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(TextFormField).last, 'Draft one');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('subtask-input-cancel')));
    await tester.tap(find.byKey(const ValueKey('subtask-input-cancel')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('+ Add subtask'), findsOneWidget);

    // Confirm path: reopen, type, tap ADD — draft added, keyboard hides,
    // trigger returns, and the title input never regains focus.
    await tester.ensureVisible(find.text('+ Add subtask'));
    await tester.tap(find.text('+ Add subtask'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).last, 'First sub');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('First sub'), findsOneWidget);
    expect(find.text('+ Add subtask'), findsOneWidget);
  });

  testWidgets('HomeDeckSwipe right completes, left reschedules', (
    WidgetTester tester,
  ) async {
    var completed = 0;
    var rescheduled = 0;
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: HomeDeckSwipe(
            swipeKey: 'deck-1',
            done: false,
            onComplete: () async => completed++,
            onReschedule: () async => rescheduled++,
            onTap: () => tapped = true,
            child: const SizedBox(
              height: 120,
              child: Center(child: Text('DECK CARD')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('DECK CARD'));
    await tester.pump();
    expect(tapped, isTrue);

    // Right fling past threshold completes; card springs back.
    await tester.fling(find.text('DECK CARD'), const Offset(300, 0), 800);
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(rescheduled, 0);
    expect(find.text('DECK CARD'), findsOneWidget);

    // Left fling past threshold reschedules.
    await tester.fling(find.text('DECK CARD'), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(rescheduled, 1);
    expect(find.text('DECK CARD'), findsOneWidget);
  });

  testWidgets('RescheduleDialog shows date and time pickers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: RescheduleDialog(
              task: TodoTask(
                id: 5,
                title: 'Fix sink',
                category: 'HOME',
                dueDate: '2026-04-16',
                dueTime: '10:00 HRS',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('[<>] RESCHEDULE'), findsOneWidget);
    expect(find.text('Fix sink'), findsOneWidget);
    expect(find.text('New date'), findsOneWidget);
    expect(find.text('2026-04-16'), findsOneWidget);
    expect(find.text('New time'), findsOneWidget);
    expect(find.text('10:00 HRS'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
  });

  testWidgets('HomeDeckList renders scrollable stacked deck with peeks', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final iso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTasksProvider.overrideWith(
            (ref) async => [
              TodoTask(
                id: 1,
                title: 'First task',
                category: 'WORK',
                dueDate: iso,
                dueTime: '14:00 HRS',
              ),
              TodoTask(
                id: 2,
                title: 'Second task',
                category: 'ERRANDS',
                dueDate: iso,
                dueTime: '17:00 HRS',
              ),
            ],
          ),
          subtasksProvider.overrideWith(
            (ref, taskId) async => taskId == 1
                ? const [
                    Subtask(id: 1, taskId: 1, title: 'Book room'),
                    Subtask(
                      id: 2,
                      taskId: 1,
                      title: 'Print agenda',
                      done: true,
                    ),
                  ]
                : const [],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeDeckList()),
          ),
        ),
      ),
    );
    await tester.pump();

    // One continuous deck: top card fully rendered with its footer,
    // next todos filed in a tight pile beneath it…
    expect(find.text('First task'), findsOneWidget);
    expect(find.text('CARD 01 OF 02'), findsOneWidget);
    expect(find.text('#02'), findsOneWidget);
    // …due prefix deduped (`DUE 14:00`, never `DUE DUE …`).
    expect(find.text('DUE 14:00 HRS'), findsOneWidget);
    // Page 2 itself is lazily built: its title shows only in the pile.
    expect(find.text('Second task'), findsOneWidget);
    // Subtask checklist on the top card (async provider needs a settle).
    await tester.pumpAndSettle();
    expect(find.text('Book room'), findsOneWidget);
    expect(find.text('Print agenda'), findsOneWidget);

    // Vertical scroll pages through the cards inside the deck and back.
    await tester.fling(find.text('First task'), const Offset(0, -400), 800);
    await tester.pumpAndSettle();
    expect(find.text('Second task'), findsOneWidget);
    expect(find.text('CARD 02 OF 02'), findsOneWidget);
    await tester.fling(find.text('Second task'), const Offset(0, 400), 800);
    await tester.pumpAndSettle();
    expect(find.text('CARD 01 OF 02'), findsOneWidget);
  });

  testWidgets('TimelineSection renders dashed empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: TimelineSection(
              index: '[01]',
              title: 'TOMORROW // TUE OCT 06',
              tasks: [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TOMORROW // TUE OCT 06'), findsOneWidget);
    expect(find.text('No tasks scheduled'), findsOneWidget);
    expect(find.text('+ Plan time block'), findsOneWidget);
  });

  testWidgets('Overdue row stamps the missed day and time', (
    WidgetTester tester,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final iso =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimelineSection(
                index: '[!!]',
                title: 'OVERDUE // PAST DUE',
                tasks: [
                  TodoTask(
                    id: 9,
                    title: 'Late bill',
                    category: 'ERRANDS',
                    dueDate: iso,
                    dueTime: '18:00',
                  ),
                ],
                inverted: false,
                showDueDate: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('DUE YESTERDAY 18:00 HRS'), findsOneWidget);
  });

  testWidgets('Detail add button opens locked-category sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsProvider.overrideWith(
            (ref) async => const [TaskList(id: 1, name: 'WORK', code: 'CRIT')],
          ),
          tasksProvider.overrideWith((ref, args) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ListDetailPage(
            list: TaskList(id: 1, name: 'WORK', code: 'CRIT'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Add task'), findsOneWidget);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // Locked single pill + locked tag (app bar behind also says WORK).
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('WORK'), findsWidgets);
    // Tapping the locked pill explains filing elsewhere.
    await tester.tap(find.text('WORK').last);
    await tester.pumpAndSettle();
    expect(find.text('Category locked'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
    await tester.tap(find.text('Stay here'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);
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

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('2026-04-16'), findsOneWidget);
    expect(find.text('10:00 HRS'), findsOneWidget);
    expect(find.text('First sub'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Subtasks'));
    await tester.pump();
    await tester.tap(find.text('Subtasks'));
    await tester.pump();
    await tester.ensureVisible(find.text('+ Add subtask'));
    await tester.tap(find.text('+ Add subtask'));
    await tester.pump();
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('REQUIRED*'), findsOneWidget);
    // Row stays open for correction.
    expect(find.text('+ Add subtask'), findsNothing);
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
        child: MaterialApp(theme: AppTheme.light(), home: const ListsPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('PERSONAL'), findsWidgets);
    expect(find.text('WORK'), findsWidgets);
    expect(find.text('READING LIST'), findsOneWidget);
    expect(find.text('[SEC 01]'), findsOneWidget);
    expect(find.text('[SEC 02]'), findsOneWidget);
    expect(find.text('Create new list'), findsOneWidget);
  });

  testWidgets('CoreListCard badges follow queue state', (
    WidgetTester tester,
  ) async {
    ListCounts countsFor(int id) {
      switch (id) {
        case 1:
          return (
            total: 2,
            completed: 0,
            hasHigh: true,
            hasActionable: true,
            nextId: 11,
            nextTitle: 'Fix roof',
            nextDone: false,
          );
        case 2:
          return (
            total: 2,
            completed: 2,
            hasHigh: false,
            hasActionable: false,
            nextId: 21,
            nextTitle: 'Water plants',
            nextDone: true,
          );
        case 3:
          return (
            total: 1,
            completed: 0,
            hasHigh: false,
            hasActionable: false,
            nextId: 31,
            nextTitle: 'File papers',
            nextDone: false,
          );
        default:
          return (
            total: 3,
            completed: 1,
            hasHigh: false,
            hasActionable: true,
            nextId: 41,
            nextTitle: 'Call bank',
            nextDone: false,
          );
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listCountsProvider.overrideWith((ref, arg) async => countsFor(arg)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 1; i <= 4; i++)
                    CoreListCard(
                      list: TaskList(id: i, name: 'L$i', code: 'C$i'),
                      index: '0$i',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.text('QUEUED'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('ARCHIVED'), findsOneWidget);
    expect(find.text('1 OF 3 TASKS COMPLETED'), findsOneWidget);
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
            TodoTask(title: 'D', category: 'PERSONAL', dueDate: '2026-04-15'),
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

  test(
    'bucketTasks groups by date, heads undone-today, drops done history',
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
      expect(groups.tomorrow.map((t) => t.title).toList(), [
        'tomorrow',
        'tomorrow done',
      ]);
      expect(groups.laterThisWeek.map((t) => t.title), ['friday']);
      expect(groups.nextBeyond.map((t) => t.title), ['later']);
    },
  );

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
              TodoTask(title: 'Later task', category: 'HOME', dueDate: later),
              TodoTask(title: 'Next task', category: 'WORK', dueDate: next),
            ],
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const UpcomingPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Upcoming'), findsWidgets);
    expect(find.textContaining('Tomorrow'), findsWidgets);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.textContaining('Today //'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsOneWidget);
    // Later rows live under the later segment now: switch to it.
    await tester.tap(find.text('[ Later ]'));
    await tester.pump();
    expect(find.text('Later task'), findsOneWidget);
    expect(find.textContaining('Later this week'), findsOneWidget);
    // The later bucket is populated in this test, so there is no empty-state CTA to assert.
  });

  test('todayTasksProvider shows due-today plus overdue undone', () async {
    final today = isoDay(dayOf(DateTime.now()));
    final yesterday = isoDay(
      dayOf(DateTime.now()).subtract(const Duration(days: 1)),
    );
    final tomorrow = isoDay(dayOf(DateTime.now()).add(const Duration(days: 1)));
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
            TodoTask(title: 'overdue', category: 'WORK', dueDate: yesterday),
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
    expect(tasks.map((t) => t.title).toSet(), {
      'today',
      'today done',
      'overdue',
    });
  });

  test('buildIcs maps timed, all-day and escaped content', () {
    final ics = buildIcs(const [
      TodoTask(
        id: 7,
        title: 'Review, sync; ship',
        notes: 'Room 4B',
        category: 'WORK',
        dueDate: '2026-04-16',
        dueTime: '10:00 AM',
        priority: 3,
      ),
      TodoTask(title: 'No time task', category: 'HOME', dueDate: '2026-04-17'),
    ], now: DateTime.utc(2026, 4, 14, 12));

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

    expect(exportableTasks(groups).map((t) => t.title).toList(), [
      'past',
      'next',
    ]);
  });

  testWidgets('Settings hub lists sections without profile chrome', (
    WidgetTester tester,
  ) async {
    // Tall surface so the whole lazy list builds without scrolling.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const SettingsPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Data & backup'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Free tier'), findsNothing);
    expect(find.byIcon(Icons.account_circle), findsNothing);
    expect(find.textContaining('ID:'), findsNothing);
  });

  testWidgets('Appearance page renders prefs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppearancePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Default screen'), findsOneWidget);
    expect(find.text('Week start'), findsOneWidget);
  });

  testWidgets('Notifications page renders toggles', (
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

    expect(find.text('Task reminders'), findsOneWidget);
    expect(find.text('Daily morning briefing'), findsOneWidget);
    expect(find.text('Streak reminder'), findsOneWidget);
  });

  testWidgets('Data page renders vault', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const DataPage()),
      ),
    );
    await tester.pump();

    // Data vault sits below the fold: scroll it into view first.
    await tester.scrollUntilVisible(find.text('Reset all data').last, 500);
    expect(find.text('Reset all data').last, findsOneWidget);
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
    expect(container.read(settingsControllerProvider).theme, ThemeSetting.dark);
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
    expect(lines.first, contains('recurrence'));
    expect(lines[1], contains('"Say ""hi"", now"'));
  });

  group('reminders', () {
    test('notificationId is stable and unique per kind', () {
      expect(notificationId(7, ReminderKind.hourBefore), 70);
      expect(notificationId(7, ReminderKind.halfHourBefore), 71);
      expect(notificationId(7, ReminderKind.overdue), 72);
      expect(notificationId(8, ReminderKind.hourBefore), 80);
    });

    test('timed task schedules 1h + 30m + on-time alarms', () {
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
        ReminderKind.atStart,
      ]);
      expect(reminders[0].fireAt, DateTime(2026, 4, 15, 14));
      expect(reminders[1].fireAt, DateTime(2026, 4, 15, 14, 30));
      expect(reminders[2].fireAt, DateTime(2026, 4, 15, 15));
      expect(reminders[0].body, contains('DUE IN 1 HOUR'));
      expect(reminders[1].body, contains('DUE IN 30 MINUTES'));
      expect(reminders[2].body, contains('STARTING NOW'));
      expect(reminders[2].id, notificationId(7, ReminderKind.atStart));
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
        TodoTask(
          id: 1,
          title: 'Alpha',
          category: 'WORK',
          dueDate: '2026-04-13',
        ),
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
      expect(digest.title, '2 OVERDUE');
      expect(digest.body, contains('Alpha'));
      expect(digest.body, contains('Beta'));
      expect(digest.body.contains('Finished'), isFalse);
    });

    test('staggered dues produce one digest per morning', () {
      final now = DateTime(2026, 4, 15, 12);
      const tasks = [
        TodoTask(id: 1, title: 'Old', category: 'WORK', dueDate: '2026-04-13'),
        TodoTask(
          id: 2,
          title: 'Later',
          category: 'WORK',
          dueDate: '2026-04-20',
        ),
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
        overdueDigest(DateTime(2026, 4, 16, 8), const [
          TodoTask(
            id: 1,
            title: 'Future',
            category: 'WORK',
            dueDate: '2026-04-20',
          ),
        ]),
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
      expect(androidSoundFor(ReminderKind.overdue), 'nudge_chime');
      expect(androidSoundFor(ReminderKind.atStart), 'overdue_tone');
      expect(iosSoundFor(ReminderKind.hourBefore), 'nudge_chime.aiff');
      expect(iosSoundFor(ReminderKind.overdue), 'nudge_chime.aiff');
      expect(iosSoundFor(ReminderKind.atStart), 'overdue_tone.aiff');
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
      expect(reminders, hasLength(3));
      for (final r in reminders) {
        expect(parseReminderPayload(r.payload).taskId, 7);
      }
      expect(reminders.last.kind, ReminderKind.atStart);
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
      expect(parseReminderPayload(reminders.single.payload).taskId, 7);
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
        ReminderKind.atStart,
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
      final alarmActs = androidReminderActions(ReminderKind.atStart);
      expect(alarmActs.map((a) => a.id).toList(), [actionDismiss, actionSnooze]);
      for (final a in alarmActs) {
        expect(a.icon, isNotNull);
        expect(a.showsUserInterface, isFalse);
      }
      final estActs = androidReminderActions(ReminderKind.estimatedDone);
      expect(estActs.map((a) => a.id).toList(), [actionDone, actionExtend]);
      for (final a in estActs) {
        expect(a.icon, isNotNull);
        expect(a.showsUserInterface, isFalse);
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
      expect(ids, {
        70,
        71,
        73,
        digestId(DateTime(2026, 4, 16, 8)),
        reminderGroupSummaryId,
      });
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

    test('daily toggles gate briefing and streak ids', () {
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
      // Off by default: unchanged legacy set.
      expect(desiredIdsFor(tasks, now, null), {
        70,
        71,
        73,
        digestId(DateTime(2026, 4, 16, 8)),
        reminderGroupSummaryId,
      });
      // Briefing adds its fixed id.
      expect(
        desiredIdsFor(tasks, now, null, briefing: true),
        contains(briefingNotificationId),
      );
      // Streak fires only when tasks remain.
      expect(
        desiredIdsFor(tasks, now, null, streak: true),
        contains(streakNotificationId),
      );
      expect(desiredIdsFor(const [], now, null, streak: true), isEmpty);
    });

    test('remainingToday counts due-today plus overdue undone', () {
      final now = DateTime(2026, 4, 15, 12);
      expect(
        remainingToday(const [
          TodoTask(title: 'A', category: 'W', dueDate: '2026-04-15'),
          TodoTask(title: 'B', category: 'W', dueDate: '2026-04-14'),
          TodoTask(
            title: 'C',
            category: 'W',
            dueDate: '2026-04-14',
            done: true,
          ),
          TodoTask(title: 'D', category: 'W', dueDate: '2026-04-16'),
        ], now),
        2,
      );
      expect(remainingToday(const [], now), 0);
    });

    test('daily fires land on next 08:00 / 20:00', () {
      expect(
        nextBriefingFire(DateTime(2026, 4, 15, 7)),
        DateTime(2026, 4, 15, 8),
      );
      expect(
        nextBriefingFire(DateTime(2026, 4, 15, 9)),
        DateTime(2026, 4, 16, 8),
      );
      expect(
        nextStreakFire(DateTime(2026, 4, 15, 19)),
        DateTime(2026, 4, 15, 20),
      );
      expect(
        nextStreakFire(DateTime(2026, 4, 15, 21)),
        DateTime(2026, 4, 16, 20),
      );
    });

    test('computeStreak counts consecutive completed days', () {
      final now = DateTime(2026, 4, 15, 12);
      TodoTask t(String day, {bool done = true}) =>
          TodoTask(title: 'T$day', category: 'W', dueDate: day, done: done);
      // 3-day run ending today.
      expect(
        computeStreak([t('2026-04-15'), t('2026-04-14'), t('2026-04-13')], now),
        3,
      );
      // In-progress today doesn't break history.
      expect(
        computeStreak([
          t('2026-04-15', done: false),
          t('2026-04-14'),
          t('2026-04-13'),
        ], now),
        2,
      );
      // Gap resets (incomplete day breaks, even with history behind it).
      expect(
        computeStreak([
          t('2026-04-15'),
          t('2026-04-14', done: false),
          t('2026-04-13'),
        ], now),
        1,
      );
      // Empty days are skipped: neither count nor break.
      expect(computeStreak([t('2026-04-15'), t('2026-04-13')], now), 2);
      // Empty history = 0.
      expect(computeStreak(const [], now), 0);
    });

    test('nextDueDate steps daily and weekly', () {
      expect(nextDueDate('2026-04-15', 'DAILY'), '2026-04-16');
      expect(nextDueDate('2026-04-15', 'WEEKLY'), '2026-04-22');
      expect(nextDueDate('2026-04-15', 'NONE'), '2026-04-15');
      expect(nextDueDate('2026-04-15', 'daily'), '2026-04-16');
      expect(nextDueDate('not-a-date', 'DAILY'), 'not-a-date');
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

    test('parseBackupBundle accepts export output', () {
      const jsonText =
          '{"exported_at":"2026-10-12T00:00:00","lists":[{"id":1,"name":"WORK","code":"CRIT","description":"","sort":1}],'
          '"tasks":[{"id":5,"list_id":1,"title":"X","notes":"","category":"WORK","due_date":"2026-10-12","due_time":"09:00 HRS","priority":3,"done":0,"focus":0,"sort":0}],'
          '"subtasks":[{"id":2,"task_id":5,"title":"Sub","done":0}],'
          '"settings":{"theme":"dark"}}';
      final bundle = parseBackupBundle(jsonText);
      expect(bundle.lists.length, 1);
      expect(bundle.tasks.length, 1);
      expect(bundle.subtasks.length, 1);
      expect(bundle.settings['theme'], 'dark');
    });

    test('parseBackupBundle rejects invalid payloads', () {
      expect(() => parseBackupBundle('[]'), throwsFormatException);
      final empty = parseBackupBundle('{"tasks":[]}');
      expect(empty.tasks, isEmpty);
      expect(empty.lists, isEmpty);
      expect(
        () => parseBackupBundle(
          '{"lists":[],"tasks":[{"title":"","due_date":"2026-10-12"}],"subtasks":[]}',
        ),
        throwsFormatException,
      );
      expect(
        () => parseBackupBundle(
          '{"lists":[],"tasks":[{"title":"X","due_date":""}],"subtasks":[]}',
        ),
        throwsFormatException,
      );
    });

    test('parseTasksCsv accepts quoted hand-authored rows', () {
      const csvText =
          'title,due_date,due_time,category,priority,recurrence,done,notes\n'
          '"Fix sink, now",2026-10-20,09:00 HRS,HOME,2,WEEKLY,0,"Trap ""U"" bend"\n'
          'Call bank,2026-10-21,,,1,,no,\n';
      final rows = parseTasksCsv(csvText);
      expect(rows.length, 2);
      expect(rows[0]['title'], 'Fix sink, now');
      expect(rows[0]['due_date'], '2026-10-20');
      expect(rows[0]['category'], 'HOME');
      expect(rows[0]['priority'], 2);
      expect(rows[0]['recurrence'], 'WEEKLY');
      expect(rows[0]['notes'], 'Trap "U" bend');
      expect(rows[1]['category'], 'PERSONAL');
      expect(rows[1]['done'], 0);
      expect(rows[1]['due_time'], isNull);
    });

    test('parseTasksCsv rejects bad rows with line numbers', () {
      expect(
        () => parseTasksCsv('title,due_date\n,2026-10-20\n'),
        throwsFormatException,
      );
      expect(
        () => parseTasksCsv('title,due_date\nX,\n'),
        throwsFormatException,
      );
      expect(
        () => parseTasksCsv('title,due_date\nX,20-10-2026\n'),
        throwsFormatException,
      );
      expect(() => parseTasksCsv('title\nX\n'), throwsFormatException);
      expect(() => parseTasksCsv(''), throwsFormatException);
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
            TodoTask(title: 'C', category: 'PERSONAL', dueDate: '2026-04-15'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(listTasksProvider(1).future);
    expect(tasks.map((t) => t.title).toList(), ['A', 'B']);
  });

  group('Responsive navigation', () {
    testWidgets('Portrait renders BottomNav and no SideNavRail', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayTasksProvider.overrideWith((ref) async => []),
            todayBaseTasksProvider.overrideWith((ref) async => []),
            todayCategoryCountsProvider.overrideWith(
              (ref) async => <String?, int>{null: 0},
            ),
            todayCountsProvider.overrideWith(
              (ref) async => (total: 0, completed: 0, remaining: 0),
            ),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump();

      expect(find.byType(BottomNav), findsOneWidget);
      expect(find.byType(SideNavRail), findsNothing);
    });

    testWidgets('Landscape renders SideNavRail and no BottomNav', (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayTasksProvider.overrideWith((ref) async => []),
            todayBaseTasksProvider.overrideWith((ref) async => []),
            todayCategoryCountsProvider.overrideWith(
              (ref) async => <String?, int>{null: 0},
            ),
            todayCountsProvider.overrideWith(
              (ref) async => (total: 0, completed: 0, remaining: 0),
            ),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pump();

      expect(find.byType(SideNavRail), findsOneWidget);
      expect(find.byType(BottomNav), findsNothing);
    });

    testWidgets('HomePage renders in landscape without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayTasksProvider.overrideWith((ref) async => []),
            todayBaseTasksProvider.overrideWith((ref) async => []),
            todayCategoryCountsProvider.overrideWith(
              (ref) async => <String?, int>{null: 0},
            ),
            todayCountsProvider.overrideWith(
              (ref) async => (total: 0, completed: 0, remaining: 0),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('TODAY'), findsWidgets);
      expect(find.text('Add task'), findsOneWidget);
    });

    testWidgets('UpcomingPage renders in landscape without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksProvider.overrideWith((ref, args) async => []),
          ],
          child: const MaterialApp(home: UpcomingPage()),
        ),
      );
      await tester.pump();

      expect(find.byType(UpcomingPage), findsOneWidget);
      expect(find.byType(DayStrip), findsOneWidget);
      expect(find.text('Upcoming'), findsWidgets);
    });
  });
}
