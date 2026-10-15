import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Edge-to-edge top bar: 1px bottom rule, mono uppercase title,
/// bordered square actions. No elevation, no rounding.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? index;
  final List<Widget> actions;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.index,
    this.actions = const [],
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
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
                      title.toUpperCase(),
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
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
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
    );
  }
}
