import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../stats/stats_page.dart';
import 'appearance_page.dart';
import 'data_page.dart';
import 'notifications_page.dart';
import 'settings_sections/profile_hero.dart';

/// Settings // Preferences hub — status strip, profile, four section
/// entries (Appearance / Notifications / Data & Vault / Stats), version.
/// Detail lives in the sub-screens so this ledger stays scannable.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  'SYSTEM REVISION: ${const String.fromEnvironment('APP_VERSION', defaultValue: '0.0.1')} // RUNTIME',
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
          _HubCell(
            index: '01',
            title: 'APPEARANCE',
            hint: 'THEME // DEFAULT VIEW // CADENCE',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            ),
          ),
          _HubCell(
            index: '02',
            title: 'NOTIFICATIONS',
            hint: 'BRIEFING // STREAK // REMINDERS',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
          _HubCell(
            index: '03',
            title: 'DATA & VAULT',
            hint: 'EXPORT // IMPORT // PURGE',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataPage()),
            ),
          ),
          _HubCell(
            index: '04',
            title: 'STATS // LEDGER',
            hint: 'STREAK // TODAY // WEEK // LISTS',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsPage()),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: scheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VERSION ${const String.fromEnvironment('APP_VERSION', defaultValue: '0.0.1')}-BUILD-${const String.fromEnvironment('APP_BUILD', defaultValue: '2026')} // FLUTTER ENGINE',
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
          border: Border(
            bottom: BorderSide(color: scheme.primary, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Text(
              '$index //',
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
