import '../../../data/models.dart';
import '../../../data/task_dates.dart';

const weekdayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

const monthShort = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// `WED APR 15`.
String fmtDayBadge(DateTime d) =>
    '${weekdayShort[d.weekday - 1]} ${monthShort[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';

/// `APR 16 - 19` range label for two dates.
String fmtRange(DateTime from, DateTime to) =>
    '${monthShort[from.month - 1]} ${from.day} - ${to.day}';

/// Normalized time: `HH:MM HRS` 24h via [parseEventTime], `''` when untimed.
/// Falls back to stripped uppercased raw when unparseable but non-empty.
String normalizeDueTime(String? raw) {
  final t = parseEventTime(raw);
  if (t != null) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} HRS';
  }
  final r = (raw ?? '').trim().replaceFirst(
    RegExp(r'^DUE\s+', caseSensitive: false),
    '',
  ).trim();
  return r.toUpperCase();
}

/// Trailing due stamp for a task row: normalized `HH:MM HRS` (or `ANYTIME`
/// when untimed) by default; with [showDate], the due day + time
/// (`DUE YESTERDAY 18:00 HRS`, `DUE WED APR 15 10:00 HRS`) for overdue rows.
String fmtDueStamp(TodoTask task, {required bool showDate}) {
  final normTime = normalizeDueTime(task.dueTime);
  if (!showDate) {
    return normTime.isEmpty ? 'ANYTIME' : normTime;
  }
  final day = tryParseDueDate(task.dueDate);
  final today = dayOf(DateTime.now());
  final String dayPart;
  if (day == null) {
    dayPart = task.dueDate.toUpperCase();
  } else {
    final behind = today.difference(dayOf(day)).inDays;
    if (behind == 1) {
      dayPart = 'YESTERDAY';
    } else if (behind <= 0) {
      dayPart = 'TODAY';
    } else {
      dayPart = fmtDayBadge(day);
    }
  }

  return normTime.isEmpty
      ? 'DUE $dayPart'
      : 'DUE $dayPart $normTime';
}
