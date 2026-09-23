import 'package:flutter/material.dart';

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

  const DateTimeSection({
    super.key,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
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
          '03 // Target date & time',
          right: 'REQ*',
          boldRight: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DateTimeCell(
                    header: '03A // Target Date',
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
                    header: '03B // Exec Time',
                    mono: '24-HR LOCAL',
                    value: time == null
                        ? 'TAP TO SET'
                        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')} HRS',
                    icon: Icons.schedule,
                    onTap: onPickTime,
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

  const _DateTimeCell({
    required this.header,
    required this.mono,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: scheme.surfaceContainerLowest,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              header.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.primary, width: 1),
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
                          mono.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
