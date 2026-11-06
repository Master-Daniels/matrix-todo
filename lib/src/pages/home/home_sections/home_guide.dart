import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../settings/settings_providers.dart';

/// Gesture legend pinned above the action bar. First-run only: hides
/// permanently once dismissed via GOT IT (`guide_seen` setting).
class HomeGuide extends ConsumerWidget {
  const HomeGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(guideSeenProvider)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        8,
        AppSpacing.md,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.primary, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'SWIPE RIGHT = COMPLETE • SWIPE LEFT = RESCHEDULE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Dismiss gesture guide',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setGuideSeen(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    border: Border.all(color: scheme.primary, width: 1),
                  ),
                  child: Text(
                    'Got it',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
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
