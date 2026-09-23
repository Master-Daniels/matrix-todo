import 'package:flutter/material.dart';

/// Rectangular tag block: 1px border, 0px radius, 4x8 padding,
/// uppercase Space Mono. Active = black fill / white text.
class CustomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CustomChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.primary, width: 1),
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? scheme.onPrimary : scheme.primary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
