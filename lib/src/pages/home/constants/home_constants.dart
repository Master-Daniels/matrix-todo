const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];
const _weekdays = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

String todayBadge() {
  final now = DateTime.now();
  final m = _months[now.month - 1];
  return '$m ${now.day.toString().padLeft(2, '0')}, ${now.year}';
}

String weekday() => _weekdays[DateTime.now().weekday - 1];

/// Topbar index for Option 1: `SATURDAY — OCT 11, 2026`.
String todayIndex() => '${weekday()} — ${todayBadge()}';
