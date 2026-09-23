import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../notifications/reminder_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/result_dialog.dart';
import '../../widgets/section_header.dart';
import 'settings_providers.dart';
import 'settings_sections/data_section.dart';
import 'settings_sections/notification_rescue.dart';
import 'settings_sections/profile_hero.dart';
import 'settings_sections/segmented_row.dart';
import 'settings_sections/toggle_row.dart';

/// Settings // Preferences — profile name, live app preferences
/// (theme / default view / week start), notification stubs, data vault.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings // Preferences',
        leading: Icon(Icons.tune, size: 18),
      ),
      body: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  'SYSTEM REVISION: 0.0.1 // RUNTIME',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'CORE ENGINE ACTIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const ProfileHero(),
          const SectionHeader(
            title: '01 // App preferences',
            index: '[UI_STATE: SYNCHRONIZED]',
          ),
          SegmentedRow<ThemeSetting>(
            title: 'Theme engine',
            subtitle: 'Structural chromatic runtime settings',
            values: ThemeSetting.values,
            selected: settings.theme,
            label: (v) => v.name,
            onSelect: settingsCtl.setTheme,
          ),
          SegmentedRow<DefaultView>(
            title: 'Default view matrix',
            subtitle: 'Initial canvas destination on launch',
            values: DefaultView.values,
            selected: settings.defaultView,
            label: (v) => v.name,
            onSelect: settingsCtl.setDefaultView,
          ),
          SegmentedRow<WeekStart>(
            title: 'Calendar cadence',
            subtitle: 'Day matrix 0-index initializer',
            values: WeekStart.values,
            selected: settings.weekStart,
            label: (v) => v.name,
            onSelect: settingsCtl.setWeekStart,
          ),
          const SectionHeader(
            title: '02 // Notifications & sync',
            index: '[DISPATCH: ARMED]',
          ),
          ToggleRow(
            title: 'Daily morning briefing',
            subtitle:
                'Audio-visual ingestion of daily index rows — dispatch stub',
            badge: '08:00 AM',
            value: settings.briefing,
            onChanged: settingsCtl.setBriefing,
          ),
          ToggleRow(
            title: 'Streak reminder',
            subtitle:
                'Trigger evening notification if tasks remain — dispatch stub',
            value: settings.streakReminder,
            onChanged: settingsCtl.setStreakReminder,
          ),
          ToggleRow(
            title: 'Task reminders',
            subtitle: '30m + 1h chimes and morning-after overdue tone',
            badge: settings.reminders ? 'ARMED' : 'MUTED',
            value: settings.reminders,
            onChanged: (v) => _toggleReminders(ref, v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final service = ref.read(reminderServiceProvider);
                    try {
                      await service.scheduleTestNotification(
                        const Duration(minutes: 2),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test alarm scheduled in 2 minutes'),
                        ),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to schedule test alarm'),
                        ),
                      );
                    }
                  },
                  child: const Text('Schedule 2-min Test Alarm'),
                ),
              ],
            ),
          ),
          const NotificationRescueSection(),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CLOUD SYNC (LOCAL / SQLITE)',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'STATUS: LOCAL VAULT // NO CLOUD BACKEND',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const ResultDialog(
                        title: 'SYNC QUEUED',
                        message:
                            'LOCAL SQLITE IS THE STORE // NOTHING TO SYNC.\nCLOUD FUNCTIONALITY COMING SOON!',
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'SYNC NOW',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: '03 // Data & backup',
            index: '[LOCAL_VAULT]',
          ),
          const DataSection(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: scheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VERSION 0.0.1-BUILD-2026 // FLUTTER ENGINE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'ARCHITECTURAL BRUTALISM • CONTIGUOUS GRID PARADIGM • ZERO LATENCY SYSTEM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
