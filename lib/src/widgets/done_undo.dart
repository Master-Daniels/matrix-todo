import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';

/// Shared undo snackbar (WS9): call after setting a task done.
/// [onUndo] should set the task back to undone + resync + invalidate.
void showDoneUndo(
  BuildContext context,
  WidgetRef ref,
  TodoTask task,
  Future<void> Function() onUndo,
) {
  if (task.id == null) return;
  var title = task.title.trim().toUpperCase();
  if (title.length > 28) title = '${title.substring(0, 28)}…';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('DONE // $title // UNDO?'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // ignore: discarded_futures
            onUndo();
          },
        ),
      ),
    );
}
