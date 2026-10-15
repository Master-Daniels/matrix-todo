import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// Boxy ledger toggle: title + subtitle (+ optional badge) left,
/// 64×32 bordered ON/OFF block right. No curves, no switches.
class ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.value,
    required this.onChanged,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: scheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badge!.toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                border: Border.all(color: scheme.primary, width: 1),
              ),
              padding: const EdgeInsets.all(2),
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: value ? scheme.primary : scheme.surfaceContainerHigh,
                  border: value
                      ? null
                      : Border.all(color: scheme.primary, width: 1),
                ),
                child: Center(
                  child: Text(
                    value ? 'ON' : 'OFF',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: value ? scheme.onPrimary : scheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
