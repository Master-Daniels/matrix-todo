import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../data/task_dates.dart';
import 'notification_service.dart';

/// Reminder slots per task. The index doubles as the notification-id suffix.
/// Append-only: existing indexes are baked into scheduled ids.
enum ReminderKind { hourBefore, halfHourBefore, overdue, atStart }

/// Deterministic id: rescheduling the same task never duplicates.
int notificationId(int taskId, ReminderKind kind) => taskId * 10 + kind.index;

/// Pre-reminder lead times. Reserved for future configurability.
const reminderOffsets = {
  ReminderKind.hourBefore: 60,
  ReminderKind.halfHourBefore: 30,
};

/// Overdue nudge fire hour (local). Reserved for future configurability.
const overdueNudgeHour = 8;

/// Snooze durations for notification action buttons. DB-backed (see
/// `snoozed_until` / `digest_snooze_until`) so the next `syncAll` rebuild
/// — which clears everything — re-emits the snoozed fire instead of wiping
/// it. Single place to tune.
const snoozeTaskDelay = Duration(minutes: 15);
const snoozeDigestDelay = Duration(hours: 3);

/// Foreground action ids. Handled in the main isolate (the tap opens the
/// app), so actions can touch the DB + reschedule directly — no background
/// isolate, no second DB open.
const actionSnooze = 'snooze';
const actionDone = 'done';

/// Explicit notification group (WhatsApp-style): every reminder shares
/// [reminderGroupKey], and a live inbox summary ([reminderGroupSummaryId])
/// heads the stack. Tapping the group header expands the dropdown; each
/// child expands to its action buttons. Without an explicit summary the OS
/// auto-groups anyway (e.g. HyperOS `matrix_todo(2)`), but children of
/// auto-groups hide their actions on several skins.
const reminderGroupKey = 'matrix_group';
const reminderGroupSummaryId = -999999;

/// One computed fire event. Pure data — the plugin call lives in
/// [ReminderService] so this stays unit-testable without platform channels.
typedef ScheduledReminder = ({
  int id,
  ReminderKind kind,
  DateTime fireAt,
  String title,
  String body,
  String? payload,
});

/// Android channel sound names (no extension `res/raw` entries).
String androidSoundFor(ReminderKind kind) =>
    kind == ReminderKind.overdue ? 'overdue_tone' : 'nudge_chime';

/// iOS bundled sound filenames.
String iosSoundFor(ReminderKind kind) => '${androidSoundFor(kind)}.aiff';

/// Notification payload: JSON so taps/actions deep-link to the task and can
/// dismiss exactly what fired. Pre-reminders carry `taskId`; digests carry
/// the `digest` morning ISO day. `nid` is the fired notification id, so the
/// router can dismiss precisely that entry (ongoing notifications are NOT
/// auto-dismissed by the OS). Null/legacy payloads parse to an empty target.
String reminderPayload({int? taskId, String? digest, int? nid}) {
  final map = <String, Object?>{'v': 1};
  if (taskId != null) map['taskId'] = taskId;
  if (digest != null) map['digest'] = digest;
  if (nid != null) map['nid'] = nid;
  return jsonEncode(map);
}

/// Deep-link target decoded from a payload. Pure + unit-tested.
typedef ReminderTarget = ({int? taskId, String? digest, int? nid});

ReminderTarget parseReminderPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return (taskId: null, digest: null, nid: null);
  }
  try {
    final map = jsonDecode(payload);
    if (map is! Map) return (taskId: null, digest: null, nid: null);
    final rawId = map['taskId'];
    final rawDigest = map['digest'];
    final rawNid = map['nid'];
    return (
      taskId: rawId is int ? rawId : null,
      digest: rawDigest is String ? rawDigest : null,
      nid: rawNid is int ? rawNid : null,
    );
  } catch (_) {
    return (taskId: null, digest: null, nid: null);
  }
}

