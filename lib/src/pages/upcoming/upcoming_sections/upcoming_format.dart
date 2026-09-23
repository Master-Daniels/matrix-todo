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
