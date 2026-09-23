import 'package:flutter/material.dart';

enum ButtonKind { primary, secondary, danger }

/// Full-border rectilinear button, 0px radius.
/// Primary: black fill / white mono label. Secondary: white fill.
/// Danger: red 2px outline + red label (hover tints red).
/// Active/pressed inverts (handled by caller via [selected] where needed).
class Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final Widget? leading;
  final bool expanded;

  const Button({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = ButtonKind.primary,
    this.leading,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPrimary = kind == ButtonKind.primary;
    var style =
        (isPrimary
                ? theme.elevatedButtonTheme.style
                : theme.outlinedButtonTheme.style)!
            .copyWith(
              minimumSize: WidgetStateProperty.all(
                Size(expanded ? double.infinity : 0, 48),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
    if (kind == ButtonKind.danger) {
      style = style.copyWith(
        foregroundColor: WidgetStatePropertyAll(scheme.error),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.error, width: 2),
        ),
      );
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Flexible(
          child: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (isPrimary) {
      return ElevatedButton(onPressed: onPressed, style: style, child: child);
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Underlined ghost action with trailing `->`.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 1,
              color: scheme.primary,
            ),
          ),
          Icon(Icons.arrow_right, size: 20, color: scheme.primary),
        ],
      ),
    );
  }
}
