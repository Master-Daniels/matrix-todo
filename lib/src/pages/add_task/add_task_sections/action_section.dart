import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/button.dart';

/// Terminal action bar: primary commit + secondary discard.
class ActionSection extends StatelessWidget {
  final bool saving;
  final VoidCallback onSubmit;
  final String submitLabel;

  const ActionSection({
    super.key,
    required this.saving,
    required this.onSubmit,
    this.submitLabel = 'COMMIT & SAVE TASK -> [ENTER]',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          label: saving ? 'SAVING...' : submitLabel,
          onPressed: saving ? null : onSubmit,
        ),
        const SizedBox(height: AppSpacing.sm),
        Button(
          label: 'DISCARD CHANGES',
          kind: ButtonKind.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
