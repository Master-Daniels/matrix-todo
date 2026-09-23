import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'button.dart';

/// Shared screen states: bordered ledger blocks, mono indices,
/// Megrim titles. Use these in every screen instead of ad-hoc placeholders
/// so loading/empty/error look identical across Today / Upcoming / Lists.
class EmptyState extends StatelessWidget {
  final String index;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.index = '[EMPTY]',
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.primary, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title.toUpperCase(), style: theme.textTheme.headlineSmall),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Button(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Indeterminate loader: a filled cell marching across N
/// 1px-bordered segments + a mono status label. No spinners, no curves.
class LoadingState extends StatelessWidget {
  final String label;
  final int cells;

  const LoadingState({
    super.key,
    this.label = 'LOADING // PLEASE WAIT',
    this.cells = 8,
  }) : assert(cells > 1, 'cells must be > 1');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
          ),
          child: _MarchingCells(cells: cells),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(color: scheme.secondary),
        ),
      ],
    );
  }
}

class _MarchingCells extends StatefulWidget {
  final int cells;

  const _MarchingCells({required this.cells});

  @override
  State<_MarchingCells> createState() => _MarchingCellsState();
}

class _MarchingCellsState extends State<_MarchingCells>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * widget.cells).floor();
        return Row(
          children: List.generate(widget.cells, (i) {
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: i == active
                      ? scheme.primary
                      : scheme.surfaceContainerLowest,
                  border: i < widget.cells - 1
                      ? Border(
                          right: BorderSide(color: scheme.primary, width: 1),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Failure block: `[ERR]` index in error red, message, retry.
class ErrorState extends StatelessWidget {
  final String index;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.index = '[ERR]',
    required this.message,
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.error, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message.toUpperCase(),
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: AppSpacing.md),
          Button(
            label: retryLabel,
            kind: ButtonKind.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