/// A tap or action-button press: target + optional [actionSnooze]/[actionDone].
typedef ReminderRoute = ({
  int? taskId,
  String? digest,
  String? actionId,
  int? nid,
});

ReminderRoute routeFromResponse(NotificationResponse response) {
  final target = parseReminderPayload(response.payload);
  return (
    taskId: target.taskId,
    digest: target.digest,
    actionId: response.actionId,
    nid: target.nid,
  );
}

/// Computes the pre-reminder fire events for [task] after [now].
/// Done tasks and rows without an id schedule nothing. A live snooze
/// (`snoozed_until` in the future) suppresses the regular fires and emits
/// the single deferred fire instead. Overdue nudges are not per-task — see
/// [digestMornings]/[overdueDigest] for the single per-morning digest.
List<ScheduledReminder> remindersFor(TodoTask task, DateTime now) {
  if (task.id == null || task.done) return [];
  final snoozeMs = task.snoozedUntil;
  if (snoozeMs != null && snoozeMs > now.millisecondsSinceEpoch) {
    final fire = DateTime.fromMillisecondsSinceEpoch(snoozeMs);
    final when = (task.dueTime ?? '').isEmpty
        ? ''
        : ' // ${task.dueTime!.toUpperCase()}';
    final snoozeId = notificationId(task.id!, ReminderKind.halfHourBefore);
    return [
      (
        id: snoozeId,
        kind: ReminderKind.halfHourBefore,
        fireAt: fire,
        title: task.title,
        body: 'SNOOZED$when',
        payload: reminderPayload(taskId: task.id, nid: snoozeId),
      ),
    ];
  }
  final out = <ScheduledReminder>[];
  final day = tryParseDueDate(task.dueDate);
  if (day == null) return out;
  final parsed = parseEventTime(task.dueTime);
  if (parsed == null) return out;
  final eventAt = DateTime(
    day.year,
    day.month,
    day.day,
    parsed.hour,
    parsed.minute,
  );
  for (final kind in [ReminderKind.hourBefore, ReminderKind.halfHourBefore]) {
    final fire = eventAt.subtract(Duration(minutes: reminderOffsets[kind]!));
    if (!fire.isAfter(now)) continue;
    final label = kind == ReminderKind.hourBefore ? '1 HOUR' : '30 MINUTES';
    final when = task.dueTime!.toUpperCase();
    final id = notificationId(task.id!, kind);
    out.add((
      id: id,
      kind: kind,
      fireAt: fire,
      title: task.title,
      body: 'DUE IN $label // $when',
      payload: reminderPayload(taskId: task.id, nid: id),
    ));
  }
  // On-time alarm: fires exactly at the event start.
  if (eventAt.isAfter(now)) {
    final id = notificationId(task.id!, ReminderKind.atStart);
    out.add((
      id: id,
      kind: ReminderKind.atStart,
      fireAt: eventAt,
      title: task.title,
      body: 'STARTING NOW // ${task.dueTime!.toUpperCase()}',
      payload: reminderPayload(taskId: task.id, nid: id),
    ));
  }
  return out;
}

/// Negative ids can never collide with `taskId * 10 + kind`.
int digestId(DateTime morning) =>
    -(morning.year * 10000 + morning.month * 100 + morning.day);

/// Distinct 08:00 mornings that need an overdue digest: one per morning on
/// which at least one undone task is overdue. A task's overdue morning is
/// the day after its due date, clamped to tomorrow or later.
List<DateTime> digestMornings(List<TodoTask> tasks, DateTime now) {
  final tomorrow = dayOf(now).add(const Duration(days: 1));
  final mornings = <DateTime>{};
  for (final task in tasks) {
    if (task.done) continue;
    final day = tryParseDueDate(task.dueDate);
    if (day == null) continue;
    var morning = dayOf(day).add(const Duration(days: 1));
    if (morning.isBefore(tomorrow)) morning = tomorrow;
    mornings.add(
      DateTime(morning.year, morning.month, morning.day, overdueNudgeHour),
    );
  }
  return mornings.toList()..sort();
}

