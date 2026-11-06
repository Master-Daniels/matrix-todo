import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_spacing.dart';
import 'section_label.dart';

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// `03A/B` target date + exec time split cells. Taps are handled by the
/// parent sheet (owns the picker dialogs + state).
class DateTimeSection extends StatelessWidget {
  final DateTime date;
  final TimeOfDay? time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<DateTime>? onSelectDate;
  final VoidCallback? onClearTime;

  const DateTimeSection({
    super.key,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
    this.onSelectDate,
    this.onClearTime,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Date is required (REQ*): the sheet always holds a value (defaults to
    // today, picker clamps to today onwards), so the tag is informational.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(
          'Target date & time',
          right: 'Required',
          boldRight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (onSelectDate != null) ...[
          _QuickDateRow(
            currentDate: date,
            onSelect: onSelectDate!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DateTimeCell(
                    header: 'Target date',
                    mono:
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    value: _dateLabel(date),
                    icon: Icons.calendar_today,
                    onTap: onPickDate,
                  ),
                ),
                Container(width: 1, color: scheme.primary),
                Expanded(
                  child: _DateTimeCell(
                    header: 'Time',
                    mono: '24-HR LOCAL',
                    value: time == null
                        ? 'Set time'
                        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')} HRS',
                    icon: Icons.schedule,
                    onTap: onPickTime,
                    onClear: onClearTime,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final m = _months[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    return isToday ? 'TODAY, $m $day' : '$m $day, ${d.year}';
  }
}

class _DateTimeCell extends StatelessWidget {
  final String header;
  final String mono;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimeCell({
    required this.header,
    required this.mono,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: scheme.surfaceContainerLowest,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              header,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.primary, width: 1),
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mono,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          border: Border.all(color: scheme.primary, width: 1),
                        ),
                        child: Icon(Icons.close, size: 14, color: scheme.primary),
                      ),
                    )
                  else
                    Icon(icon, size: 18, color: scheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateRow extends StatelessWidget {
  final DateTime currentDate;
  final ValueChanged<DateTime> onSelect;

  const _QuickDateRow({
    required this.currentDate,
    required this.onSelect,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final in2Days = today.add(const Duration(days: 2));
    final nextWeek = today.add(const Duration(days: 7));

    final options = [
      (label: 'TODAY', date: today),
      (label: 'TOMORROW', date: tomorrow),
      (label: '+2 DAYS', date: in2Days),
      (label: 'NEXT WEEK', date: nextWeek),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: options.map((opt) {
        final isSelected = _isSameDay(currentDate, opt.date);
        return _QuickDateChip(
          label: opt.label,
          selected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.date);
          },
        );
      }).toList(),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          border: Border.all(
            color: scheme.primary,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          selected ? '■ $label' : label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? scheme.onPrimary : scheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
