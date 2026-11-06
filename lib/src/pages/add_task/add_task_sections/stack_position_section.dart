import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// `DECK STACK POSITION` — top = next up in queue, bottom = append.
/// Maps to `sort` on insert (min-1 / max+1, computed by the sheet).
class StackPositionSection extends StatelessWidget {
  final bool top;
  final ValueChanged<bool> onSelect;

  const StackPositionSection({
    super.key,
    required this.top,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task position',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              Icon(Icons.layers, size: 16, color: scheme.secondary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Option(
                  label: 'Top of list',
                  hint: 'Next up in the queue',
                  icon: Icons.vertical_align_top,
                  selected: top,
                  onTap: () => onSelect(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Option(
                  label: 'Bottom of list',
                  hint: 'Append to the list',
                  icon: Icons.vertical_align_bottom,
                  selected: !top,
                  onTap: () => onSelect(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(
            color: scheme.primary,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? scheme.onPrimary : scheme.secondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? scheme.onPrimary.withValues(alpha: 0.7)
                    : scheme.secondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
