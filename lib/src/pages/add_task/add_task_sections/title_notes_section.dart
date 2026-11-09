import 'package:flutter/material.dart';

import '../../../theme/app_borders.dart';
import '../../../theme/app_spacing.dart';
import 'section_label.dart';

/// Combined Task Name and Notes input in a single unified card.
/// Replaces the separate TitleSection and NotesSection to eliminate vertical clutter.
class TitleNotesSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController notesController;

  const TitleNotesSection({
    super.key,
    required this.titleController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(
          'Task details',
          right: 'Required',
          boldRight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.primary, width: 1),
            borderRadius: AppBorders.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Task Name
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task name',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Pay the electric bill',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary.withValues(alpha: 0.35),
                          fontSize: 14,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'REQUIRED*';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: scheme.primary.withValues(alpha: 0.25),
              ),
              // Notes
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs + 2,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      minLines: 2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Context, links, acceptance criteria',
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
