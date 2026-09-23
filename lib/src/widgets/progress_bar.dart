import 'package:flutter/material.dart';

/// Segmented blueprint progress: N sharp cells sharing 1px rules,
/// filled = black, empty = white. No rounded bars.
class ProgressBar extends StatelessWidget {
  final int total;
  final int completed;
  final double height;

  const ProgressBar({
    super.key,
    required this.total,
    required this.completed,
    this.height = 20,
  }) : assert(total > 0, 'total must be > 0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = completed.clamp(0, total);
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
      ),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i < done;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: filled ? scheme.primary : scheme.surfaceContainerLowest,
                border: i < total - 1
                    ? Border(right: BorderSide(color: scheme.primary, width: 1))
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
