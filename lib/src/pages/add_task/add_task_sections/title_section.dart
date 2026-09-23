import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/text_field.dart';
import 'section_label.dart';

/// `01 // TASK NAME` — required title input.
class TitleSection extends StatelessWidget {
  final TextEditingController controller;

  const TitleSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(
          '01 // Task Name // What needs doing?',
          right: 'REQ*',
          boldRight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomTextField(
          hint: 'e.g. Schedule architecture audit',
          controller: controller,
          required: true,
          checks: [FieldChecks.required()],
        ),
      ],
    );
  }
}
