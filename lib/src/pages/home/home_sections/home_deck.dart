import 'package:flutter/material.dart';

import '../../../data/models.dart';

/// Single continuous deck holding every today task.
///
/// * Middle: uniform-height vertical snap pager — scrolling brings one
///   card forward at a time, and back again reversibly, with no gaps.
/// * Below: the next queued todos filed as a tight descending pile of
///   summary strips (display-only), glued to the pager.
/// * Above: already-viewed todos filed as an identical ascending pile,
///   the deck transitions from downward to upward while scrolling.
///
/// Horizontal swipe (complete / reschedule) lives on the focused card
/// only; pile strips are display-only.
class HomeDeck extends StatefulWidget {
  final List<TodoTask> tasks;
  final Widget Function(int index, TodoTask task) cardBuilder;

  /// Fixed card height: every page is identical, keeping the pile tight.
  static const double fixedCardHeight = 340;

  final double cardHeight;

  /// Maximum todos shown in each pile (above and below).
  final int maxPile;

  const HomeDeck({
    super.key,
    required this.tasks,
    required this.cardBuilder,
    this.cardHeight = fixedCardHeight,
    this.maxPile = 3,
  });

  @override
  State<HomeDeck> createState() => _HomeDeckState();
}

class _HomeDeckState extends State<HomeDeck> {
  late final PageController _pages;

  /// Settled page. BOTH surroundings (above edges and below pile) are
  /// driven by it and update only when scrolling stops. Updating anything
  /// around the pager mid-flight causes visible layout jumps in the deck
  /// during the transition, so there is deliberately no live tracking.
  int _settled = 0;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Settles the above edges. NOTE: this must NOT listen to the
  /// controller itself — controller listeners only fire on pixel
  /// notifications, never on the scroll-stop flip, so `_settled` would
  /// never update. The `ScrollEndNotification` below is the reliable
  /// signal instead.
  void _onScrollEnd() {
    if (!mounted || !_pages.hasClients) return;
    final actual = _pages.page?.round();
    if (actual != null && actual != _settled) {
      setState(() => _settled = actual);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final viewed = <int>[
      for (var k = _settled - 1;
          k >= 0 && k > _settled - 1 - widget.maxPile;
          k--)
        k,
    ];
    final buried = <int>[
      for (var k = 1; k <= widget.maxPile; k++)
        if (_settled + k < tasks.length) _settled + k,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var v = viewed.length - 1; v >= 0; v--)
          _DeckStrip(
            key: ValueKey('up-$_settled-${viewed.length - v}'),
            task: tasks[viewed[v]],
            number: viewed[v] + 1,
            depth: viewed.length - v,
          ),
        SizedBox(
          // Stable key: siblings above/below (edges, strips) come and go
          // as you page. Without it, an insertion above can remount this
          // subtree, resetting the scroll position to page 0 while state
          // believes otherwise (frozen-on-page-0 desync).
          key: const ValueKey('pager'),
          height: widget.cardHeight,
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (n) {
              // depth 0 = the pager itself; deeper notifications (none
              // inside cards today) are ignored.
              if (n.depth == 0) _onScrollEnd();
              return false;
            },
            child: PageView.builder(
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: tasks.length,
              itemBuilder: (context, i) => widget.cardBuilder(i, tasks[i]),
            ),
          ),
        ),
        for (var s = 0; s < buried.length; s++)
          _DeckStrip(
            key: ValueKey('pile-$_settled-$s'),
            task: tasks[buried[s]],
            number: buried[s] + 1,
            depth: s + 1,
          ),
      ],
    );
  }
}

/// One filed todo in either pile: index + category + single-line title +
/// due time, narrowing with depth like cards filed around the top one.
class _DeckStrip extends StatelessWidget {
  final TodoTask task;
  final int number;
  final int depth;

  const _DeckStrip({
    super.key,
    required this.task,
    required this.number,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rawDue = (task.dueTime ?? '').trim();
    final due = rawDue.isEmpty ? 'ANYTIME' : rawDue;
    // Outer outline following the rounded border (3px gap), mirroring
    // the double-frame treatment.
    return Container(
      margin: EdgeInsets.fromLTRB(9.0 * depth, 8, 9.0 * depth, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            '#${number.toString().padLeft(2, '0')}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1),
            ),
            child: Text(
              task.category.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            due.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
