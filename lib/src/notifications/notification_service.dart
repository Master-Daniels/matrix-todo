import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin transport over `flutter_local_notifications`. No task knowledge:
/// callers pass channel/sound/actions/payload explicitly. Policy (what to
/// schedule, payload scheme, action ids) lives in `reminder_service.dart`.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exactAlarms = false;

  static const remindersChannelId = 'matrix_reminders_v3';
  static const overdueChannelId = 'matrix_overdue_v3';
  static const alarmsChannelId = 'matrix_alarms_v5';

  bool get exactAlarms => _exactAlarms;

  /// Channels, tap routing and the cold-start flag. Idempotent and
  /// permission-free — safe to call in `main()` before `runApp()`.
  /// `onResponse` fires for taps AND foreground action buttons, both when
  /// the app is open and when it is resumed from background.
  Future<void> init({
    required Future<void> Function(NotificationResponse) onResponse,
    void Function(NotificationResponse)? onBackgroundResponse,
    List<DarwinNotificationCategory> darwinCategories = const [],
  }) async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {}
    // UTC is a display container only — every schedule goes through epoch
    // millis, so firing is exact in every device timezone (see reminder
    // policy docs). No timezone plugin required.
    tz.setLocalLocation(tz.UTC);
    debugPrint(
      '[NotificationService] tz.local=UTC (display only); '
      'device now=${DateTime.now()} offset=${DateTime.now().timeZoneOffset} '
      'name=${DateTime.now().timeZoneName}',
    );
    const androidInit = AndroidInitializationSettings('ic_launcher_monochrome');
    final darwinInit = DarwinInitializationSettings(
      notificationCategories: darwinCategories,
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    await ensureChannels();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _exactAlarms = await android?.canScheduleExactNotifications() ?? false;
      debugPrint(
        '[NotificationService] init probed exact alarms: $_exactAlarms',
      );
    } catch (_) {}
    _ready = true;
  }

  /// Creates notification channels with the bundled chimes. Channels are immutable
  /// once created by the OS — any sound/description/attribute change requires a new
  /// channel id (hence the `_v3` suffix convention).
  Future<void> ensureChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Clean up older channel IDs whose sounds or attributes were superseded
    await android?.deleteNotificationChannel(channelId: 'matrix_alarms_v3');
    await android?.deleteNotificationChannel(channelId: 'matrix_alarms_v4');
    await android?.deleteNotificationChannel(channelId: 'matrix_overdue_v2');
    await android?.deleteNotificationChannel(channelId: 'matrix_reminders_v2');

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        alarmsChannelId,
        'ALARMS',
        description: 'Urgent task alarms and test alarms',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('overdue_tone'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        bypassDnd: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        remindersChannelId,
        'REMINDERS',
        description: 'Task reminders before due time',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('nudge_chime'),
        audioAttributesUsage: AudioAttributesUsage.notification,
        enableVibration: true,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        overdueChannelId,
        'OVERDUE',
        description: 'Overdue task nudges',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('nudge_chime'),
        audioAttributesUsage: AudioAttributesUsage.notification,
        enableVibration: true,
      ),
    );
  }

  Future<void> requestExactAlarmsPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<bool> canScheduleExactAlarms() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final allowed = await android?.canScheduleExactNotifications() ?? false;
      _exactAlarms = allowed;
      return allowed;
    } catch (_) {
      return false;
    }
  }

  /// The response that cold-launched the app via a notification tap/action,
  /// or null when the app was launched normally.
  Future<NotificationResponse?> getLaunchResponse() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        return details?.notificationResponse;
      }
    } catch (_) {}
    return null;
  }

  // ---- Permissions (all best-effort, never throw) ----

  /// Ensures plugin is initialized, runtime notification permission is prompted,
  /// exact alarm capability is probed, and iOS alert set is requested.
  Future<void> ensureReady({
    Future<void> Function(NotificationResponse)? onResponse,
  }) async {
    if (!_ready) {
      await init(onResponse: onResponse ?? (_) async {});
    }
    await requestNotificationsPermission();
    await ensureExactAlarms();
    await requestIosPermissions();
  }

  /// Android 13+ runtime prompt. Returns true when notifications are allowed
  /// afterwards. No-op (true) on other platforms.
  Future<bool> requestNotificationsPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      if (granted != null) return granted;
    } catch (_) {}
    return true;
  }

  /// Silent probe — never prompts. Use at startup / before first-task flows
  /// to decide whether prompting is needed.
  Future<bool> areNotificationsEnabled() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled != null) return enabled;
    } catch (_) {}
    return true;
  }

  /// Exact-alarm probe + (on denial) system settings redirect. Updates and
  /// returns the cached [_exactAlarms] flag used by [zonedSchedule].
  Future<bool> ensureExactAlarms() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _exactAlarms = await android?.canScheduleExactNotifications() ?? false;
      debugPrint(
        '[NotificationService] canScheduleExactNotifications: $_exactAlarms',
      );
      if (!_exactAlarms) {
        await android?.requestExactAlarmsPermission();
        _exactAlarms = await android?.canScheduleExactNotifications() ?? false;
        debugPrint(
          '[NotificationService] post-request exact alarms: $_exactAlarms',
        );
      }
    } catch (_) {}
    return _exactAlarms;
  }

  Future<void> requestIosPermissions() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  // ---- Delivery ----

  /// Wraps an exact epoch-millis instant for the plugin. Dart epoch millis
  /// already encode the current offset (including DST), so no
  /// device-timezone lookup is needed. Edge case: a DST transition between
  /// scheduling and firing shifts the wall-clock by the transition — healed
  /// on the next `syncAll`, which runs on every launch and every mutation.
  tz.TZDateTime tzOf(DateTime local) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.UTC,
        local.millisecondsSinceEpoch,
      );

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzOf(fireAt),
      notificationDetails: notificationDetails,
      androidScheduleMode: _exactAlarms
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<List<int>> pendingIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((p) => p.id).toList();
    } catch (_) {
      return [];
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Minimal system bridge for OEM-resilience flows: vendor detection plus
/// settings intents (battery-optimization, app-info, app notifications).
/// Implemented natively in MainActivity (`matrix_todo/system`). Settings
/// screens only — never auto-requests battery exemptions (Play policy).
class SystemBridge {
  static const MethodChannel _channel = MethodChannel('matrix_todo/system');

  static Future<String> manufacturer() async {
    try {
      final value = await _channel.invokeMethod<String>('getManufacturer');
      return (value ?? '').toLowerCase();
    } catch (_) {
      return '';
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  static Future<void> openAppDetailsSettings() async {
    try {
      await _channel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  /// Opens this app's system notification settings (channels, floating
  /// pop-ups, lock-screen visibility, sound). Falls back to app details.
  static Future<void> openAppNotificationSettings() async {
    try {
      await _channel.invokeMethod('openAppNotificationSettings');
    } catch (_) {}
  }

  /// Dynamically enables or disables showing over the lockscreen.
  /// Should only be enabled when an alarm is actively ringing.
  static Future<void> setShowWhenLocked(bool enabled) async {
    try {
      await _channel.invokeMethod('setShowWhenLocked', {'enabled': enabled});
    } catch (_) {}
  }

  /// Sends the app to the background without exiting the process, returning
  /// the user directly to the lock screen or previous app.
  static Future<void> minimize() async {
    try {
      await _channel.invokeMethod('minimize');
    } catch (_) {}
  }
}
