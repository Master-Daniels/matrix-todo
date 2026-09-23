import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Swipe + tap wrapper for task rows across every list surface.
///
/// * Swipe left → [onMarkDone] (no-op when already done).
/// * Swipe right → [onMarkUndone] (no-op when undone).
/// * Tap → [onTap] (edit sheet); inner controls (checkbox, popover,
///   links) win their own tap arenas and never trigger it.
///
/// Travel is clamped to half the row width (measured from the laid-out
/// row itself, so full-width rows and half-width grid cells each clamp to
/// their own half) and the action fires past a quarter width; on release
/// the row always animates back — nothing ever slides off-screen.
///
/// Deliberately no [LayoutBuilder] inside: several parents size rows with
/// `IntrinsicHeight`, which cannot compute intrinsics through one.
class TaskSwipe extends StatefulWidget {
  final String swipeKey;
  final bool done;
  final Future<void> Function() onMarkDone;
  final Future<void> Function() onMarkUndone;
  final VoidCallback? onTap;
  final Widget child;

  const TaskSwipe({
    super.key,
    required this.swipeKey,
    required this.done,
    required this.onMarkDone,
    required this.onMarkUndone,
    this.onTap,
    required this.child,
  });

  @override
  State<TaskSwipe> createState() => _TaskSwipeState();
}

class _TaskSwipeState extends State<TaskSwipe> {
  double _dragX = 0;
  double _halfWidth = 160;

  /// Own laid-out width is valid during gesture callbacks (post-layout),
  /// so each row — full-width or half-width grid cell — clamps to its own
  /// half without any [LayoutBuilder].
  void _measure() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      _halfWidth = box.size.width / 2;
    }
  }

  void _release() {
    final threshold = _halfWidth / 2;
    if (_dragX <= -threshold && !widget.done) {
      widget.onMarkDone();
    } else if (_dragX >= threshold && widget.done) {
      widget.onMarkUndone();
    }
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('task-swipe-${widget.swipeKey}'),
      onTap: widget.onTap,
      onHorizontalDragUpdate: (details) {
        _measure();
        setState(() {
          _dragX = (_dragX + details.delta.dx).clamp(
            -_halfWidth,
            _halfWidth,
          );
        });
      },
      onHorizontalDragEnd: (_) => _release(),
      child: Stack(
        children: [
          const Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _SwipePanel(
                    alignment: Alignment.centerLeft,
                    label: 'REOPEN',
                    inverted: false,
                  ),
                ),
                Expanded(
                  child: _SwipePanel(
                    alignment: Alignment.centerRight,
                    label: '✓ DONE',
                    inverted: true,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(_dragX, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _SwipePanel extends StatelessWidget {
  final Alignment alignment;
  final String label;
  final bool inverted;

  const _SwipePanel({
    required this.alignment,
    required this.label,
    required this.inverted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: inverted ? scheme.primary : scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: alignment,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: inverted ? scheme.onPrimary : scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
