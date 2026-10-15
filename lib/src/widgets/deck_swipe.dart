import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Swipe wrapper for deck cards (`today_swipe_gesture_state`):
/// right = complete, left = reschedule picker. Translates + rotates
/// (+8deg at +52px), shows corner stamp, springs back on release.
class HomeDeckSwipe extends StatefulWidget {
  final String swipeKey;
  final bool done;
  final Future<void> Function() onComplete;
  final Future<void> Function() onReschedule;
  final VoidCallback? onTap;
  final Widget child;

  /// False renders a straight translate (flat ledger rows); true adds
  /// the deck tilt.
  final bool rotate;

  const HomeDeckSwipe({
    super.key,
    required this.swipeKey,
    required this.done,
    required this.onComplete,
    required this.onReschedule,
    this.onTap,
    required this.child,
    this.rotate = true,
  });

  @override
  State<HomeDeckSwipe> createState() => _HomeDeckSwipeState();
}

class _HomeDeckSwipeState extends State<HomeDeckSwipe>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  double _halfWidth = 160;
  late AnimationController _spring;
  Animation<double>? _springAnim;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _measure() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      _halfWidth = box.size.width / 2;
    }
  }

  void _onRelease() {
    final threshold = _halfWidth / 2;
    if (_dragX >= threshold && !widget.done) {
      widget.onComplete();
    } else if (_dragX <= -threshold) {
      widget.onReschedule();
    }
    // Spring back.
    _springAnim = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _spring, curve: Curves.easeOut),
    )..addListener(() {
        if (mounted) setState(() => _dragX = _springAnim!.value);
      });
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final swipingRight = _dragX > 12;
    final swipingLeft = _dragX < -12;
    final angle = (_dragX / 650) * (8 * math.pi / 180) * 8;

    return GestureDetector(
      key: ValueKey('deck-swipe-${widget.swipeKey}'),
      onTap: widget.onTap,
      onHorizontalDragUpdate: (details) {
        _measure();
        _spring.stop();
        setState(() {
          _dragX = (_dragX + details.delta.dx).clamp(
            -_halfWidth,
            _halfWidth,
          );
        });
      },
      onHorizontalDragEnd: (_) => _onRelease(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(_dragX, widget.rotate ? _dragX.abs() * -0.02 : 0),
            child: _SwipeBody(
              angle: widget.rotate ? angle.clamp(-0.14, 0.14) : 0,
              swipingRight: swipingRight,
              swipingLeft: swipingLeft,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBody extends StatelessWidget {
  final double angle;
  final bool swipingRight;
  final bool swipingLeft;
  final Widget child;

  const _SwipeBody({
    required this.angle,
    required this.swipingRight,
    required this.swipingLeft,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (swipingRight)
            Positioned(
              top: -12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                color: scheme.primary,
                child: Text(
                  'RELEASE TO COMPLETE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (swipingLeft)
            Positioned(
              top: -12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: scheme.primary,
                    width: 1,
                  ),
                ),
                child: Text(
                  'RELEASE TO RESCHEDULE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
