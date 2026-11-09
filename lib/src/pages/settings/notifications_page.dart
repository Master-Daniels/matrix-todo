import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/section_header.dart';
import 'settings_providers.dart';
import 'settings_sections/notification_rescue.dart';
import 'settings_sections/test_alarm_section.dart';
import 'settings_sections/toggle_row.dart';

/// Notifications sub-screen: briefing, streak, master reminders,
/// OEM rescue.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
        leading: CustomIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: 'Notifications',
        index: 'SETTINGS / 02',
      ),
      body: ListView(
        children: [
          const SectionHeader(title: 'Dispatch', index: null),
          ToggleRow(
            title: 'Daily morning briefing',
            subtitle: 'Daily summary of each day\'s tasks, sent at 8:00 AM',
            badge: '08:00 AM',
            value: settings.briefing,
            onChanged: (v) =>
                _toggleDaily(ref, () => settingsCtl.setBriefing(v)),
          ),
          ToggleRow(
            title: 'Streak reminder',
            subtitle: 'Evening nudge at 8:00 if tasks remain',
            value: settings.streakReminder,
            onChanged: (v) =>
                _toggleDaily(ref, () => settingsCtl.setStreakReminder(v)),
          ),
          ToggleRow(
            title: 'Task reminders',
            subtitle:
                'Alerts 1 hour before, 30 minutes before, and at the scheduled task time',
            badge: settings.reminders ? 'On' : 'Off',
            value: settings.reminders,
            onChanged: (v) => _toggleReminders(ref, v),
          ),
          const NotificationRescueSection(),
          const SectionHeader(title: 'Diagnostics', index: null),
          const TestAlarmSection(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// Daily toggles: persist, prompt for permissions, then rebuild the whole
  /// schedule — [ReminderService.syncAll] applies the daily policy itself.
  Future<void> _toggleDaily(
    WidgetRef ref,
    Future<void> Function() persist,
  ) async {
    await persist();
    final service = ref.read(reminderServiceProvider);
    try {
      await service.ensureReady();
      await service.syncAll(
        await ref.read(appDatabaseProvider).getTasks(),
        enabled: ref.read(remindersEnabledProvider),
      );
    } catch (_) {}
  }

  /// Master reminders switch: enabling prompts for permissions then rebuilds
  /// the whole schedule; disabling clears every pending notification.
  Future<void> _toggleReminders(WidgetRef ref, bool value) async {
    await ref.read(settingsControllerProvider.notifier).setReminders(value);
    final service = ref.read(reminderServiceProvider);
    try {
      if (value) {
        await service.ensureReady();
        await service.syncAll(
          await ref.read(appDatabaseProvider).getTasks(),
          enabled: true,
        );
      } else {
        await service.cancelAll();
      }
    } catch (_) {}
  }
}
