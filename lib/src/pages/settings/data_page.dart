import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/section_header.dart';
import 'settings_sections/data_section.dart';

/// Data & Vault sub-screen: local-vault status, export/import/purge.
class DataPage extends ConsumerWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        leading: CustomIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: 'Data & backup',
        index: 'SETTINGS / 03',
      ),
      body: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your data stays on this device',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stored locally. Nothing leaves your phone.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Data & backup',
            index: null,
          ),
          const DataSection(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
