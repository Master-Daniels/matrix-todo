import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import 'section_label.dart';

/// `04 // PRIORITY SEVERITY` — segmented `LOW [01] / MEDIUM [02] / HIGH [03]`
/// with `STATE: LVL-n` header. Selected segment inverted with `■`.
class PrioritySection extends StatelessWidget {
  final int priority;
  final ValueChanged<int> onSelect;

  const PrioritySection({
    super.key,
    required this.priority,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const labels = ['LOW [01]', 'MEDIUM [02]', 'HIGH [03]'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(
          '04 // Priority Severity',
          right: 'STATE: LVL-$priority',
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
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () => onSelect(i + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: priority == i + 1
                              ? scheme.primary
                              : scheme.surface,
                          borderRadius: BorderRadius.zero,
                          border: priority == i + 1
                              ? null
                              : Border.all(
                                  color: scheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          priority == i + 1 ? '${labels[i]} ■' : labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: priority == i + 1
                                ? scheme.onPrimary
                                : scheme.primary,
                            fontWeight: priority == i + 1
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
