import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/pages/add_task/add_task_sections/recurrence_section.dart';
import 'package:matrix_todo/src/theme/app_theme.dart';

void main() {
  testWidgets('RecurrenceSection renders presets and updates rule on select', (
    WidgetTester tester,
  ) async {
    RecurrenceRule? updatedRule;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RecurrenceSection(
                rule: updatedRule,
                onChange: (rule) {
                  setState(() => updatedRule = rule);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify presets are displayed
    expect(find.text('Never ■'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Custom...'), findsOneWidget);
    expect(find.text('Does not repeat'), findsOneWidget);

    // Tap Daily preset
    await tester.tap(find.text('Daily'));
    await tester.pump();

    expect(updatedRule, isNotNull);
    expect(updatedRule!.frequency, 'DAILY');
    expect(updatedRule!.interval, 1);
    expect(find.textContaining('Repeats every day'), findsOneWidget);

    // Tap Weekdays preset
    await tester.tap(find.text('Weekdays'));
    await tester.pump();

    expect(updatedRule!.frequency, 'WEEKLY');
    expect(updatedRule!.weekdays, [1, 2, 3, 4, 5]);
    expect(find.textContaining('Repeats every weekday'), findsOneWidget);

    // Tap "Adjust" to reveal custom options
    await tester.tap(find.text('Adjust'));
    await tester.pump();

    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('On days'), findsOneWidget);
    expect(find.text('Ends'), findsOneWidget);
  });
}
