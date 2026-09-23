import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/checkbox.dart';
import '../../../widgets/text_field.dart';
import 'section_label.dart';

/// Local draft for a subtask node. `id == null` means not yet persisted:
/// inserted on save in create mode, diffed (update/insert/delete) in edit
/// mode via the initial id snapshot held by the sheet.
class DraftSubtask {
  int? id;
  String title;
  bool done = false;
  DraftSubtask(this.title, {this.id, this.done = false});
}

/// `05 // SUB-EXECUTION NODES` — bordered ledger with done toggle, delete,
/// tap-to-edit rows and an inline `+ ADD SUBTASK NODE` row.
///
/// The single input (add or edit, never both) lives in its own [Form] so
/// empty confirms fail validation with the red `REQ*` error instead of
/// silently dropping.
class SubtaskSection extends StatelessWidget {
  final List<DraftSubtask> drafts;
  final bool adding;
  final int editingIndex;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final GlobalKey<FormState> inputFormKey;
  final void Function(int i, bool v) onToggle;
  final void Function(int i) onDelete;
  final void Function(int i) onStartEdit;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelInput;
  final VoidCallback onConfirmAdd;
  final VoidCallback onConfirmEdit;

  const SubtaskSection({
    super.key,
    required this.drafts,
    required this.adding,
    required this.editingIndex,
    required this.controller,
    required this.focusNode,
    required this.inputFormKey,
    required this.onToggle,
    required this.onDelete,
    required this.onStartEdit,
    required this.onStartAdd,
    required this.onCancelInput,
    required this.onConfirmAdd,
    required this.onConfirmEdit,
  });

  bool get _inputOpen => adding || editingIndex >= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(
          '05 // Sub-Execution Nodes',
          right: '${drafts.length} ITEMS',
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < drafts.length; i++)
                if (editingIndex == i)
                  _InputRow(
                    key: ValueKey('edit-$i'),
                    controller: controller,
                    focusNode: focusNode,
                    formKey: inputFormKey,
                    confirmLabel: 'SAVE',
                    onConfirm: onConfirmEdit,
                    onCancel: onCancelInput,
                    hasTopBorder: i > 0,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: i < drafts.length - 1 || _inputOpen
                          ? Border(
                              bottom: BorderSide(
                                color: scheme.primary,
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        CustomCheckbox(
                          value: drafts[i].done,
                          onChanged: (v) => onToggle(i, v),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onStartEdit(i),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              drafts[i].title.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: drafts[i].done
                                    ? scheme.secondary
                                    : scheme.primary,
                                decoration: drafts[i].done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          drafts[i].done ? 'DONE' : 'PENDING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onDelete(i),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
              if (adding)
                _InputRow(
                  key: const ValueKey('add'),
                  controller: controller,
                  focusNode: focusNode,
                  formKey: inputFormKey,
                  confirmLabel: 'ADD',
                  onConfirm: onConfirmAdd,
                  onCancel: onCancelInput,
                  hasTopBorder: drafts.isNotEmpty,
                )
              else if (editingIndex < 0)
                GestureDetector(
                  onTap: onStartAdd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      border: Border(
                        top: BorderSide(
                          color: scheme.primary,
                          width: drafts.isEmpty ? 0 : 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '+ ADD SUBTASK NODE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared inline input for add + edit. Only one is ever mounted, so the
/// parent's single [formKey] validates whichever is open.
class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final GlobalKey<FormState> formKey;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool hasTopBorder;

  const _InputRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.formKey,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    required this.hasTopBorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: hasTopBorder
            ? Border(top: BorderSide(color: scheme.primary, width: 1))
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'SUBTASK // TITLE',
                    hint: 'SUBTASK TITLE',
                    controller: controller,
                    focusNode: focusNode,
                    required: true,
                    checks: [FieldChecks.required()],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    color: scheme.primary,
                    child: Text(
                      confirmLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
