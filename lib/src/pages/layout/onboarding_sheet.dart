import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../settings/settings_providers.dart';

/// First-run coach: 3 pages (deck gestures / folders / reminders),
/// blocking dialog, persisted via `onboarding_seen`.
class OnboardingSheet extends ConsumerStatefulWidget {
  const OnboardingSheet({super.key});

  @override
  ConsumerState<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends ConsumerState<OnboardingSheet> {
  final _pages = PageController();
  int _page = 0;

  static const _slides = [
    (
      index: '01 // TODAY',
      title: 'Swipe the deck',
      body: 'Swipe right to complete a task. Swipe left to reschedule it. '
          'The top card is your focus.',
    ),
    (
      index: '02 // FOLDERS',
      title: 'File by list',
      body: 'Lists keep work, home and errands separate. Open a list to '
          'filter, sort and reorder.',
    ),
    (
      index: '03 // INGEST',
      title: 'Bring tasks',
      body: 'Settings → Data backup imports a JSON backup or an easy CSV list. '
          'Unknown lists are created.',
    ),
    (
      index: '04 // DISPATCH',
      title: 'Never miss a start',
      body: '1-hour chimes plus an on-time alarm. Morning briefing at 8:00, '
          'streak nudge at 8:00.',
    ),
    (
      index: '05 // DENSITY',
      title: 'Deck or flat list',
      body: 'The grid button beside Add task flips the stacked deck into a '
          'flat list. Same tasks, denser.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setOnboardingSeen(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.primary, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      elevation: 0,
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: _finish,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        s.index,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.body,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    width: 24,
                    height: 6,
                    margin: EdgeInsets.only(
                      right: i < _slides.length - 1 ? 4 : 0,
                    ),
                    color: i == _page
                        ? scheme.primary
                        : scheme.surfaceContainerHigh,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_page < _slides.length - 1) {
                  _pages.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                } else {
                  _finish();
                }
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  border: Border.all(color: scheme.primary, width: 1),
                ),
                child: Text(
                  _page < _slides.length - 1 ? 'NEXT ->' : 'START ->',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