/// Single digest for [morning]: every task undone and overdue as of then.
/// Null when nothing qualifies. Titles are a snapshot — a task finished
/// between scheduling and 08:00 may still be listed.
ScheduledReminder? overdueDigest(DateTime morning, List<TodoTask> tasks) {
  final due =
      tasks.where((t) {
        if (t.done) return false;
        final day = tryParseDueDate(t.dueDate);
        return day != null && dayOf(day).isBefore(dayOf(morning));
      }).toList()..sort((a, b) {
        final c = a.dueDate.compareTo(b.dueDate);
        return c != 0 ? c : a.title.compareTo(b.title);
      });
  if (due.isEmpty) return null;
  final titles = due.take(3).map((t) => t.title).join(' • ');
  final more = due.length > 3 ? ' +${due.length - 3} MORE' : '';
  final id = digestId(morning);
  return (
    id: id,
    kind: ReminderKind.overdue,
    fireAt: morning,
    title: '${due.length} OVERDUE // OPEN TO REVIEW',
    body: '$titles$more',
    payload: reminderPayload(digest: isoDay(morning), nid: id),
  );
}

/// Shifts [digest] to [snoozeUntilMs] when the digest fire is at or before
/// the snooze deadline; otherwise returns it unchanged. Pure + unit-tested.
ScheduledReminder applyDigestSnooze(
  ScheduledReminder digest,
  int? snoozeUntilMs,
) {
  if (snoozeUntilMs == null) return digest;
  if (digest.fireAt.millisecondsSinceEpoch > snoozeUntilMs) return digest;
  return (
    id: digest.id,
    kind: digest.kind,
    fireAt: DateTime.fromMillisecondsSinceEpoch(snoozeUntilMs),
    title: digest.title,
    body: digest.body,
    payload: digest.payload,
  );
}

/// Inbox lines for the group summary: one per task with live fires plus
/// digest titles, capped for the shade. Pure + unit-tested.
List<String> groupSummaryLines(List<TodoTask> tasks, DateTime now) {
  final lines = <String>[];
  for (final task in tasks) {
    if (remindersFor(task, now).isEmpty) continue;
    final when = (task.dueTime ?? '').isEmpty
        ? ''
        : ' // ${task.dueTime!.toUpperCase()}';
    lines.add('${task.title}$when');
  }
  for (final morning in digestMornings(tasks, now)) {
    final digest = overdueDigest(morning, tasks);
    if (digest != null) lines.add(digest.title);
  }
  return lines.take(7).toList();
}

/// Every notification id the schedule wants alive right now: pre-reminder
/// slots plus digest mornings (post-snooze-shift — shifts never change ids),
/// plus the daily toggles when armed ([briefing] always fires; [streak]
/// only when tasks remain today), plus the group summary when anything
/// is scheduled.
/// Pure + unit-tested; drives the stale-sweep in [ReminderService.syncAll].
Set<int> desiredIdsFor(
  List<TodoTask> tasks,
  DateTime now,
  int? digestSnoozeMs, {
  bool briefing = false,
  bool streak = false,
}) {
  final ids = <int>{};
  for (final task in tasks) {
    for (final r in remindersFor(task, now)) {
      ids.add(r.id);
    }
  }
  for (final morning in digestMornings(tasks, now)) {
    final digest = overdueDigest(morning, tasks);
    if (digest != null) ids.add(applyDigestSnooze(digest, digestSnoozeMs).id);
  }
  if (briefing) ids.add(briefingNotificationId);
  if (streak && remainingToday(tasks, now) > 0) {
    ids.add(streakNotificationId);
  }
  if (ids.isNotEmpty) ids.add(reminderGroupSummaryId);
  return ids;
}

