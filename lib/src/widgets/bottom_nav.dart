import 'package:flutter/material.dart';

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
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? scheme.primary : scheme.surface,
                    border: i < items.length - 1
                        ? Border(
                            right: BorderSide(color: scheme.primary, width: 1),
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
                      const SizedBox(height: 2),
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
