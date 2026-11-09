import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/recurrence.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_borders.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/button.dart';
import '../home/home_providers.dart';
import '../settings/settings_providers.dart';
import '../upcoming/upcoming_providers.dart';
import 'alarm_providers.dart';

/// Full-screen high-priority alarm page displayed over the lockscreen and app
/// when an exact task alarm or test alarm fires.
///
/// Dismissable by swiping up, snoozeable (+10 min), or markable done.
/// All exit actions return the user to their previous screen / lockscreen
/// via [SystemBridge.minimize] without dropping into the app shell.
class AlarmRingingPage extends ConsumerStatefulWidget {
  final RingingAlarmInfo alarm;

  const AlarmRingingPage({super.key, required this.alarm});

  @override
  ConsumerState<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends ConsumerState<AlarmRingingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late DateTime _currentTime;
  Timer? _clockTimer;
  double _dragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    SystemBridge.setShowWhenLocked(true);
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemBridge.setShowWhenLocked(false);
    _clockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0.0;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    // Upward swipe has negative velocity (< -250) or upward distance (< -60px)
    if (velocity < -250 || _dragDistance < -60) {
      _dismiss();
    }
    _dragDistance = 0.0;
  }

  Future<void> _dismiss() async {
    final reminders = ref.read(reminderServiceProvider);
    await reminders.dismiss(widget.alarm.nid);
    if (widget.alarm.isTest) {
      await reminders.cancelTestAlarm();
    }
    ref.read(ringingAlarmProvider.notifier).dismiss();
    await SystemBridge.setShowWhenLocked(false);
    await SystemBridge.minimize();
  }

  Future<void> _snooze() async {
    final reminders = ref.read(reminderServiceProvider);
    final db = ref.read(appDatabaseProvider);
    await reminders.dismiss(widget.alarm.nid);
    if (widget.alarm.taskId != null) {
      await reminders.snoozeTask(db, widget.alarm.taskId!);
      ref.invalidate(tasksProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(upcomingGroupsProvider);
      await reminders.syncAll(
        await db.getTasks(),
        enabled: ref.read(remindersEnabledProvider),
      );
    } else if (widget.alarm.isTest) {
      await reminders.scheduleTestAlarm(delay: snoozeTaskDelay);
    }
    ref.read(ringingAlarmProvider.notifier).dismiss();
    await SystemBridge.setShowWhenLocked(false);
    await SystemBridge.minimize();
  }

  Future<void> _markDone() async {
    final reminders = ref.read(reminderServiceProvider);
    final db = ref.read(appDatabaseProvider);
    await reminders.dismiss(widget.alarm.nid);
    if (widget.alarm.taskId != null) {
      final task = await db.getTask(widget.alarm.taskId!);
      if (task != null) {
        await completeTaskWithRecurrence(db, task);
      } else {
        await db.setTaskDone(widget.alarm.taskId!, true);
        await db.setTaskSnooze(widget.alarm.taskId!, null);
      }
      ref.invalidate(tasksProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(upcomingGroupsProvider);
      await reminders.syncAll(
        await db.getTasks(),
        enabled: ref.read(remindersEnabledProvider),
      );
    } else if (widget.alarm.isTest) {
      await reminders.cancelTestAlarm();
    }
    ref.read(ringingAlarmProvider.notifier).dismiss();
    await SystemBridge.setShowWhenLocked(false);
    await SystemBridge.minimize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final alarm = widget.alarm;

    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minStr = _currentTime.minute.toString().padLeft(2, '0');
    final secStr = _currentTime.second.toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _dismiss();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Scaffold(
          backgroundColor: scheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top status bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '[ MATRIX // ALARM ACTIVATED ]',
                        style: TextStyle(
                          fontFamily: AppTypography.monoFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      FadeTransition(
                        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: AppBorders.zero,
                          ),
                          child: Text(
                            'RINGING',
                            style: TextStyle(
                              fontFamily: AppTypography.monoFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Pulsing Alarm Icon & Time
                  Center(
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.08).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.primary, width: 2),
                              borderRadius: AppBorders.zero,
                            ),
                            child: Icon(
                              Icons.alarm_on,
                              size: 44,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '$hourStr:$minStr:$secStr',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFamily,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: scheme.primary,
                          ),
                        ),
                        Text(
                          alarm.isTest ? 'TEST ALARM' : 'EXACT TASK ALARM',
                          style: TextStyle(
                            fontFamily: AppTypography.monoFamily,
                            fontSize: 13,
                            letterSpacing: 1.5,
                            color: scheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Task details card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        border: Border.all(color: scheme.primary, width: 1),
                        borderRadius: AppBorders.zero,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (alarm.category != null &&
                                alarm.category!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                  ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: scheme.secondary,
                                    width: 1,
                                  ),
                                  borderRadius: AppBorders.zero,
                                ),
                                child: Text(
                                  alarm.category!.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTypography.monoFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            Text(
                              alarm.title,
                              style: (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 26,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (alarm.body.isNotEmpty &&
                                alarm.body != alarm.title) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                alarm.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                            if (alarm.notes.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'NOTES: ${alarm.notes}',
                                style: TextStyle(
                                  fontFamily: AppTypography.monoFamily,
                                  fontSize: 12,
                                  color: scheme.secondary,
                                ),
                              ),
                            ],
                            if (alarm.isTest) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Test alarm audio is actively playing on the dedicated alarm track. Swipe up to dismiss or tap Snooze (+10 min).',
                                style: TextStyle(
                                  fontFamily: AppTypography.monoFamily,
                                  fontSize: 12,
                                  color: scheme.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Swipe Up to Dismiss Affordance
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: const Offset(0, -0.2),
                            ).animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: Icon(
                              Icons.keyboard_double_arrow_up,
                              size: 26,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SWIPE UP TO DISMISS',
                            style: TextStyle(
                              fontFamily: AppTypography.monoFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Controls: SNOOZE (+10 MIN) & MARK DONE
                  Button(
                    label: 'SNOOZE (+10 MIN)',
                    kind: ButtonKind.primary,
                    onPressed: _snooze,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Button(
                    label: 'MARK DONE',
                    kind: ButtonKind.secondary,
                    onPressed: _markDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
