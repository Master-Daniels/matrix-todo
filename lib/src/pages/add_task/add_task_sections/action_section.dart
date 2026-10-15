import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Terminal action bar: full-width rounded primary commit + centered
/// text discard. Custom chrome (not the sharp global [Button]) to match
/// the decluttered deck modal.
class ActionSection extends StatelessWidget {
  final bool saving;
  final VoidCallback onSubmit;
  final String submitLabel;

  const ActionSection({
    super.key,
    required this.saving,
    required this.onSubmit,
    this.submitLabel = 'ADD TASK TO DECK',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: saving ? null : onSubmit,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary,
              border: Border.all(color: scheme.primary, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              saving ? 'SAVING...' : submitLabel.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: saving ? null : () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'DISCARD',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
