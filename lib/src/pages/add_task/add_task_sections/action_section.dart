import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_spacing.dart';

/// Terminal action bar: full-width primary commit + optional delete +
/// bordered discard action. Custom chrome (not the sharp global [Button])
/// to match the decluttered deck modal.
class ActionSection extends StatelessWidget {
  final bool saving;
  final VoidCallback onSubmit;
  final String submitLabel;
  final VoidCallback? onDelete;

  const ActionSection({
    super.key,
    required this.saving,
    required this.onSubmit,
    this.submitLabel = 'Add task',
    this.onDelete,
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
          onTap: saving
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onSubmit();
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary,
              border: Border.all(color: scheme.primary, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Text(
              saving ? 'Saving...' : submitLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: saving
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    onDelete!();
                  },
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.error, width: 1.5),
                borderRadius: BorderRadius.zero,
              ),
              alignment: Alignment.center,
              child: Text(
                'Delete task',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
