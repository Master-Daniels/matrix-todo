// Shared date helpers for schedule bucketing. ISO `yyyy-MM-dd` is the
// canonical stored form (`TodoTask.dueDate` is non-nullable).

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

String isoDay(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses ISO `yyyy-MM-dd`. Null when unparseable (defensive only).
DateTime? tryParseDueDate(String dueDate) {
  try {
    final parts = dueDate.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}

bool isToday(DateTime day, DateTime now) =>
    day.isAtSameMomentAs(dayOf(now));

bool isOverdueDay(DateTime day, DateTime now) =>
    day.isBefore(dayOf(now));

/// `HH:MM` 24h match within free-text `dueTime` (`10:00 AM`, `15:00 HRS`,
/// `DUE 14:00`). Null when unparseable.
({int hour, int minute})? parseEventTime(String? dueTime) {
  if (dueTime == null) return null;
  final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(dueTime);
  if (m == null) return null;
  var hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  if (minute > 59) return null;
  final upper = dueTime.toUpperCase();
  if (upper.contains('PM') && hour < 12) hour += 12;
  if (upper.contains('AM') && hour == 12) hour = 0;
  if (hour > 23) return null;
  return (hour: hour, minute: minute);
}

/// First day of the week containing [now] for a Monday(1)..Sunday(7) start.
DateTime weekStartOf(DateTime now, int weekStart) {
  final today = dayOf(now);
  return today.subtract(Duration(days: (today.weekday - weekStart) % 7));
}

/// Last day (start + 6) of that week.
DateTime weekEndOf(DateTime now, int weekStart) =>
    weekStartOf(now, weekStart).add(const Duration(days: 6));
