import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../settings_providers.dart';
import '../sheets/name_edit_sheet.dart';

/// `00/ PROFILE` hero: name row only (no avatar, no tier tag) + static
/// email line + `EDIT PROFILE ->` opening the name sheet.
class ProfileHero extends ConsumerWidget {
  const ProfileHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(profileNameProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '00/ PROFILE',
            style: AppTypography.indexIndicator(
              context,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LOCAL OPERATOR • ON-DEVICE VAULT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Button(
            label: 'Edit profile',
            leading: const Icon(Icons.arrow_forward, size: 18),
            expanded: false,
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const NameEditSheet(),
            ),
          ),
        ],
      ),
    );
  }
}
