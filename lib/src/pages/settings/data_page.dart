import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/result_dialog.dart';
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
        title: 'Data & Vault',
        index: 'SETTINGS // 03',
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LOCAL VAULT // NO CLOUD [STUB]',
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
                        title: 'SYNC QUEUED [STUB]',
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
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
