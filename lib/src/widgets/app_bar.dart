import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Edge-to-edge top bar: 1px bottom rule, mono uppercase title,
/// bordered square actions. No elevation, no rounding.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? index;
  final List<Widget> actions;
  final Widget? leading;
  final double? height;

  const CustomAppBar({
    super.key,
    required this.title,
    this.index,
    this.actions = const [],
    this.leading,
    this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? 60);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        left: !isLandscape,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: (height != null && height! > 60) ? 8 : 4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index != null)
                      Text(
                        index!.toUpperCase(),
                        style: AppTypography.indexIndicator(
                          context,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    SizedBox(height: 3),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Square bordered icon button used inside [CustomAppBar].
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool inverted;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.inverted = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button = Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: inverted ? scheme.primary : scheme.surface,
              border: Border.all(color: scheme.primary, width: 1),
            ),
            child: Icon(
              icon,
              size: 18,
              color: inverted ? scheme.onPrimary : scheme.primary,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
