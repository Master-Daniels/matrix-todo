import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import 'section_label.dart';

/// `05 // Recurrence` — segmented `NONE / DAILY / WEEKLY`.
/// Completing a recurring task clones it onto the next due date.
class RecurrenceSection extends StatelessWidget {
  final String recurrence;
  final ValueChanged<String> onSelect;

  const RecurrenceSection({
    super.key,
    required this.recurrence,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const values = ['NONE', 'DAILY', 'WEEKLY'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(
          '05 // Recurrence',
          right: 'RULE: $recurrence',
          boldRight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () => onSelect(values[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: recurrence == values[i]
                              ? scheme.primary
                              : scheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: recurrence == values[i]
                              ? null
                              : Border.all(
                                  color: scheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          recurrence == values[i]
                              ? '${values[i]} ■'
                              : values[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: recurrence == values[i]
                                ? scheme.onPrimary
                                : scheme.primary,
                            fontWeight: recurrence == values[i]
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
