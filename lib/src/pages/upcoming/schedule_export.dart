import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../data/models.dart';
import 'upcoming_providers.dart';

/// Undone tasks across the on-screen upcoming groups, in display order.
List<TodoTask> exportableTasks(UpcomingGroups groups) => [
      ...groups.today.where((t) => !t.done),
      ...groups.overdue.where((t) => !t.done),
      ...groups.tomorrow.where((t) => !t.done),
      ...groups.laterThisWeek.where((t) => !t.done),
      ...groups.nextBeyond.where((t) => !t.done),
    ];

String _escape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

/// RFC 5545 75-octet folding (content is ASCII in practice).
String _fold(String line) {
  if (line.length <= 75) return line;
  final out = StringBuffer(line.substring(0, 75));
  var rest = line.substring(75);
  while (rest.isNotEmpty) {
    final chunk = rest.length > 74 ? rest.substring(0, 74) : rest;
    out.write('\r\n $chunk');
    rest = rest.length > 74 ? rest.substring(74) : '';
  }
  return out.toString();
}

String _uid(TodoTask task) {
  if (task.id != null) return 'task-${task.id}@matrix-todo';
  var hash = 0;
  for (final c in '${task.title}|${task.dueDate}'.codeUnits) {
    hash = (hash * 31 + c) & 0x7fffffff;
  }
  return 'task-$hash@matrix-todo';
}

String _stamp(DateTime now) {
  final u = now.toUtc();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${u.year}${p(u.month)}${p(u.day)}T${p(u.hour)}${p(u.minute)}${p(u.second)}Z';
}

/// Pure VCALENDAR builder — no I/O, fully unit-testable.
String buildIcs(List<TodoTask> tasks, {DateTime? now}) {
  final stamp = _stamp(now ?? DateTime.now());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//MATRIX TODO//EN',
    'CALSCALE:GREGORIAN',
  ];
  for (final t in tasks) {
    final date = t.dueDate.replaceAll('-', '');
    final time = parseEventTime(t.dueTime);
    lines.add('BEGIN:VEVENT');
    lines.add('UID:${_uid(t)}');
    lines.add('DTSTAMP:$stamp');
    if (time == null) {
      lines.add('DTSTART;VALUE=DATE:$date');
    } else {
      String p(int v) => v.toString().padLeft(2, '0');
      final end = DateTime(
        2000,
        1,
        1,
        time.hour,
        time.minute,
      ).add(const Duration(hours: 1));
      lines.add('DTSTART:${date}T${p(time.hour)}${p(time.minute)}00');
      lines.add('DTEND:${date}T${p(end.hour)}${p(end.minute)}00');
    }
    lines.add('SUMMARY:${_escape(t.title)}');
    final desc = [
      if (t.notes.isNotEmpty) t.notes,
      'CATEGORY: ${t.category} / PRIORITY: LVL-${t.priority}',
      if ((t.dueTime ?? '').isNotEmpty) 'TIME: ${t.dueTime}',
    ].join('\n');
    lines.add('DESCRIPTION:${_escape(desc)}');
    lines.add('STATUS:NEEDS-ACTION');
    lines.add('END:VEVENT');
  }
  lines.add('END:VCALENDAR');
  return "${lines.map(_fold).join('\r\n')}\r\n";
}

/// Opens a native save-file dialog so the user picks where to save the ICS
/// and returns the saved file URI as a string, or null if the user
/// cancelled. No storage permission needed — the picker grants access to
/// the user-chosen location on every platform.
Future<String?> saveScheduleIcs(List<TodoTask> tasks) async {
  final now = DateTime.now();
  final fileName =
      'matrix-schedule-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.ics';
  final bytes = Uint8List.fromList(utf8.encode(buildIcs(tasks, now: now)));
  final uri = await FilePicker.saveFile(
    dialogTitle: 'Save schedule as ICS',
    fileName: fileName,
    bytes: bytes,
    mimeType: 'text/calendar',
  );
  return uri?.toString();
}
