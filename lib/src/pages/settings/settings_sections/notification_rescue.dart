import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/notification_service.dart';
import '../../../notifications/oem_guidance.dart';
import '../../../theme/app_spacing.dart';

/// OEM rescue: some manufacturers (Xiaomi, Huawei, OnePlus, Samsung…)
/// kill background alarms to save battery (see https://dontkillmyapp.com).
/// This section shows vendor-matched steps plus settings shortcuts.
/// Guidance only — the app never auto-requests battery exemptions.
class NotificationRescueSection extends ConsumerStatefulWidget {
  const NotificationRescueSection({super.key});

  @override
  ConsumerState<NotificationRescueSection> createState() =>
      _NotificationRescueSectionState();
}

class _NotificationRescueSectionState
    extends ConsumerState<NotificationRescueSection> {
  OemGuidance _guidance = guidanceFor('');

  @override
  void initState() {
    super.initState();
    SystemBridge.manufacturer().then((maker) {
      if (mounted) setState(() => _guidance = guidanceFor(maker));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NOTIFICATIONS NOT FIRING? // ${_guidance.vendor}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'SOME PHONE MAKERS KILL BACKGROUND ALARMS. FOLLOW THE STEPS FOR YOUR DEVICE:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _guidance.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${i + 1}. ${_guidance.steps[i]}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      SystemBridge.openAppNotificationSettings,
                  child: const Text('NOTIFICATIONS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      SystemBridge.openBatteryOptimizationSettings,
                  child: const Text('BATTERY'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: SystemBridge.openAppDetailsSettings,
                  child: const Text('APP INFO'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
