import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/button.dart';
import '../../widgets/search_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../list_detail/list_detail_page.dart';
import 'list_form_sheet.dart';
import 'lists_providers.dart';
import 'lists_sections/core_list_card.dart';
import 'lists_sections/ledger_banner.dart';

/// Lists // Folders — scrollable ledgers with a pinned create footer.
/// Taps push [ListDetailPage]; create opens [ListFormSheet] as a modal.
class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreAsync = ref.watch(coreListsProvider);
    final customAsync = ref.watch(customListsProvider);
    final coreCount =
        coreAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lists',
        actions: [
          CustomIconButton(
            icon: Icons.search,
            onPressed: () => showAnimatedModalBottomSheet(
              context: context,
              builder: (_) => const SearchSheet(),
            ),
          ),
          const SizedBox(width: 8),
          CustomIconButton(
            icon: Icons.add,
            inverted: true,
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const LedgerBanner(),
                const SectionHeader(
                  title: 'Core directories // Quad-matrix',
                  index: '[SEC 01]',
                ),
                coreAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: LoadingState(label: 'Loading lists'),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(coreListsProvider),
                    ),
                  ),
                  data: (lists) => _CoreGrid(
                    lists: lists,
                    onOpen: (l) => _openDetail(context, l),
                  ),
                ),
                const SectionHeader(
                  title: 'Custom lists',
                  index: '[SEC 02]',
                ),
                customAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(customListsProvider),
                    ),
                  ),
                  data: (lists) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lists.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: _DashedEmptyLists(),
                        ),
                      for (var i = 0; i < lists.length; i++)
                        CoreListCard(
                          list: lists[i],
                          index: (coreCount + i + 1)
                              .toString()
                              .padLeft(2, '0'),
                          onOpen: () => _openDetail(context, lists[i]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CreateFooter(onCreate: () => _openForm(context)),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, TaskList list) {
    if (list.id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListDetailPage(list: list)),
    );
  }

  void _openForm(BuildContext context) {
    showAnimatedModalBottomSheet(
      context: context,
      builder: (_) => const ListFormSheet(),
    );
  }
}

/// Single column on phones, 2-column matrix on wider screens.
/// Cards carry their own borders + margins, so no divider column.
class _CoreGrid extends StatelessWidget {
  final List<TaskList> lists;
  final ValueChanged<TaskList> onOpen;

  const _CoreGrid({required this.lists, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < lists.length; i++)
                CoreListCard(
                  list: lists[i],
                  index: (i + 1).toString().padLeft(2, '0'),
                  onOpen: () => onOpen(lists[i]),
                ),
            ],
          );
        }
        final rows = <Widget>[];
        for (var r = 0; r * 2 < lists.length; r += 1) {
          final cells = <Widget>[];
          for (var c = 0; c < 2; c++) {
            final i = r * 2 + c;
            if (i < lists.length) {
              cells.add(
                Expanded(
                  child: CoreListCard(
                    list: lists[i],
                    index: (i + 1).toString().padLeft(2, '0'),
                    onOpen: () => onOpen(lists[i]),
                  ),
                ),
              );
            } else {
              cells.add(const Expanded(child: SizedBox.shrink()));
            }
          }
          rows.add(IntrinsicHeight(child: Row(children: cells)));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

/// Pinned action zone: always visible under the scrolling ledgers.
class _CreateFooter extends StatelessWidget {
  final VoidCallback onCreate;

  const _CreateFooter({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.primary, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Button(
              label: 'Create new list',
              leading: const Icon(Icons.add_box_outlined, size: 18),
              onPressed: onCreate,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Dashed empty state for custom lists (matches timeline empty-box language).
class _DashedEmptyLists extends StatelessWidget {
  const _DashedEmptyLists();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CustomPaint(
      painter: _DashedBorderPainter(color: scheme.primary),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '[EMPTY STATE]',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No custom lists',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first list',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      var drawn = 0.0;
      while (drawn < total) {
        final end = (drawn + dash).clamp(0.0, total);
        canvas.drawLine(
          a + (b - a) * (drawn / total),
          a + (b - a) * (end / total),
          paint,
        );
        drawn += dash + gap;
      }
    }

    line(Offset.zero, Offset(size.width, 0));
    line(Offset(size.width, 0), Offset(size.width, size.height));
    line(Offset(size.width, size.height), Offset(0, size.height));
    line(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
