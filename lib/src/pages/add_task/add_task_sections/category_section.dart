import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../theme/app_spacing.dart';
import 'section_label.dart';

/// Fallback categories when `listsProvider` is loading/error.
/// Mirrors the seeded DB lists. No `+ CUSTOM` (added via Lists screen later).
const fallbackCategories = ['PERSONAL', 'WORK', 'HOME & LIVING', 'ERRANDS'];

/// `02 // TAXONOMY CATEGORY` — DB-driven 3-column matrix, selected cell
/// inverted with `■`.
class CategorySection extends ConsumerWidget {
  final String selected;
  final void Function(String name, int? listId) onSelect;

  const CategorySection({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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

    final rows = <Widget>[];
    final rowCount = (names.length / 3).ceil();
    for (var r = 0; r < rowCount; r++) {
      final cells = <Widget>[];
      for (var c = 0; c < 3; c++) {
        final i = r * 3 + c;
        if (i < names.length) {
          cells.add(
            _CategoryCell(
              label: names[i],
              selected: names[i] == selected.toUpperCase(),
              lastCol: c == 2,
              onTap: () => onSelect(names[i], listIdFor(names[i])),
            ),
          );
        } else {
          cells.add(
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  border: Border(
                    right: BorderSide(
                      color: scheme.primary,
                      width: c == 2 ? 0 : 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      // Horizontal rule between rows so each grid row reads as its own
      // ledger line (outer top/bottom come from the wrapper border).
      rows.add(
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.primary,
                width: r < rowCount - 1 ? 1 : 0,
              ),
            ),
          ),
          child: IntrinsicHeight(child: Row(children: cells)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('02 // Taxonomy Category', right: 'Select one'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool lastCol;
  final VoidCallback onTap;

  const _CategoryCell({
    required this.label,
    required this.selected,
    required this.lastCol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            border: Border(
              right: BorderSide(color: scheme.primary, width: lastCol ? 0 : 1),
            ),
          ),
          child: Text(
            selected ? '[ $label ] ■' : '[ $label ]',
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? scheme.onPrimary : scheme.primary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
