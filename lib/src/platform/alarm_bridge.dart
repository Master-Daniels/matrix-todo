import 'package:flutter/services.dart';

/// Dart bridge for the Android native AlarmService platform channel (`matrix_todo/alarm`).
///
/// Starts and stops the native Foreground Service playing `overdue_tone`
/// on `USAGE_ALARM` with transient exclusive audio focus.
class AlarmBridge {
  static const MethodChannel _channel = MethodChannel('matrix_todo/alarm');

  /// Starts the native AlarmService foreground playback.
  static Future<bool> startAlarm({
    required String title,
    required String body,
    required int nid,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('startAlarm', {
        'title': title,
        'body': body,
        'nid': nid,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops the native AlarmService foreground playback and abandons audio focus.
  static Future<bool> stopAlarm() async {
    try {
      final res = await _channel.invokeMethod<bool>('stopAlarm');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Probes whether the native AlarmService is currently running and playing.
  static Future<bool> isAlarmActive() async {
    try {
      final res = await _channel.invokeMethod<bool>('isAlarmActive');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
