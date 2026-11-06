/// Pure recurrence date engine.
///
/// All calculations run in local wall-clock time using naive [DateTime].
/// The `timezone` package is available in `pubspec.yaml` for future
/// IANA-zone correctness; Phase 2 keeps naive local dates because tasks
/// store local dates/times without a zone. Date arithmetic uses
/// calendar-day construction (`DateTime(y, m, d + 1)`) rather than
/// `Duration(days: 1)`, so DST transitions never shift a date by a day.
///
/// All functions are pure and unit-testable — no DB, no platform channels.
library;

import 'models.dart';
import 'task_dates.dart';

/// Returns the next calendar day at local midnight, DST-safe.
/// Unlike `DateTime.add(Duration(days: 1))`, this never shifts by a
/// DST hour gap/overlap.
DateTime _nextCalendarDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Returns the current local date at midnight.
/// Uses naive [DateTime.now()] — the `timezone` package remains available
/// for future IANA-zone correctness but isn't required for date arithmetic,
/// which uses calendar-day construction (DST-safe by design).
DateTime _todayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Given a rule and a reference date (usually the last occurrence's due date),
/// returns the next valid ISO due date (`yyyy-MM-dd`), or null when the
/// series has ended (end condition reached or no valid date exists).
///
/// The search starts the day after [fromDate] so the same date is never
/// returned twice. Dates before [rule.startDate] and, when
/// [rule.endCondition] is `on_date`, dates after [rule.endDate] are skipped.
/// Dates in [exceptions] are skipped.
String? nextOccurrenceDate(
  RecurrenceRule rule,
  DateTime fromDate, {
  DateTime? now,
  Set<String>? exceptions,
}) {
  final ruleStart = tryParseDueDate(rule.startDate);
  final end = rule.endCondition == 'on_date' && rule.endDate != null
      ? tryParseDueDate(rule.endDate!)
      : null;

  // Cap the search so an impossible rule can't loop forever.
  final searchLimit = DateTime(
    now != null ? now.year : _todayLocal().year + 5,
  );

  var candidate = _nextCalendarDay(fromDate);

  // Never return before the rule's start date.
  if (ruleStart != null && candidate.isBefore(ruleStart)) {
    candidate = DateTime(ruleStart.year, ruleStart.month, ruleStart.day);
  }

  while (candidate.isBefore(searchLimit) ||
      candidate.isAtSameMomentAs(searchLimit)) {
    // Respect end date.
    if (end != null && candidate.isAfter(end)) return null;

    final iso = isoDay(candidate);
    // Skip exception dates.
    if (exceptions != null && exceptions.contains(iso)) {
      candidate = _nextCalendarDay(candidate);
      continue;
    }

    if (_matchesRule(rule, candidate)) {
      return iso;
    }

    candidate = _advanceCandidate(rule, candidate);
  }

  return null;
}

/// Returns the next valid occurrence(s) for [rule] after [fromDate], as
/// `({DateTime date, String time})` pairs — one per configured time.
///
/// If [rule.times] is non-empty, returns one entry per time on the next
/// valid date. If empty, returns a single entry with an empty time
/// (caller supplies the task's `dueTime`).
///
/// Dates in [exceptions] are skipped.
List<({DateTime date, String time})> nextOccurrences(
  RecurrenceRule rule,
  DateTime fromDate, {
  DateTime? now,
  Set<String>? exceptions,
}) {
  final times = rule.times.isNotEmpty
      ? rule.times.map((t) => t.timeOfDay).toList()
      : <String>[''];

  final date = nextOccurrenceDate(rule, fromDate, now: now, exceptions: exceptions);
  if (date == null) return const [];

  final day = tryParseDueDate(date)!;
  return times.map((t) => (date: day, time: t)).toList();
}

/// Pre-generates future occurrences for [rule] starting after [fromDate],
/// up to [horizonDays] days ahead, returning `({DateTime date, String time})`
/// pairs. Skips dates already present in [existingDates] to avoid duplicates.
///
/// This drives the "pre-generate N future occurrences" behavior: callers
/// insert tasks for each returned pair, then skip any whose date is already
/// covered by an existing task.
List<({DateTime date, String time})> generateOccurrences(
  RecurrenceRule rule,
  DateTime fromDate, {
  int horizonDays = 30,
  DateTime? now,
  Set<String>? exceptions,
  Set<String>? existingDates,
}) {
  final out = <({DateTime date, String time})>[];
  var cursor = fromDate;

  while (out.length < horizonDays) {
    final next = nextOccurrences(
      rule,
      cursor,
      now: now,
      exceptions: exceptions,
    );
    if (next.isEmpty) break;

    for (final occ in next) {
      final iso = isoDay(occ.date);
      if (existingDates != null && existingDates.contains(iso)) continue;
      out.add(occ);
      if (out.length >= horizonDays) break;
    }

    // Advance cursor to the last date found (next search starts from
    // the day after, via nextOccurrenceDate's +1-day offset).
    cursor = next.last.date;
  }

  return out;
}

/// Returns true when [day] satisfies the rule's frequency, interval, and
/// weekday/month constraints.
bool _matchesRule(RecurrenceRule rule, DateTime day) {
  final freq = rule.frequency.trim().toUpperCase();

  switch (freq) {
    case 'DAILY':
      return _matchesDaily(rule, day);
    case 'WEEKLY':
      return _matchesWeekly(rule, day);
    case 'MONTHLY':
      return _matchesMonthly(rule, day);
    default:
      return false;
  }
}

/// Advances [day] to the next plausible candidate based on frequency, so the
/// search doesn't step one day at a time unnecessarily. DST-safe.
///
/// Steps one calendar day at a time for all frequencies — this is correct
/// because [_matchesRule] already enforces interval/weekday/month alignment,
/// so stepping one day never misses a valid date and never returns an invalid
/// one. The performance cost is negligible for typical search horizons.
DateTime _advanceCandidate(RecurrenceRule rule, DateTime day) {
  return _nextCalendarDay(day);
}

/// DAILY: every N days, optionally restricted to selected weekdays.
/// An empty [weekdays] list means every day.
bool _matchesDaily(RecurrenceRule rule, DateTime day) {
  final interval = rule.interval.clamp(1, 99);
  final ruleStart = tryParseDueDate(rule.startDate);
  if (ruleStart == null) return false;

  // Must be interval-aligned from the start date (calendar-day diff).
  final diff = day.difference(ruleStart).inDays;
  if (diff < 0 || diff % interval != 0) return false;

  // Weekday restriction (if any).
  if (rule.weekdays.isNotEmpty && !rule.weekdays.contains(day.weekday)) {
    return false;
  }

  return true;
}

/// WEEKLY: every N weeks, on selected weekdays.
bool _matchesWeekly(RecurrenceRule rule, DateTime day) {
  final interval = rule.interval.clamp(1, 99);
  final ruleStart = tryParseDueDate(rule.startDate);
  if (ruleStart == null) return false;

  // Must fall on a selected weekday (or any day if none selected — treat as
  // every day at weekly cadence).
  if (rule.weekdays.isNotEmpty && !rule.weekdays.contains(day.weekday)) {
    return false;
  }

  // Week-aligned from start date: whole weeks * interval.
  final diffDays = day.difference(ruleStart).inDays;
  if (diffDays < 0 || diffDays % (7 * interval) != 0) return false;

  return true;
}

/// MONTHLY: fixed day, last day, or nth weekday, every N months.
bool _matchesMonthly(RecurrenceRule rule, DateTime day) {
  final interval = rule.interval.clamp(1, 99);
  final ruleStart = tryParseDueDate(rule.startDate);
  if (ruleStart == null) return false;

  // Month-aligned from start date: whole months * interval.
  final monthDiff =
      (day.year - ruleStart.year) * 12 + (day.month - ruleStart.month);
  if (monthDiff < 0 || monthDiff % interval != 0) return false;

  if (rule.monthLastDay) {
    final nextMonth = DateTime(day.year, day.month + 1, 0);
    return day.day == nextMonth.day;
  }

  if (rule.monthNth != null && rule.monthNthWeekday != null) {
    return _isNthWeekday(day, rule.monthNth!, rule.monthNthWeekday!);
  }

  if (rule.monthDay != null) {
    // Clamp the target day to the last valid day of the month
    // (e.g. monthDay 31 in February → 28). Then compare candidate day.
    final nextMonth = DateTime(day.year, day.month + 1, 0);
    final lastDay = nextMonth.day;
    final validDay = rule.monthDay!.clamp(1, lastDay);
    return day.day == validDay;
  }

  return false;
}

/// True when [day] is the [nth] (1–5) occurrence of [weekday] (1–7) in its
/// month. Returns false when the month doesn't have that many occurrences.
bool _isNthWeekday(DateTime day, int nth, int weekday) {
  if (day.weekday != weekday) return false;
  // Count how many times this weekday has occurred so far this month.
  var count = 0;
  var d = DateTime(day.year, day.month, 1);
  while (d.month == day.month) {
    if (d.weekday == weekday) {
      count++;
      if (count == nth && d.day == day.day) return true;
    }
    d = _nextCalendarDay(d);
  }
  return false;
}

/// Build a [RecurrenceRule] from legacy `DAILY`/`WEEKLY` strings for
/// migrating existing tasks (optional helper).
RecurrenceRule legacyRuleFromString(String recurrence, String startDate) {
  final rule = recurrence.trim().toUpperCase();
  switch (rule) {
    case 'DAILY':
      return RecurrenceRule(
        frequency: 'DAILY',
        interval: 1,
        weekdays: const [],
        startDate: startDate,
        endCondition: 'never',
      );
    case 'WEEKLY':
      final day = tryParseDueDate(startDate);
      return RecurrenceRule(
        frequency: 'WEEKLY',
        interval: 1,
        weekdays: day != null ? [day.weekday] : const [],
        startDate: startDate,
        endCondition: 'never',
      );
    default:
      return RecurrenceRule(
        frequency: 'NONE',
        interval: 1,
        startDate: startDate,
        endCondition: 'never',
      );
  }
}
