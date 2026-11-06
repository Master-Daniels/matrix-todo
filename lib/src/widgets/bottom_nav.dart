import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fixed bottom ledger nav: top 1px rule, equal cells split by
/// 1px vertical dividers, active cell fully inverted.
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final active = i == currentIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: active,
                label: '${item.label} tab, ${i + 1} of ${items.length}',
                child: GestureDetector(
                  onTap: () {
                    if (!active) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : scheme.surface,
                      border: i < items.length - 1
                          ? Border(
                              right:
                                  BorderSide(color: scheme.primary, width: 1),
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: active
                              ? scheme.onPrimary
                              : theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: active
                                ? scheme.onPrimary
                                : theme.colorScheme.secondary,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Fixed side ledger rail for landscape / wide viewports: right 1px rule,
/// equal cells split by 1px horizontal dividers, active cell fully inverted.
class SideNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final double width;

  const SideNavRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.width = 90,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leftInset = MediaQuery.paddingOf(context).left;
    final effectiveWidth = width + leftInset;

    return Container(
      width: effectiveWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final active = i == currentIndex;
            return Expanded(
              child: Semantics(
                button: true,
                selected: active,
                label: '${item.label} tab, ${i + 1} of ${items.length}',
                child: GestureDetector(
                  onTap: () {
                    if (!active) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : scheme.surface,
                      border: i < items.length - 1
                          ? Border(
                              bottom:
                                  BorderSide(color: scheme.primary, width: 1),
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: active
                              ? scheme.onPrimary
                              : scheme.secondary,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: active
                                  ? scheme.onPrimary
                                  : scheme.secondary,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 10.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

@immutable
class NavItem {
  final String label;
  final IconData icon;

  const NavItem({required this.label, required this.icon});
}
