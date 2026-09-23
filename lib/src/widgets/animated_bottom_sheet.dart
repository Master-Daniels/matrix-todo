import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

///  bottom-sheet system (single home for all sheet APIs).
///
/// * [Sheet] — content scaffold: opaque container, 2px top border, header
///   with title + `[X] CLOSE`, divided form body. Works in either presenter.
/// * [showAnimatedModalBottomSheet] — primary presenter: modal route with a
///   short slide+fade entrance. Use for forms like Add Task. Pass
///   [heightFactor] (e.g. `0.92`) to stretch the sheet to a fraction of the
///   screen height so it sits higher; omit to hug content.
/// * [showBrutalSheet] — stipple-scrim variant (`showGeneralDialog` +
///   [StippleScrim]) for cases that need the technical hatch overlay.
/// * [StippleScrim] — 72% dark + dot hatch, no blur.
Future<T?> showAnimatedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
  double? heightFactor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (BuildContext context) {
      return AnimatedBottomSheetContent(
        builder: builder,
        heightFactor: heightFactor,
      );
    },
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.4),
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    useSafeArea: true,
  );
}

/// Animated wrapper: slide+fade entrance around  chrome —
/// square corners, 2px top rule, no shadows, no drag pill (the top rule
/// is the handle). Keyboard-aware via `viewInsets` padding.
class AnimatedBottomSheetContent extends StatefulWidget {
  final WidgetBuilder builder;

  /// Fraction of screen height the sheet should occupy. Null hugs content.
  final double? heightFactor;

  const AnimatedBottomSheetContent({
    super.key,
    required this.builder,
    this.heightFactor,
  });

  @override
  State<AnimatedBottomSheetContent> createState() =>
      _AnimatedBottomSheetContentState();
}

class _AnimatedBottomSheetContentState extends State<AnimatedBottomSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final expanded = widget.heightFactor != null;
    final content = Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.primary, width: 2)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Column(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [Flexible(child: widget.builder(context))],
        ),
      ),
    );
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        // Fixed height on purpose: shrinking with viewInsets.bottom is what
        // made the sheet visibly drop when the keyboard opened. The inner
        // viewInsets padding + Flexible scroll area absorb the keyboard
        // while the sheet frame stays put.
        child: expanded
            ? SizedBox(
                height: media.size.height * widget.heightFactor!,
                child: content,
              )
            : content,
      ),
    );
  }
}

/// Bottom sheet scaffold: opaque container, 2px top border,
/// header with title + `[X] CLOSE`, divided form body.
/// Use inside [showAnimatedModalBottomSheet], or with [showBrutalSheet]
/// for the stipple scrim.
class Sheet extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final List<Widget> children;

  const Sheet({
    super.key,
    required this.title,
    this.onClose,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.primary, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                border: Border(
                  bottom: BorderSide(color: scheme.primary, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.primary, width: 1),
                      ),
                      child: Text(
                        '[X] CLOSE',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: children[i],
                      ),
                      if (i < children.length - 1) const Divider(height: 0),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Technical stipple scrim: 72% dark + dot hatch, no blur.
class StippleScrim extends StatelessWidget {
  final VoidCallback? onTap;

  const StippleScrim({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: CustomPaint(
        painter: _StipplePainter(),
        child: Container(color: const Color.fromRGBO(26, 28, 28, 0.72)),
      ),
    );
  }
}

class _StipplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF000000);
    const step = 4.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<T?> showBrutalSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, _, _) {
      return Stack(
        children: [
          const Positioned.fill(child: StippleScrim()),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Material(
                color: Colors.transparent,
                child: builder(dialogContext),
              ),
            ),
          ),
        ],
      );
    },
  );
}
