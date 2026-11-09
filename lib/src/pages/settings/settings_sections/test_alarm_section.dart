import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/notification_service.dart';
import '../../../notifications/reminder_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/button.dart';
import '../../../widgets/result_dialog.dart';

/// Interactive button to schedule a 2-minute test alarm.
/// Verifies notification permissions, exact-alarm capability, and OS AlarmManager delivery.
class TestAlarmSection extends ConsumerStatefulWidget {
  final bool isCard;

  const TestAlarmSection({super.key, this.isCard = true});

  @override
  ConsumerState<TestAlarmSection> createState() => _TestAlarmSectionState();
}

class _TestAlarmSectionState extends ConsumerState<TestAlarmSection> {
  bool _scheduling = false;
  bool _testingSound = false;

  Future<void> _testSound() async {
    setState(() => _testingSound = true);
    try {
      final service = ref.read(reminderServiceProvider);
      await service.testAlarmSoundNow();
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => ResultDialog(
          title: 'Sound check failed',
          message: '$e',
          isError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _testingSound = false);
    }
  }

  Future<void> _scheduleTestAlarm() async {
    setState(() => _scheduling = true);
    try {
      final service = ref.read(reminderServiceProvider);
      await service.ensureReady();
      final enabled = await service.areNotificationsEnabled();
      if (!mounted) return;
      if (!enabled) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('NOTIFICATIONS DISABLED'),
            content: const Text(
              'Notifications are turned off in system settings for Matrix Todo. Please enable notifications so alarms can ring.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  SystemBridge.openAppNotificationSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        );
        return;
      }
      final fireAt = await service.scheduleTestAlarm(
        delay: const Duration(minutes: 2),
      );
      if (!mounted) return;
      final timeStr =
          '${fireAt.hour.toString().padLeft(2, '0')}:${fireAt.minute.toString().padLeft(2, '0')}:${fireAt.second.toString().padLeft(2, '0')}';
      await showDialog(
        context: context,
        builder: (_) => ResultDialog(
          title: 'Alarm scheduled',
          message:
              'Test alarm set for $timeStr (in 2 minutes).\n\nConfigured on the dedicated ALARM audio stream with full volume chime and vibration.\n\nYou can lock your screen or close the app now to verify that the alarm wakes the device and sounds.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = '$e';
      if (msg.contains('EXACT_ALARM_DENIED')) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('EXACT ALARMS REQUIRED'),
            content: const Text(
              'Android requires "Alarms & Reminders" permission for alarms to fire at exact times without being delayed by battery optimization.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(notificationServiceProvider).requestExactAlarmsPermission();
                },
                child: const Text('GRANT PERMISSION'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (_) => ResultDialog(
            title: 'Scheduling failed',
            message: msg,
            isError: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.alarm, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Alarm test',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Verify system alarm audio and delivery on the dedicated Alarm stream.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Button(
                label: _scheduling ? 'Scheduling...' : 'Schedule test alarm (2 min)',
                leading: const Icon(Icons.timer_outlined, size: 18),
                onPressed: _scheduling ? null : _scheduleTestAlarm,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Button(
                label: _testingSound ? 'Playing...' : 'Test sound',
                kind: ButtonKind.secondary,
                leading: const Icon(Icons.volume_up_outlined, size: 18),
                onPressed: _testingSound ? null : _testSound,
              ),
            ),
          ],
        ),
      ],
    );

    if (!widget.isCard) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }
}
