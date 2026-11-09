import 'package:flutter/material.dart';

import '../../../theme/app_borders.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'section_label.dart';

/// Optional estimated task duration selector.
/// Offers quick preset chips (`15m`, `30m`, `45m`, `1h`) and a `Custom`
/// chip that opens the clock picker.
class EstimatedDurationSection extends StatelessWidget {
  final int? estimatedMinutes;
  final ValueChanged<int?> onSelectDuration;
  final VoidCallback onPickCustom;

  const EstimatedDurationSection({
    super.key,
    required this.estimatedMinutes,
    required this.onSelectDuration,
    required this.onPickCustom,
  });

  static const _presets = [
    (minutes: 15, label: '15m'),
    (minutes: 30, label: '30m'),
    (minutes: 45, label: '45m'),
    (minutes: 60, label: '1h'),
  ];

  static String formatMinutes(int mins) {
    if (mins < 60) return '$mins MIN';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h HR' : '$h HR $m MIN';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPresetSelected = _presets.any((p) => p.minutes == estimatedMinutes);
    final isCustomSelected = estimatedMinutes != null && !isPresetSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('Estimated duration', right: 'Optional'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final p in _presets)
              _Chip(
                label: p.label,
                selected: estimatedMinutes == p.minutes,
                onTap: () {
                  if (estimatedMinutes == p.minutes) {
                    onSelectDuration(null); // Unselect if tapped again
                  } else {
                    onSelectDuration(p.minutes);
                  }
                },
              ),
            _Chip(
              label: isCustomSelected
                  ? 'Custom (${formatMinutes(estimatedMinutes!)})'
                  : 'Custom',
              icon: Icons.schedule,
              selected: isCustomSelected,
              onTap: onPickCustom,
            ),
          ],
        ),
        if (estimatedMinutes != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'TARGET TIME: +${formatMinutes(estimatedMinutes!)}',
                style: TextStyle(
                  fontFamily: AppTypography.monoFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: scheme.secondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onSelectDuration(null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    '[CLEAR]',
                    style: TextStyle(
                      fontFamily: AppTypography.monoFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: AppBorders.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? scheme.onPrimary : scheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.monoFamily,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
