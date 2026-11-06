import 'package:flutter_test/flutter_test.dart';

import 'package:matrix_todo/src/data/models.dart';
import 'package:matrix_todo/src/data/recurrence_engine.dart';
import 'package:matrix_todo/src/data/task_dates.dart';

void main() {
  group('nextOccurrenceDate', () {
    test('DAILY every day returns next calendar day', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 10)),
        '2026-04-11',
      );
    });

    test('DAILY every 2 days skips one day', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 2,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      // From April 9 (aligned: diff=8, even), next is April 11 (diff=10, even).
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 9)),
        '2026-04-11',
      );
    });

    test('DAILY weekdays only skips weekends', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        weekdays: [1, 2, 3, 4, 5], // Mon-Fri
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      // Friday -> next Monday
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 10)), // Friday
        '2026-04-13', // Monday
      );
    });

    test('WEEKLY every week on same weekday', () {
      final rule = RecurrenceRule(
        frequency: 'WEEKLY',
        interval: 1,
        weekdays: [3], // Wednesday
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      // From a Wednesday, next is +7 days
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 1)), // Wednesday
        '2026-04-08',
      );
    });

    test('WEEKLY every 2 weeks', () {
      final rule = RecurrenceRule(
        frequency: 'WEEKLY',
        interval: 2,
        weekdays: [1], // Monday
        startDate: '2026-04-06', // Monday
        endCondition: 'never',
      );
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 6)), // Monday
        '2026-04-20', // +2 weeks
      );
    });

    test('MONTHLY fixed day', () {
      final rule = RecurrenceRule(
        frequency: 'MONTHLY',
        interval: 1,
        monthDay: 15,
        startDate: '2026-01-01',
        endCondition: 'never',
      );
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 1, 10)),
        '2026-01-15',
      );
    });

    test('MONTHLY fixed day clamps to month end', () {
      final rule = RecurrenceRule(
        frequency: 'MONTHLY',
        interval: 1,
        monthDay: 31,
        startDate: '2026-01-01',
        endCondition: 'never',
      );
      // Jan 31 -> Feb 28 (clamped)
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 1, 31)),
        '2026-02-28',
      );
    });

    test('MONTHLY last day of month', () {
      final rule = RecurrenceRule(
        frequency: 'MONTHLY',
        interval: 1,
        monthLastDay: true,
        startDate: '2026-01-01',
        endCondition: 'never',
      );
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 1, 15)),
        '2026-01-31',
      );
      // Next should be Feb 28
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 1, 31)),
        '2026-02-28',
      );
    });

    test('MONTHLY nth weekday (2nd Tuesday)', () {
      final rule = RecurrenceRule(
        frequency: 'MONTHLY',
        interval: 1,
        monthNth: 2,
        monthNthWeekday: 2, // Tuesday
        startDate: '2026-01-01',
        endCondition: 'never',
      );
      // April 2026: 2nd Tuesday is April 14
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 1)),
        '2026-04-14',
      );
    });

    test('end condition on_date stops after end date', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endDate: '2026-04-05',
        endCondition: 'on_date',
      );
      // From April 4, next is April 5 (on end date, OK)
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 4)),
        '2026-04-05',
      );
      // From April 5, next would be April 6 which is after end date -> null
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 5)),
        isNull,
      );
    });

    test('start date in future is respected', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-20',
        endCondition: 'never',
      );
      // From April 10, next should be April 20 (start date), not April 11
      expect(
        nextOccurrenceDate(rule, DateTime(2026, 4, 10)),
        '2026-04-20',
      );
    });

    test('skips exception dates', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final exceptions = {'2026-04-11'};
      // April 10 -> April 11 is skipped -> April 12
      expect(
        nextOccurrenceDate(
          rule,
          DateTime(2026, 4, 10),
          exceptions: exceptions,
        ),
        '2026-04-12',
      );
    });

    test('returns null when all remaining dates are exceptions', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endDate: '2026-04-03',
        endCondition: 'on_date',
      );
      final exceptions = {'2026-04-02', '2026-04-03'};
      expect(
        nextOccurrenceDate(
          rule,
          DateTime(2026, 4, 1),
          exceptions: exceptions,
        ),
        isNull,
      );
    });
  });

  group('nextOccurrences (multiple times)', () {
    test('single time returns one occurrence', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        times: [RecurrenceTime(timeOfDay: '09:00')],
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final occs = nextOccurrences(rule, DateTime(2026, 4, 10));
      expect(occs, hasLength(1));
      expect(occs.first.time, '09:00');
      expect(isoDay(occs.first.date), '2026-04-11');
    });

    test('multiple times returns one per time', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        times: [
          RecurrenceTime(timeOfDay: '08:00'),
          RecurrenceTime(timeOfDay: '17:00'),
        ],
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final occs = nextOccurrences(rule, DateTime(2026, 4, 10));
      expect(occs, hasLength(2));
      expect(occs[0].time, '08:00');
      expect(occs[1].time, '17:00');
      expect(isoDay(occs[0].date), '2026-04-11');
      expect(isoDay(occs[1].date), '2026-04-11');
    });

    test('no times returns single occurrence with empty time', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final occs = nextOccurrences(rule, DateTime(2026, 4, 10));
      expect(occs, hasLength(1));
      expect(occs.first.time, '');
    });
  });

  group('generateOccurrences (pre-generation)', () {
    test('generates up to horizon days', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final occs = generateOccurrences(
        rule,
        DateTime(2026, 4, 10),
        horizonDays: 5,
      );
      expect(occs, hasLength(5));
      expect(isoDay(occs[0].date), '2026-04-11');
      expect(isoDay(occs[4].date), '2026-04-15');
    });

    test('skips existing dates to avoid duplicates', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final existing = {'2026-04-11', '2026-04-12'};
      final occs = generateOccurrences(
        rule,
        DateTime(2026, 4, 10),
        horizonDays: 5,
        existingDates: existing,
      );
      // April 11 and 12 are skipped, so we get April 13, 14, 15, 16, 17
      expect(occs, hasLength(5));
      expect(isoDay(occs[0].date), '2026-04-13');
      expect(isoDay(occs[4].date), '2026-04-17');
    });

    test('respects exception dates', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final exceptions = {'2026-04-11'};
      final occs = generateOccurrences(
        rule,
        DateTime(2026, 4, 10),
        horizonDays: 3,
        exceptions: exceptions,
      );
      expect(occs, hasLength(3));
      expect(isoDay(occs[0].date), '2026-04-12'); // April 11 skipped
      expect(isoDay(occs[1].date), '2026-04-13');
      expect(isoDay(occs[2].date), '2026-04-14');
    });
  });

  group('RecurrenceRule.summary', () {
    test('daily summary', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 2,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      expect(rule.summary(), contains('↻ DAILY'));
      expect(rule.summary(), contains('every 2'));
    });

    test('weekly with weekdays summary', () {
      final rule = RecurrenceRule(
        frequency: 'WEEKLY',
        interval: 1,
        weekdays: [1, 3, 5], // Mon/Wed/Fri
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      expect(rule.summary(), contains('Mon/Wed/Fri'));
    });

    test('monthly fixed day summary', () {
      final rule = RecurrenceRule(
        frequency: 'MONTHLY',
        interval: 1,
        monthDay: 15,
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      expect(rule.summary(), contains('day 15'));
    });

    test('multiple times in summary', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        times: [
          RecurrenceTime(timeOfDay: '08:00'),
          RecurrenceTime(timeOfDay: '17:00'),
        ],
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      expect(rule.summary(), contains('08:00'));
      expect(rule.summary(), contains('17:00'));
    });
  });

  group('RecurrenceRule.copyWith', () {
    test('copies times correctly', () {
      final rule = RecurrenceRule(
        frequency: 'DAILY',
        times: [RecurrenceTime(timeOfDay: '09:00')],
        startDate: '2026-04-01',
        endCondition: 'never',
      );
      final copied = rule.copyWith(frequency: 'WEEKLY');
      expect(copied.frequency, 'WEEKLY');
      expect(copied.times, hasLength(1));
      expect(copied.times.first.timeOfDay, '09:00');
    });
  });
}
