import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../stats/stats_page.dart';
import 'appearance_page.dart';
import 'data_page.dart';
import 'notifications_page.dart';
import 'settings_sections/profile_hero.dart';

/// Settings hub — profile, four section entries, version.
/// Detail lives in the sub-screens so this page stays scannable.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final version = const String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '0.0.2',
    );

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        leading: const Icon(Icons.tune, size: 18),
        height: isLandscape ? 72 : null,
      ),
      body: ListView(
        children: [
          const ProfileHero(),
          _HubCell(
            index: '01',
            title: 'Appearance',
            hint: 'Theme, home screen, week start',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AppearancePage())),
          ),
          _HubCell(
            index: '02',
            title: 'Notifications',
            hint: 'Daily updates & reminders',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
          _HubCell(
            index: '03',
            title: 'Data & backup',
            hint: 'Save, restore, reset',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DataPage())),
          ),
          _HubCell(
            index: '04',
            title: 'Progress',
            hint: 'Streak, today, week, lists',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StatsPage())),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: scheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Version $version',
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
}

class _HubCell extends StatelessWidget {
  final String index;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _HubCell({
    required this.index,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Text(
              index,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_right, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
