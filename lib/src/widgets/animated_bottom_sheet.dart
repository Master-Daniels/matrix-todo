import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

///  bottom-sheet system (single home for all sheet APIs).
///
/// * [Sheet] — content scaffold: opaque container, 2px top border, header
///   with title + `[X] CLOSE`, divided form body. Works in either presenter.
/// * [showAnimatedModalBottomSheet] — primary presenter: modal route with a
///   short slide+fade entrance. Use for forms like Add Task. The sheet
///   always docks bottom and hugs content (capped at 85% height, scrolling
///   internally beyond that) — never floating, never stretched.
/// * [showBrutalSheet] — stipple-scrim variant (`showGeneralDialog` +
///   [StippleScrim]) for cases that need the technical hatch overlay.
/// * [StippleScrim] — 72% dark + dot hatch, no blur.
Future<T?> showAnimatedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (BuildContext context) {
      return AnimatedBottomSheetContent(
        builder: builder,
      );
    },
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.4),
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    // Cap width on tablets/landscape so rows never stretch edge to edge.
    constraints: const BoxConstraints(maxWidth: 640),
    // Single safe-area source: the Sheet pads its own content below, so
    // the background stays flush with the screen bottom edge (docked,
    // never floating). useSafeArea:true would lift the whole sheet.
    useSafeArea: false,
  );
}

/// Animated wrapper: slide+fade entrance around  chrome —
/// square corners, 2px top rule, no shadows, no drag pill (the top rule
/// is the handle). Keyboard-aware via `viewInsets` padding.
class AnimatedBottomSheetContent extends StatefulWidget {
  final WidgetBuilder builder;

  const AnimatedBottomSheetContent({
    super.key,
    required this.builder,
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
    final media = MediaQuery.of(context);
    // Hug content, capped at 85%: the route bottom-anchors the box, so
    // the sheet is always docked flush (never floating middle) and the
    // inner Flexible below always has bounded height to work with.
    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.85,
          ),
          child: widget.builder(context),
        ),
      ),
    );
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: content,
      ),
    );
  }
}

/// Bottom sheet scaffold: rounded-top opaque container (decluttered
/// deck styling), drag pill, header with title + optional tag + close,
/// spaced form body. Use inside [showAnimatedModalBottomSheet], or with
/// [showBrutalSheet] for the stipple scrim.
class Sheet extends StatelessWidget {
  final String title;

  /// Optional uppercase tag pill next to the title (e.g. `DECK ENTRY`).
  final String? tag;
  final VoidCallback? onClose;
  final List<Widget> children;

  const Sheet({
    super.key,
    required this.title,
    this.tag,
    this.onClose,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Manual bottom inset (route useSafeArea is off): background stays
    // flush with the screen edge while content clears the gesture bar.
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPad = viewPadding > 12 ? viewPadding : 12.0;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border(
          top: BorderSide(color: scheme.primary, width: 2),
          left: BorderSide(color: scheme.primary, width: 2),
          right: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tactile drag indicator.
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.35),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              tag!.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.primary, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i < children.length - 1)
                        const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
