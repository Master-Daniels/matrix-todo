import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/text_field.dart';
import 'section_label.dart';

/// `01B // TASK NOTES` — optional free-text description shown on the
/// home deck card when non-empty. Never required.
class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(
          '01B // Task Notes // Description',
          right: 'OPTIONAL',
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomTextField(
          hint: 'e.g. Context, links, acceptance criteria',
          controller: controller,
          maxLines: 3,
        ),
      ],
    );
  }
}