/// Fixed ids for the daily toggles (WS11). Negative like digests, far from
/// `digestId` (-yyyymmdd ≈ -20M) and the group summary (-999999).
const briefingNotificationId = -900001;
const streakNotificationId = -900002;

/// Fire hour for the daily toggles: briefing 08:00, streak nudge 20:00.
const briefingHour = 8;
const streakHour = 20;

/// Undone tasks due today or overdue as of [now] — the briefing body and
/// the streak-remainder gate. Pure + unit-testable.
int remainingToday(List<TodoTask> tasks, DateTime now) {
  final today = dayOf(now);
  var n = 0;
  for (final t in tasks) {
    if (t.done) continue;
    final day = tryParseDueDate(t.dueDate);
    if (day == null) continue;
    if (!dayOf(day).isAfter(today)) n++;
  }
  return n;
}

/// Next 08:00 briefing fire after [now] (today when still ahead, else
/// tomorrow). Pure + unit-testable.
DateTime nextBriefingFire(DateTime now) {
  final eight = DateTime(now.year, now.month, now.day, briefingHour);
  return now.isBefore(eight)
      ? eight
      : eight.add(const Duration(days: 1));
}

/// Next 20:00 streak fire after [now]. Pure + unit-testable.
DateTime nextStreakFire(DateTime now) {
  final eight = DateTime(now.year, now.month, now.day, streakHour);
  return now.isBefore(eight)
      ? eight
      : eight.add(const Duration(days: 1));
}

/// Task id to scroll-to + highlight in Upcoming after a notification tap.
/// Set by the response router, consumed once by the timeline rows.
class FocusedTaskId extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) => state = id;
  void clear() => state = null;
}

final focusedTaskIdProvider = NotifierProvider<FocusedTaskId, int?>(
  FocusedTaskId.new,
);

/// Action buttons per reminder kind. Pre-reminders map 1:1 to a task, so
/// they get MARK DONE + SNOOZE. Digests cover N tasks (no single task to
/// complete), so SNOOZE-only; the body tap opens Upcoming for review.
List<AndroidNotificationAction> androidReminderActions(ReminderKind kind) => [
  // Icons are required, not decoration: HyperOS/MIUI and several other
  // OEM skins skip icon-less actions even in the expanded shade.
  const AndroidNotificationAction(
    actionSnooze,
    'SNOOZE',
    icon: DrawableResourceAndroidBitmap('ic_snooze'),
    showsUserInterface: true,
    cancelNotification: true,
  ),
  if (kind != ReminderKind.overdue)
    const AndroidNotificationAction(
      actionDone,
      'MARK DONE',
      icon: DrawableResourceAndroidBitmap('ic_done'),
      showsUserInterface: true,
      cancelNotification: true,
    ),
];

/// iOS/macOS foreground categories mirroring [androidReminderActions].
List<DarwinNotificationCategory> darwinReminderCategories() => [
  DarwinNotificationCategory(
    'task_reminder',
    actions: [
      DarwinNotificationAction.plain(
        actionSnooze,
        'SNOOZE',
        options: {DarwinNotificationActionOption.foreground},
      ),
      DarwinNotificationAction.plain(
        actionDone,
        'MARK DONE',
        options: {DarwinNotificationActionOption.foreground},
      ),
    ],
  ),
  DarwinNotificationCategory(
    'digest',
    actions: [
      DarwinNotificationAction.plain(
        actionSnooze,
        'SNOOZE',
        options: {DarwinNotificationActionOption.foreground},
      ),
    ],
  ),
];

/// Reminder policy: computes what/when from tasks, delegates delivery to
/// [NotificationService]. All scheduling funnels through [syncTask]
/// (cancel-then-schedule, idempotent) so edits, pauses and reopens simply
/// re-sync. Fired notifications are delivered by the OS even when the app
/// is closed or killed.
class ReminderService {
  ReminderService({NotificationService? notifications})
    : _notifications = notifications ?? NotificationService();

