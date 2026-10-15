import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/section_header.dart';
import 'settings_providers.dart';
import 'settings_sections/segmented_row.dart';

/// Appearance sub-screen: theme engine, default view, calendar cadence.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

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
        title: 'Appearance',
        index: 'SETTINGS // 01',
      ),
      body: ListView(
        children: [
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
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
