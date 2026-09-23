import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'button.dart';

/// Square bordered outcome dialog: title, mono message, close.
/// Shared by settings data/export flows and schedule export.
class ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;

  const ResultDialog({
    super.key,
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError ? scheme.error : scheme.primary;
    return Dialog(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              message.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Button(
              label: 'Close',
              kind: ButtonKind.secondary,
              expanded: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