  final NotificationService _notifications;
  bool _ready = false;
  ReminderRoute? _launchRoute;

  /// Hook for the persisted digest snooze (`digest_snooze_until` epoch
  /// millis). Wired in `main()`; null disables digest snoozing (tests).
  Future<int?> Function()? digestSnoozeReader;

  /// Transport init + tap/action routing. Idempotent. Permission-free.
  Future<void> init({
    required Future<void> Function(ReminderRoute) onRoute,
  }) async {
    if (_ready) return;
    await _notifications.init(
      onResponse: (response) => onRoute(routeFromResponse(response)),
      darwinCategories: darwinReminderCategories(),
    );
    final launch = await _notifications.getLaunchResponse();
    if (launch != null) {
      _launchRoute = routeFromResponse(launch);
    }
    _ready = true;
  }

  /// Consumes the cold-start route (single-shot for AppShell routing).
  ReminderRoute? consumeLaunchRoute() {
    final value = _launchRoute;
    _launchRoute = null;
    return value;
  }

  /// Silent probe for startup / first-task flows. Never prompts.
  Future<bool> areNotificationsEnabled() =>
      _notifications.areNotificationsEnabled();

  /// Runtime prompts (Android 13+ notifications, iOS alert set) plus the
  /// exact-alarm capability probe. Denials degrade to inexact timing;
  /// never throws. Call only from user interaction (settings toggle, test
  /// button, first-task rationale) — never at launch.
  Future<void> ensureReady() async {
    await _notifications.requestNotificationsPermission();
    await _notifications.ensureExactAlarms();
    await _notifications.requestIosPermissions();
  }

  /// Rebuilds one task's schedule from scratch. No-op without an id.
  Future<void> syncTask(TodoTask task, {required bool enabled}) async {
    if (task.id == null) return;
    await cancelTask(task.id!);
    if (!enabled) return;
    for (final r in remindersFor(task, DateTime.now())) {
      await _schedule(r);
    }
  }

  /// Cancels every slot that could belong to [taskId]. The overdue slot is
  /// never scheduled per-task today, but the loop also clears legacy
  /// per-task overdue alarms from older installs.
  Future<void> cancelTask(int taskId) async {
    for (final kind in ReminderKind.values) {
      await _notifications.cancel(notificationId(taskId, kind));
    }
  }

  Future<void> cancelAll() => _notifications.cancelAll();

  /// Dismisses exactly one displayed entry by id. Ongoing notifications are
  /// never auto-dismissed by the OS, so every tap/action route calls this
  /// with the payload `nid`. Never touches pending sibling schedules.
  Future<void> dismiss(int id) => _notifications.cancel(id);

  /// Hook for the persisted daily toggles (WS11). Wired in `main()`;
  /// null disables daily scheduling (tests). Read on every [syncAll] so
  /// mutations refresh the briefing/streak fires and toggle-off is honored.
  Future<({bool briefing, bool streak})> Function()? dailyPolicyReader;

