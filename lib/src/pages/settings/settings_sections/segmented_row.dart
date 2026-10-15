import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Ledger option row: title + subtitle left, bordered segmented control
/// right. Selected cell inverted; unselected cells share 1px dividers.
class SegmentedRow<T extends Object> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const SegmentedRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1),
            ),
            child: Row(
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(values[i]),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: values[i] == selected
                              ? scheme.primary
                              : scheme.surfaceContainerLowest,
                          border: i < values.length - 1
                              ? Border(
                                  right: BorderSide(
                                    color: scheme.primary,
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          '[ ${label(values[i]).toUpperCase()} ]${values[i] == selected ? ' ■' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: values[i] == selected
                                ? scheme.onPrimary
                                : scheme.primary,
                            fontWeight: values[i] == selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
