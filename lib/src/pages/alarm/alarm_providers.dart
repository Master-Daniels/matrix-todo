import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of an actively ringing alarm to display on [AlarmRingingPage].
class RingingAlarmInfo {
  final int nid;
  final int? taskId;
  final String title;
  final String body;
  final String? dueTime;
  final String? category;
  final int priority;
  final String notes;
  final bool isTest;

  const RingingAlarmInfo({
    required this.nid,
    this.taskId,
    required this.title,
    required this.body,
    this.dueTime,
    this.category,
    this.priority = 1,
    this.notes = '',
    this.isTest = false,
  });
}

/// Global provider for actively ringing alarms. When non-null, the full-screen
/// [AlarmRingingPage] takes over the screen until dismissed or snoozed.
final ringingAlarmProvider =
    NotifierProvider<RingingAlarmNotifier, RingingAlarmInfo?>(
  RingingAlarmNotifier.new,
);

class RingingAlarmNotifier extends Notifier<RingingAlarmInfo?> {
  @override
  RingingAlarmInfo? build() => null;

  void trigger(RingingAlarmInfo info) {
    state = info;
  }

  void dismiss() {
    state = null;
  }
}