  /// Full rebuild from the DB: per-task cancel-then-schedule plus one
  /// overdue digest per morning (shifted by a live digest snooze), the
  /// daily briefing/streak fires per [dailyPolicyReader], then a
  /// stale-sweep that cancels pending ids nobody wants any more (deleted /
  /// completed tasks, shifted mornings, disarmed dailies).
  ///
  /// Deliberately NOT a global `cancelAll` (except when the master switch
  /// is off): displayed ongoing reminders stay in the shade across resyncs
  /// and dismiss only via tap/actions. `healOnly` (cold start) skips the
  /// rebuild entirely when pending ids already match the desired set, so
  /// merely opening the app never wipes a waiting reminder; reboot-cleared
  /// or drifted schedules still heal because the sets differ.
  Future<void> syncAll(
    List<TodoTask> tasks, {
    required bool enabled,
    bool healOnly = false,
  }) async {
    if (!enabled) {
      await cancelAll();
      return;
    }
    final now = DateTime.now();
    final digestSnooze = await digestSnoozeReader?.call();
    final policy = await dailyPolicyReader?.call() ??
        (briefing: false, streak: false);
    Set<int> wanted() => desiredIdsFor(
          tasks,
          now,
          digestSnooze,
          briefing: policy.briefing,
          streak: policy.streak,
        )..remove(reminderGroupSummaryId);
    if (healOnly) {
      final pending = await _notifications.pendingIds();
      // The summary is shown immediately (displayed, never pending), so it
      // is excluded from the intact-check; children must match exactly.
      final want = wanted();
      final live = pending.where((id) => id != 999998 && id != 999999).toSet();
      if (live.length == want.length && live.containsAll(want)) {
        debugPrint(
          '[ReminderService] syncAll heal-only: schedules intact, skip',
        );
        return;
      }
    }
    for (final task in tasks) {
      await syncTask(task, enabled: true);
    }
    for (final morning in digestMornings(tasks, now)) {
      final digest = overdueDigest(morning, tasks);
      if (digest != null) {
        await _schedule(applyDigestSnooze(digest, digestSnooze));
      }
    }
    await _syncDaily(tasks, now, policy);
    final desired = wanted()..add(reminderGroupSummaryId);
    final pending = await _notifications.pendingIds();
    for (final id in pending) {
      if (id == 999998 || id == 999999) continue;
      if (!desired.contains(id)) await _notifications.cancel(id);
    }
    // Group summary last: shows live inbox lines when anything is
    // scheduled, disappears when the schedule is empty.
    await _syncGroupSummary(tasks, now);
    if (kDebugMode) {
      final after = await _notifications.pendingIds();
      debugPrint('[ReminderService] syncAll done: ${after.length} pending');
    }
  }

  /// Daily toggles (WS11): cancel-then-schedule the 08:00 briefing and the
  /// 20:00 streak nudge per policy. The briefing lists today's remaining
  /// rows; the streak nudge fires only when tasks remain. Informational:
  /// tap opens Upcoming, no action buttons (so SNOOZE/DONE never pollute
  /// task or digest state).
  Future<void> _syncDaily(
    List<TodoTask> tasks,
    DateTime now,
    ({bool briefing, bool streak}) policy,
  ) async {
    final remaining = remainingToday(tasks, now);
    if (!policy.briefing) {
      await _notifications.cancel(briefingNotificationId);
    } else {
      await _notifications.cancel(briefingNotificationId);
      final due = tasks.where((t) {
        if (t.done) return false;
        final day = tryParseDueDate(t.dueDate);
        return day != null && !dayOf(day).isAfter(dayOf(now));
      }).toList();
      final titles = due.take(3).map((t) => t.title).join(' • ');
      final more = due.length > 3 ? ' +${due.length - 3} MORE' : '';
      final fire = nextBriefingFire(now);
      await _scheduleDaily(
        id: briefingNotificationId,
        fireAt: fire,
        title: 'MORNING BRIEFING // $remaining TODAY',
        body: due.isEmpty ? 'DAY CLEAR // NOTHING DUE' : '$titles$more',
        digest: isoDay(fire),
      );
    }
    if (!policy.streak || remaining == 0) {
      await _notifications.cancel(streakNotificationId);
    } else {
      await _notifications.cancel(streakNotificationId);
      final fire = nextStreakFire(now);
      await _scheduleDaily(
        id: streakNotificationId,
        fireAt: fire,
        title: 'STREAK CHECK // $remaining REMAIN',
        body:
            'CLOSE THE DAY // $remaining TASK${remaining == 1 ? '' : 'S'} REMAIN',
        digest: isoDay(fire),
      );
    }
  }

