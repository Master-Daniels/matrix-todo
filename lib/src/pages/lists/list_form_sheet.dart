import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/animated_bottom_sheet.dart';
import '../../widgets/button.dart';
import '../../widgets/text_field.dart';
import 'lists_providers.dart';

/// Derives a ledger code from a name: first 4 alphanumerics, uppercased
/// (`Reading List` → `READ`). Used when the code field is left empty.
String deriveListCode(String name) {
  final chars = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (chars.isEmpty) return 'LIST';
  return chars.length <= 4 ? chars : chars.substring(0, 4);
}

/// `+ CREATE NEW CATEGORY` brutal sheet: `01` name (required), `02` code
/// (optional, auto-derived), `03` description. New lists land in
/// `SEC 02` (`sort` continues past the seeded core directories).
class ListFormSheet extends ConsumerStatefulWidget {
  const ListFormSheet({super.key});

  @override
  ConsumerState<ListFormSheet> createState() => _ListFormSheetState();
}

class _ListFormSheetState extends ConsumerState<ListFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Sheet(
        title: '[+] New Category',
        children: [
          CustomTextField(
            label: '01 // List name // What is this folder for?',
            hint: 'e.g. Reading list',
            controller: _nameController,
            required: true,
            checks: [FieldChecks.required()],
          ),
          CustomTextField(
            label: '02 // Code // Short ledger tag',
            hint: 'e.g. READ (auto if empty)',
            controller: _codeController,
          ),
          CustomTextField(
            label: '03 // Description // Scope notes',
            hint: 'e.g. Monographs and technical papers',
            controller: _descController,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                label: _saving ? 'SAVING...' : 'COMMIT & SAVE LIST',
                onPressed: _saving ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Button(
                label: 'DISCARD CHANGES',
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
      final name = _nameController.text.trim().toUpperCase();
      final code = _codeController.text.trim().isEmpty
          ? deriveListCode(name)
          : _codeController.text.trim().toUpperCase();
      final existing = await ref.read(listsProvider.future);
      var maxSort = 3;
      for (final l in existing) {
        if (l.sort > maxSort) maxSort = l.sort;
      }
      await ref.read(appDatabaseProvider).insertList(
            TaskList(
              name: name,
              code: code,
              description: _descController.text.trim(),
              sort: maxSort + 1,
            ),
          );
      ref.invalidate(listsProvider);
      ref.invalidate(coreListsProvider);
      ref.invalidate(customListsProvider);
      ref.invalidate(listsSummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
