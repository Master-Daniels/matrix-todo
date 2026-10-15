import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../theme/app_spacing.dart';
import 'section_label.dart';

/// Fallback categories when `listsProvider` is loading/error.
/// Mirrors the seeded DB lists. No `+ CUSTOM` (added via Lists screen later).
const fallbackCategories = ['PERSONAL', 'WORK', 'HOME & LIVING', 'ERRANDS'];

/// `02 // TAXONOMY CATEGORY` — DB-driven wrapping pill row. Selected pill
/// inverted; single-select via [onSelect]. When [locked], the single
/// pill is display-only and taps route to [onLockedTap] instead.
class CategorySection extends ConsumerWidget {
  final String selected;
  final void Function(String name, int? listId) onSelect;
  final bool locked;
  final VoidCallback? onLockedTap;

  const CategorySection({
    super.key,
    required this.selected,
    required this.onSelect,
    this.locked = false,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsProvider);

    final names = listsAsync.maybeWhen(
      data: (lists) => lists.map((l) => l.name.toUpperCase()).toList(),
      orElse: () => fallbackCategories,
    );
    int? listIdFor(String name) => listsAsync.maybeWhen(
      data: (lists) {
        for (final l in lists) {
          if (l.name.toUpperCase() == name) return l.id;
        }
        return null;
      },
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(
          '02 // Taxonomy Category',
          right: locked ? 'LOCKED' : 'Select one',
          boldRight: locked,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (locked)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                  ),
                  child: _CategoryPill(
                    label: selected.toUpperCase(),
                    selected: true,
                    onTap: () => onLockedTap?.call(),
                  ),
                )
              else
                for (final name in names)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    child: _CategoryPill(
                      label: name,
                      selected: name == selected.toUpperCase(),
                      onTap: () => onSelect(name, listIdFor(name)),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(
            color: scheme.primary,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? scheme.onPrimary : scheme.primary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