  /// One informational fire: reminders channel + nudge chime, tap-only.
  Future<void> _scheduleDaily({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String digest,
  }) async {
    if (fireAt.millisecondsSinceEpoch <= DateTime.now().millisecondsSinceEpoch) {
      return;
    }
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        fireAt: fireAt,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationService.remindersChannelId,
            'REMINDERS',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('nudge_chime'),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            groupKey: reminderGroupKey,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'REMINDERS',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'nudge_chime.aiff',
            threadIdentifier: reminderGroupKey,
          ),
        ),
        payload: reminderPayload(digest: digest, nid: id),
      );
    } catch (e) {
      debugPrint('[ReminderService] _scheduleDaily error: $e');
    }
  }

  /// Posts (or refreshes) the WhatsApp-style group summary, or cancels it
  /// when nothing is scheduled. Silent + alert-once: children carry the
  /// chime, never the header.
  Future<void> _syncGroupSummary(List<TodoTask> tasks, DateTime now) async {
    final lines = groupSummaryLines(tasks, now);
    if (lines.isEmpty) {
      await _notifications.cancel(reminderGroupSummaryId);
      return;
    }
    try {
      await _notifications.show(
        id: reminderGroupSummaryId,
        title: 'MATRIX // REMINDERS',
        body: lines.first,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationService.remindersChannelId,
            'REMINDERS',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
            silent: true,
            onlyAlertOnce: true,
            groupKey: reminderGroupKey,
            setAsGroupSummary: true,
            groupAlertBehavior: GroupAlertBehavior.children,
            styleInformation: InboxStyleInformation(
              lines,
              contentTitle: 'MATRIX // REMINDERS',
              summaryText: '${lines.length} REMINDERS',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
            threadIdentifier: reminderGroupKey,
          ),
        ),
        payload: reminderPayload(),
      );
    } catch (e) {
      debugPrint('[ReminderService] group summary error: $e');
    }
  }

  /// Snooze button on a pre-reminder: defer this task's fires by
  /// [snoozeTaskDelay]. Persists so the next `syncAll` re-emits it.
  Future<void> snoozeTask(AppDatabase db, int taskId) async {
    await db.setTaskSnooze(
      taskId,
      DateTime.now().add(snoozeTaskDelay).millisecondsSinceEpoch,
    );
  }

  /// Snooze button on a morning digest: shift digest fires by
  /// [snoozeDigestDelay]. Persists in settings for the same reason.
  Future<void> snoozeDigest(AppDatabase db) async {
    await db.setSetting(
      'digest_snooze_until',
      DateTime.now().add(snoozeDigestDelay).millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> _schedule(ScheduledReminder r) async {
    final overdue = r.kind == ReminderKind.overdue;
    // Drop fire times that already passed between computation and now —
    // the plugin would otherwise fire immediately or drop them silently.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (r.fireAt.millisecondsSinceEpoch <= nowMs) {
      debugPrint(
        '[ReminderService] skip id ${r.id}: fireAt ${r.fireAt.toLocal()} '
        'is in the past (now ${DateTime.now()})',
      );
      return;
    }
    try {
      debugPrint(
        '[ReminderService] scheduling id ${r.id} fire=${r.fireAt.toLocal()} '
        'epoch=${r.fireAt.millisecondsSinceEpoch} '
        'exact=${_notifications.exactAlarms} '
        'actions=${androidReminderActions(r.kind).map((a) => '${a.id}:${a.icon != null}').toList()}',
      );
      await _notifications.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        fireAt: r.fireAt,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            overdue
                ? NotificationService.overdueChannelId
                : NotificationService.remindersChannelId,
            overdue ? 'OVERDUE' : 'REMINDERS',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(androidSoundFor(r.kind)),
            // Alarm audio focus so the chime behaves like an alarm.
            audioAttributesUsage: AudioAttributesUsage.alarm,
            actions: androidReminderActions(r.kind),
            // Pinned (Hotspot-style): HyperOS/MIUI render ongoing
            // notifications expanded with their action buttons, while
            // swipeable rows hide them until long-pressed. Dismissal is
            // explicit — every tap/action route calls [dismiss] with the
            // payload nid, because the OS never auto-dismisses ongoing
            // entries (same reason deleteTask cancels explicitly).
            ongoing: true,
            // Shared group: the inbox summary heads the stack and the
            // header expands into per-task children with their buttons.
            groupKey: reminderGroupKey,
            // Public visibility: lock-screen entries on HyperOS/AOSP hide
            // action buttons when content is redacted; our bodies carry no
            // sensitive data, so declare them public.
            visibility: NotificationVisibility.public,
            // Expanded style: guarantees the full body + action buttons are
            // reachable on every OEM skin. Collapsed shade rows on some
            // skins (Xiaomi/HyperOS, HiOS/XOS, One UI modes) hide actions
            // until the notification is expanded via its chevron — Android
            // offers no API to force expansion, so a rich expanded view is
            // the best we can do.
            styleInformation: BigTextStyleInformation(
              r.body,
              contentTitle: r.title,
              summaryText: overdue ? 'OVERDUE' : 'REMINDERS',
            ),
          ),
          iOS: DarwinNotificationDetails(
            sound: iosSoundFor(r.kind),
            categoryIdentifier: overdue ? 'digest' : 'task_reminder',
            threadIdentifier: reminderGroupKey,
          ),
          macOS: DarwinNotificationDetails(
            sound: iosSoundFor(r.kind),
            categoryIdentifier: overdue ? 'digest' : 'task_reminder',
            threadIdentifier: reminderGroupKey,
          ),
        ),
        payload: r.payload,
      );
    } catch (e) {
      debugPrint('[ReminderService] _schedule error: $e');
    }
  }

  /// Schedules a simple test notification `delay` from now. Uses a
  /// deterministic high id (to avoid colliding with task ids) and the
  /// nudge chime sound so it's audible. Intended for manual QA.
  /// Test ids are excluded from the stale-sweep, so mutations leave them
  /// alone; only master-off / data-purge clears them.
  Future<void> scheduleTestNotification([
    Duration delay = const Duration(minutes: 2),
  ]) async {
    final fire = DateTime.now().add(delay);
    final test = (
      id: 999999,
      kind: ReminderKind.halfHourBefore,
      fireAt: fire,
      title: 'TEST REMINDER',
      body: 'This is a test scheduled ${fire.toLocal()}',
      payload: reminderPayload(nid: 999999),
    );
    try {
      // Ensure initialization and permissions before scheduling.
      if (!_ready) {
        debugPrint(
          '[ReminderService] not ready, initializing before test schedule',
        );
        await init(onRoute: (_) async {});
      }
      await ensureReady();
      debugPrint(
        '[ReminderService] scheduling test notification for $fire '
        '(local=${fire.toLocal()} epoch=${fire.millisecondsSinceEpoch} '
        'exact=${_notifications.exactAlarms})',
      );
      // Fire an immediate notification to verify channel/sound/display.
      try {
        debugPrint('[ReminderService] showing immediate test notification');
        await _notifications.show(
          id: 999998,
          title: 'TEST NOW',
          body: 'Immediate test notification',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              NotificationService.remindersChannelId,
              'REMINDERS',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('nudge_chime'),
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          ),
        );
      } catch (e) {
        debugPrint('[ReminderService] immediate show failed: $e');
      }

      await _schedule(test);
      final ids = await _notifications.pendingIds();
      debugPrint(
        '[ReminderService] pending after schedule: $ids '
        '(expect 999999; if missing, zonedSchedule dropped it — check exact-alarm permission)',
      );
    } catch (e, st) {
      debugPrint('[ReminderService] failed to schedule test: $e');
      debugPrint(st.toString());
    }
  }
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) =>
      ReminderService(notifications: ref.watch(notificationServiceProvider)),
);
