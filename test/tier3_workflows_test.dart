import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/pages/add_task/add_task_sections/datetime_section.dart';
import 'package:matrix_todo/src/pages/lists/list_form_sheet.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_page.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_providers.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_sections/day_strip.dart';
import 'package:matrix_todo/src/pages/upcoming/upcoming_sections/task_popover.dart';
import 'package:matrix_todo/src/theme/app_theme.dart';
import 'package:matrix_todo/src/widgets/search_sheet.dart';

void main() {
  testWidgets('DayStrip renders days and handles day selection tap', (tester) async {
    DateTime? selected;
    final monday = DateTime(2026, 11, 2);
    final mockDays = List.generate(
      7,
      (i) => (day: monday.add(Duration(days: i)), count: i + 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekStripProvider.overrideWith((ref) async => mockDays),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DayStrip(
              selectedDay: null,
              onSelectDay: (d) => selected = d,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify weekday indicators
    expect(find.text('MON'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);

    // Tap Wednesday (index 2)
    await tester.tap(find.text('WED'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.weekday, DateTime.wednesday);
  });

  testWidgets('ListFormSheet in edit mode initializes with existing list properties',
      (tester) async {
    const existingList = TaskList(
      id: 42,
      name: 'PROJECT TITAN',
      code: 'TITAN',
      description: 'Crucial missions',
      sort: 5,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListFormSheet(list: existingList),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('[~] Edit Category'), findsOneWidget);
    expect(find.text('PROJECT TITAN'), findsOneWidget);
    expect(find.text('Crucial missions'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('TaskPopover shows confirm deletion dialog on delete tap', (tester) async {
    const task = TodoTask(
      id: 101,
      title: 'Review PR',
      category: 'WORK',
      dueDate: '2026-11-05',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskPopover(task: task),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap popover menu trigger
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Delete task
    await tester.tap(find.text('Delete task'));
    await tester.pumpAndSettle();

    // Confirm dialog should be visible
    expect(find.text('Delete task?'), findsOneWidget);
    expect(find.textContaining('Delete "Review PR"? This cannot be undone.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('DateTimeSection renders quick date chips and invokes onSelectDate', (tester) async {
    DateTime selected = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DateTimeSection(
            date: selected,
            time: null,
            onPickDate: () {},
            onPickTime: () {},
            onSelectDate: (d) => selected = d,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('■ TODAY'), findsOneWidget);
    expect(find.text('TOMORROW'), findsOneWidget);
    expect(find.text('+2 DAYS'), findsOneWidget);
    expect(find.text('NEXT WEEK'), findsOneWidget);

    await tester.tap(find.text('TOMORROW'));
    await tester.pump();

    final now = DateTime.now();
    final expectedTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    expect(selected.year, expectedTomorrow.year);
    expect(selected.month, expectedTomorrow.month);
    expect(selected.day, expectedTomorrow.day);
  });

  testWidgets('UpcomingPage includes search action in app bar and opens SearchSheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const UpcomingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchIcon = find.byIcon(Icons.search);
    expect(searchIcon, findsOneWidget);

    await tester.tap(searchIcon);
    await tester.pumpAndSettle();

    expect(find.byType(SearchSheet), findsOneWidget);
  });
}
