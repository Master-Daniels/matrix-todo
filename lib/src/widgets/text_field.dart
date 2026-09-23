import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Single validation rule: return an error string or `null` when valid.
///
/// Pass a list via [CustomTextField.checks]; the first non-null message
/// wins. Combine with [CustomTextField.validator] for one-off logic.
/// See [FieldChecks] for composable factories.
typedef FieldCheck = String? Function(String? value);

/// Composable, configurable validation rules for [CustomTextField].
///
/// Example:
/// ```dart
/// CustomTextField(
///   label: 'Email',
///   checks: [FieldChecks.required(), FieldChecks.email()],
/// )
/// ```
abstract final class FieldChecks {
  /// Fails when the value is null/empty/whitespace-only.
  static FieldCheck required([String message = 'REQUIRED*']) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  /// Fails when the value is shorter than [min].
  static FieldCheck minLength(int min, [String? message]) {
    return (value) {
      final v = value ?? '';
      if (v.length < min) return message ?? 'MIN $min CHARS*';
      return null;
    };
  }

  /// Fails when the value is longer than [max].
  static FieldCheck maxLength(int max, [String? message]) {
    return (value) {
      final v = value ?? '';
      if (v.length > max) return message ?? 'MAX $max CHARS*';
      return null;
    };
  }

  /// Fails when [pattern] does not match the value.
  static FieldCheck pattern(RegExp pattern, [String message = 'INVALID*']) {
    return (value) {
      final v = value ?? '';
      if (!pattern.hasMatch(v)) return message;
      return null;
    };
  }

  /// Simple email check (empty passes — combine with [required] to forbid).
  static FieldCheck email([String message = 'INVALID EMAIL*']) {
    return pattern(RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'), message);
  }

  /// Runs [checks] in order, returning the first error or `null`.
  static FormFieldValidator<String> combine(List<FieldCheck> checks) {
    return (value) {
      for (final check in checks) {
        final error = check(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

/// Rectilinear input: 1px perimeter, md padding, white fill.
/// Focus thickens to 2px (via theme). Label is sticky uppercase mono.
///
/// Validatable: pass [checks] and/or [validator]; they are combined into a
/// single `TextFormField.validator` (first [checks] failure wins, then
/// [validator]). With neither set — and no [errorText] — the field behaves
/// exactly as before (no validation UI). Use inside a [Form] and call
/// `Form.of(context).validate()`, or set [autovalidateMode].
///
/// Existing parameters are untouched; all validation parameters are optional.
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool required;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Ordered validation rules. First failure wins.
  final List<FieldCheck>? checks;

  /// Extra one-off validation, run after [checks].
  final FormFieldValidator<String>? validator;

  /// When to auto-run validation. Defaults to disabled unless validation
  /// is configured, in which case `onUserInteraction`.
  final AutovalidateMode? autovalidateMode;

  /// Manual error override (takes precedence over validation output).
  final String? errorText;

  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;

  /// Optional externally-owned focus node (e.g. autofocus an input that
  /// mounts on demand). When null the field manages its own node.
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.required = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.checks,
    this.validator,
    this.autovalidateMode,
    this.errorText,
    this.onChanged,
    this.onSaved,
    this.focusNode,
  });

  FormFieldValidator<String>? get _effectiveValidator {
    final checks = this.checks;
    final validator = this.validator;
    if ((checks == null || checks.isEmpty) && validator == null) return null;
    return (value) {
      if (checks != null) {
        for (final check in checks) {
          final error = check(value);
          if (error != null) return error;
        }
      }
      return validator?.call(value);
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                if (required)
                  Text(
                    'REQ*',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          onSaved: onSaved,
          validator: _effectiveValidator,
          autovalidateMode:
              autovalidateMode ??
              (checks != null || validator != null || errorText != null
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled),
          style: theme.textTheme.bodyMedium,
          // Error borders/style come from the global InputDecorationTheme
          // so every input (text, date, dropdown) stays .
          decoration: InputDecoration(
            hintText: hint?.toUpperCase(),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
