import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/animated_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_field.dart';
import '../settings_providers.dart';

/// Name-only profile editor. Persists `profile_name` locally.
class NameEditSheet extends ConsumerStatefulWidget {
  const NameEditSheet({super.key});

  @override
  ConsumerState<NameEditSheet> createState() => _NameEditSheetState();
}

class _NameEditSheetState extends ConsumerState<NameEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(profileNameProvider);
    if (_controller.text.isEmpty && current.isNotEmpty) {
      _controller.text = current;
    }
    return Form(
      key: _formKey,
      child: Sheet(
        title: 'Edit Profile',
        children: [
          CustomTextField(
            label: 'Display name',
            hint: 'e.g. Alex R.',
            controller: _controller,
            required: true,
            checks: [FieldChecks.required()],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                label: _saving ? 'Saving...' : 'Save profile',
                onPressed: _saving ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Button(
                label: 'Discard changes',
                kind: ButtonKind.secondary,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setProfileName(_controller.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
