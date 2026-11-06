import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../data/task_dates.dart';
import '../../../theme/app_borders.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/checkbox.dart';
import 'section_label.dart';

/// Preset recurrence choices that 95% of users look for.
enum RecurrencePreset {
  none('Never'),
  daily('Daily'),
  weekdays('Weekdays'),
  weekly('Weekly'),
  monthly('Monthly'),
  custom('Custom...');

  final String label;
  const RecurrencePreset(this.label);
}

/// Simplified, layman-friendly recurrence section.
///
/// Features:
/// 1. Quick presets: Never, Daily, Weekdays (Mon–Fri), Weekly, Monthly, Custom.
/// 2. Natural language live summary ("Repeats every weekday at 09:00").
/// 3. Progressive disclosure: Custom options expand on demand rather than
///    overwhelming the user immediately.
/// 4. Friendly labels for monthly rules and end conditions.
class RecurrenceSection extends StatefulWidget {
  final RecurrenceRule? rule;
  final ValueChanged<RecurrenceRule?> onChange;

  const RecurrenceSection({
    super.key,
    this.rule,
    required this.onChange,
  });

  @override
  State<RecurrenceSection> createState() => _RecurrenceSectionState();
}

class _RecurrenceSectionState extends State<RecurrenceSection> {
  // Working copy of rule properties
  late String _frequency;
  late int _interval;
  late List<int> _weekdays;
  late int? _monthDay;
  late bool _monthLastDay;
  late int? _monthNth;
  late int? _monthNthWeekday;
  late DateTime _startDate;
  late String _endCondition; // 'never' | 'on_date'
  late DateTime? _endDate;
  late List<String> _times; // HH:MM 24h

  bool _customExpanded = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    if (r != null) {
      _frequency = r.frequency;
      _interval = r.interval;
      _weekdays = List<int>.from(r.weekdays);
      _monthDay = r.monthDay;
      _monthLastDay = r.monthLastDay;
      _monthNth = r.monthNth;
      _monthNthWeekday = r.monthNthWeekday;
      _startDate = tryParseDueDate(r.startDate) ?? DateTime.now();
      _endCondition = r.endCondition;
      _endDate = r.endDate != null ? tryParseDueDate(r.endDate!) : null;
      _times = List<String>.from(r.times.map((t) => t.timeOfDay));
      if (_times.isEmpty && _frequency != 'NONE') _times = ['09:00'];
      _customExpanded = _detectPreset() == RecurrencePreset.custom;
    } else {
      _frequency = 'NONE';
      _interval = 1;
      _weekdays = const [];
      _monthDay = null;
      _monthLastDay = false;
      _monthNth = null;
      _monthNthWeekday = null;
      _startDate = DateTime.now();
      _endCondition = 'never';
      _endDate = null;
      _times = const [];
      _customExpanded = false;
    }
  }

  RecurrencePreset _detectPreset() {
    if (_frequency == 'NONE') return RecurrencePreset.none;
    if (_frequency == 'DAILY' && _interval == 1) return RecurrencePreset.daily;
    if (_frequency == 'WEEKLY' &&
        _interval == 1 &&
        _weekdays.length == 5 &&
        _weekdays.contains(1) &&
        _weekdays.contains(2) &&
        _weekdays.contains(3) &&
        _weekdays.contains(4) &&
        _weekdays.contains(5)) {
      return RecurrencePreset.weekdays;
    }
    if (_frequency == 'WEEKLY' &&
        _interval == 1 &&
        (_weekdays.isEmpty || _weekdays.length == 1)) {
      return RecurrencePreset.weekly;
    }
    if (_frequency == 'MONTHLY' &&
        _interval == 1 &&
        !_monthLastDay &&
        _monthNth == null) {
      return RecurrencePreset.monthly;
    }
    return RecurrencePreset.custom;
  }

  void _applyPreset(RecurrencePreset preset) {
    setState(() {
      switch (preset) {
        case RecurrencePreset.none:
          _frequency = 'NONE';
          _interval = 1;
          _weekdays = const [];
          _monthDay = null;
          _monthLastDay = false;
          _monthNth = null;
          _monthNthWeekday = null;
          _times = const [];
          _customExpanded = false;
          break;
        case RecurrencePreset.daily:
          _frequency = 'DAILY';
          _interval = 1;
          _weekdays = const [];
          _monthDay = null;
          _monthLastDay = false;
          _monthNth = null;
          _monthNthWeekday = null;
          if (_times.isEmpty) _times = ['09:00'];
          _customExpanded = false;
          break;
        case RecurrencePreset.weekdays:
          _frequency = 'WEEKLY';
          _interval = 1;
          _weekdays = [1, 2, 3, 4, 5];
          _monthDay = null;
          _monthLastDay = false;
          _monthNth = null;
          _monthNthWeekday = null;
          if (_times.isEmpty) _times = ['09:00'];
          _customExpanded = false;
          break;
        case RecurrencePreset.weekly:
          _frequency = 'WEEKLY';
          _interval = 1;
          _weekdays = [_startDate.weekday];
          _monthDay = null;
          _monthLastDay = false;
          _monthNth = null;
          _monthNthWeekday = null;
          if (_times.isEmpty) _times = ['09:00'];
          _customExpanded = false;
          break;
        case RecurrencePreset.monthly:
          _frequency = 'MONTHLY';
          _interval = 1;
          _weekdays = const [];
          _monthDay = _startDate.day;
          _monthLastDay = false;
          _monthNth = null;
          _monthNthWeekday = null;
          if (_times.isEmpty) _times = ['09:00'];
          _customExpanded = false;
          break;
        case RecurrencePreset.custom:
          if (_frequency == 'NONE') {
            _frequency = 'WEEKLY';
            _interval = 1;
            _weekdays = [_startDate.weekday];
            if (_times.isEmpty) _times = ['09:00'];
          }
          _customExpanded = true;
          break;
      }
      _emit();
    });
  }

  RecurrenceRule _buildRule() {
    if (_frequency == 'NONE') {
      return RecurrenceRule(
        frequency: 'NONE',
        startDate: isoDay(_startDate),
        endCondition: 'never',
      );
    }
    return RecurrenceRule(
      frequency: _frequency,
      interval: _interval,
      weekdays: _weekdays,
      monthDay: _monthDay,
      monthLastDay: _monthLastDay,
      monthNth: _monthNth,
      monthNthWeekday: _monthNthWeekday,
      startDate: isoDay(_startDate),
      endDate: _endCondition == 'on_date' && _endDate != null
          ? isoDay(_endDate!)
          : null,
      endCondition: _endCondition,
      times: _times.map((t) => RecurrenceTime(timeOfDay: t)).toList(),
    );
  }

  void _emit() => widget.onChange(_buildRule());

  String _humanSummary() {
    if (_frequency == 'NONE') return 'Does not repeat';

    final buffer = StringBuffer('Repeats ');
    if (_frequency == 'DAILY') {
      buffer.write(_interval == 1 ? 'every day' : 'every $_interval days');
    } else if (_frequency == 'WEEKLY') {
      final isWeekdaysOnly = _interval == 1 &&
          _weekdays.length == 5 &&
          _weekdays.contains(1) &&
          _weekdays.contains(2) &&
          _weekdays.contains(3) &&
          _weekdays.contains(4) &&
          _weekdays.contains(5);

      if (isWeekdaysOnly) {
        buffer.write('every weekday (Mon–Fri)');
      } else {
        buffer.write(_interval == 1 ? 'weekly' : 'every $_interval weeks');
        if (_weekdays.isNotEmpty) {
          final names = _weekdays.map(RecurrenceRule.weekdayShort).join(', ');
          buffer.write(' on $names');
        }
      }
    } else if (_frequency == 'MONTHLY') {
      buffer.write(_interval == 1 ? 'monthly' : 'every $_interval months');
      if (_monthLastDay) {
        buffer.write(' on the last day');
      } else if (_monthNth != null && _monthNthWeekday != null) {
        buffer.write(
          ' on the ${_ordinalName(_monthNth!)} ${RecurrenceRule.weekdayShort(_monthNthWeekday!)}',
        );
      } else if (_monthDay != null) {
        buffer.write(' on day $_monthDay');
      }
    }

    if (_times.isNotEmpty) {
      buffer.write(' at ${_times.join(', ')}');
    }
    if (_endCondition == 'on_date' && _endDate != null) {
      buffer.write(' until ${_formatShortDate(_endDate!)}');
    }
    return buffer.toString();
  }

  static String _ordinalName(int n) {
    switch (n) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      case 4:
        return '4th';
      case 5:
        return '5th';
      default:
        return '${n}th';
    }
  }

  static String _formatShortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickTime({int? replaceIndex}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: replaceIndex != null && replaceIndex < _times.length
          ? _parseTime(_times[replaceIndex])
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (replaceIndex != null && replaceIndex < _times.length) {
        _times = List<String>.from(_times)..[replaceIndex] = time;
      } else {
        _times = List<String>.from(_times)..add(time);
        _times.sort();
      }
      _emit();
    });
  }

  void _removeTime(int index) {
    setState(() {
      _times = List<String>.from(_times)..removeAt(index);
      _emit();
    });
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activePreset = _detectPreset();
    final isRecurring = _frequency != 'NONE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main container with presets and summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
            borderRadius: AppBorders.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              SectionLabel(
                'Repeat',
                right: activePreset.label,
                boldRight: true,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Presets selector row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: RecurrencePreset.values.map((preset) {
                  final isSelected = activePreset == preset;
                  return GestureDetector(
                    onTap: () => _applyPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : scheme.surface,
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        borderRadius: AppBorders.zero,
                      ),
                      child: Text(
                        isSelected ? '${preset.label} ■' : preset.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.primary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFamily: 'Space Mono',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Human-readable summary + customize toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _humanSummary(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.secondary,
                        fontFamily: 'Space Mono',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (isRecurring) ...[
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _customExpanded = !_customExpanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _customExpanded ? 'Less' : 'Adjust',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontFamily: 'Space Mono',
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            _customExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Custom / Advanced editor panel
        if (isRecurring && _customExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1),
              borderRadius: AppBorders.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Repeat every X [days/weeks/months]" natural sentence
                const SectionLabel('Frequency', right: 'Repeat every'),
                const SizedBox(height: AppSpacing.xs),
                _IntervalSentenceRow(
                  interval: _interval,
                  frequency: _frequency,
                  onIntervalChange: (val) {
                    setState(() {
                      _interval = val;
                      _emit();
                    });
                  },
                  onFrequencyChange: (freq) {
                    setState(() {
                      _frequency = freq;
                      if (freq == 'WEEKLY' && _weekdays.isEmpty) {
                        _weekdays = [_startDate.weekday];
                      }
                      if (freq == 'MONTHLY' &&
                          _monthDay == null &&
                          !_monthLastDay &&
                          _monthNth == null) {
                        _monthDay = _startDate.day;
                      }
                      _emit();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Weekday picker (Weekly only)
                if (_frequency == 'WEEKLY') ...[
                  const SectionLabel('On days', right: 'Select days'),
                  const SizedBox(height: AppSpacing.xs),
                  _WeekdayPicker(
                    selected: _weekdays,
                    onToggle: (day) {
                      setState(() {
                        if (_weekdays.contains(day)) {
                          if (_weekdays.length > 1) {
                            _weekdays = List<int>.from(_weekdays)..remove(day);
                          }
                        } else {
                          _weekdays = List<int>.from(_weekdays)..add(day);
                          _weekdays.sort();
                        }
                        _emit();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Monthly options (Monthly only)
                if (_frequency == 'MONTHLY') ...[
                  const SectionLabel('Monthly rule', right: 'Repeat on'),
                  const SizedBox(height: AppSpacing.xs),
                  _FriendlyMonthlyOptions(
                    startDate: _startDate,
                    monthDay: _monthDay,
                    monthLastDay: _monthLastDay,
                    monthNth: _monthNth,
                    monthNthWeekday: _monthNthWeekday,
                    onChange: ({
                      int? day,
                      bool? lastDay,
                      int? nth,
                      int? nthWeekday,
                    }) {
                      setState(() {
                        _monthDay = day;
                        _monthLastDay = lastDay ?? false;
                        _monthNth = nth;
                        _monthNthWeekday = nthWeekday;
                        _emit();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Ends condition
                const SectionLabel('Ends', right: 'Condition'),
                const SizedBox(height: AppSpacing.xs),
                _FriendlyEndConditionRow(
                  condition: _endCondition,
                  endDate: _endDate,
                  onChange: (cond, date) {
                    setState(() {
                      _endCondition = cond;
                      _endDate = date;
                      _emit();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Specific times per repeat
                const SectionLabel('Times', right: 'Alert times'),
                const SizedBox(height: AppSpacing.xs),
                _TimesRow(
                  times: _times,
                  onPick: _pickTime,
                  onRemove: _removeTime,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Natural Language & Layman-friendly Subwidgets
// ---------------------------------------------------------------------------

/// Sentence builder: `[ - ] [ 1 ] [ + ]` `[ Days ] [ Weeks ] [ Months ]`
class _IntervalSentenceRow extends StatelessWidget {
  final int interval;
  final String frequency; // 'DAILY' | 'WEEKLY' | 'MONTHLY'
  final ValueChanged<int> onIntervalChange;
  final ValueChanged<String> onFrequencyChange;

  const _IntervalSentenceRow({
    required this.interval,
    required this.frequency,
    required this.onIntervalChange,
    required this.onFrequencyChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = [
      ('DAILY', interval == 1 ? 'Day' : 'Days'),
      ('WEEKLY', interval == 1 ? 'Week' : 'Weeks'),
      ('MONTHLY', interval == 1 ? 'Month' : 'Months'),
    ];

    return Row(
      children: [
        // Number Stepper
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary, width: 1),
            borderRadius: AppBorders.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: interval > 1 ? () => onIntervalChange(interval - 1) : null,
              ),
              Container(width: 1, height: 36, color: scheme.primary),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                alignment: Alignment.center,
                child: Text(
                  '$interval',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Space Mono',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: scheme.primary),
              _StepperButton(
                icon: Icons.add,
                onTap: interval < 99 ? () => onIntervalChange(interval + 1) : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Unit selector tabs (Day / Week / Month)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1),
              borderRadius: AppBorders.zero,
            ),
            child: Row(
              children: units.map((u) {
                final isSelected = frequency == u.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onFrequencyChange(u.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : scheme.surface,
                        borderRadius: AppBorders.zero,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        u.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.primary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFamily: 'Space Mono',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        color: onTap != null ? scheme.primary : scheme.surfaceContainerLowest,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? scheme.onPrimary
              : scheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// 7-day row for weekday selection: Mon, Tue, Wed, Thu, Fri, Sat, Sun.
class _WeekdayPicker extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<int> onToggle;

  const _WeekdayPicker({
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const days = [1, 2, 3, 4, 5, 6, 7];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: AppBorders.zero,
      ),
      child: Row(
        children: days.map((day) {
          final isSelected = selected.contains(day);
          final isLast = day == 7;
          return Expanded(
            child: GestureDetector(
              onTap: () => onToggle(day),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : scheme.surface,
                  border: isLast
                      ? null
                      : Border(
                          right: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  RecurrenceRule.weekdayShort(day),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? scheme.onPrimary : scheme.primary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontFamily: 'Space Mono',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Clear human-readable monthly choices
class _FriendlyMonthlyOptions extends StatelessWidget {
  final DateTime startDate;
  final int? monthDay;
  final bool monthLastDay;
  final int? monthNth;
  final int? monthNthWeekday;
  final void Function({
    int? day,
    bool? lastDay,
    int? nth,
    int? nthWeekday,
  }) onChange;

  const _FriendlyMonthlyOptions({
    required this.startDate,
    required this.monthDay,
    required this.monthLastDay,
    required this.monthNth,
    required this.monthNthWeekday,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final currentDay = monthDay ?? startDate.day;
    final isFixedDay = !monthLastDay && monthNth == null;
    final isLastDay = monthLastDay;
    final isNthWeekday = monthNth != null && monthNthWeekday != null;

    final nthVal = monthNth ?? ((startDate.day - 1) ~/ 7 + 1);
    final nthDayVal = monthNthWeekday ?? startDate.weekday;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: AppBorders.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option 1: On day X each month
          _RadioOptionRow(
            title: 'On day $currentDay each month',
            isSelected: isFixedDay,
            onTap: () => onChange(day: currentDay, lastDay: false, nth: null, nthWeekday: null),
          ),
          if (isFixedDay) ...[
            Container(height: 1, color: scheme.primary.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    'Change day:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Space Mono',
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StepperButton(
                    icon: Icons.remove,
                    onTap: currentDay > 1
                        ? () => onChange(
                              day: currentDay - 1,
                              lastDay: false,
                              nth: null,
                              nthWeekday: null,
                            )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$currentDay',
                      style: const TextStyle(
                        fontFamily: 'Space Mono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add,
                    onTap: currentDay < 31
                        ? () => onChange(
                              day: currentDay + 1,
                              lastDay: false,
                              nth: null,
                              nthWeekday: null,
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ],

          Container(height: 1, color: scheme.primary.withValues(alpha: 0.3)),

          // Option 2: On the last day of each month
          _RadioOptionRow(
            title: 'On the last day of each month',
            isSelected: isLastDay,
            onTap: () => onChange(day: null, lastDay: true, nth: null, nthWeekday: null),
          ),

          Container(height: 1, color: scheme.primary.withValues(alpha: 0.3)),

          // Option 3: On the Nth weekday
          _RadioOptionRow(
            title:
                'On the ${_nthName(nthVal)} ${RecurrenceRule.weekdayShort(nthDayVal)} each month',
            isSelected: isNthWeekday,
            onTap: () => onChange(
              day: null,
              lastDay: false,
              nth: nthVal,
              nthWeekday: nthDayVal,
            ),
          ),
          if (isNthWeekday) ...[
            Container(height: 1, color: scheme.primary.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nth selector (1st..5th)
                  Wrap(
                    spacing: 4,
                    children: [1, 2, 3, 4, 5].map((n) {
                      final active = nthVal == n;
                      return GestureDetector(
                        onTap: () => onChange(
                          day: null,
                          lastDay: false,
                          nth: n,
                          nthWeekday: nthDayVal,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: active ? scheme.primary : scheme.surface,
                            border: Border.all(color: scheme.primary, width: 1),
                          ),
                          child: Text(
                            _nthName(n),
                            style: TextStyle(
                              color: active ? scheme.onPrimary : scheme.primary,
                              fontFamily: 'Space Mono',
                              fontSize: 10,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  // Weekday selector
                  _WeekdayPicker(
                    selected: [nthDayVal],
                    onToggle: (w) => onChange(
                      day: null,
                      lastDay: false,
                      nth: nthVal,
                      nthWeekday: w,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _nthName(int n) {
    switch (n) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      case 4:
        return '4th';
      case 5:
        return '5th';
      default:
        return '${n}th';
    }
  }
}

class _RadioOptionRow extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioOptionRow({
    required this.title,
    required this.isSelected,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        color: isSelected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
        child: Row(
          children: [
            CustomCheckbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              inverted: false,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'Space Mono',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simplified end condition: Never vs On date
class _FriendlyEndConditionRow extends StatelessWidget {
  final String condition; // 'never' | 'on_date'
  final DateTime? endDate;
  final void Function(String condition, DateTime? date) onChange;

  const _FriendlyEndConditionRow({
    required this.condition,
    required this.endDate,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNever = condition == 'never';

    final effectiveDate = endDate ?? DateTime.now().add(const Duration(days: 30));
    final dateLabel =
        '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: AppBorders.zero,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Never button
              Expanded(
                child: GestureDetector(
                  onTap: () => onChange('never', null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isNever ? scheme.primary : scheme.surface,
                      borderRadius: AppBorders.zero,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isNever ? 'Never ■' : 'Never',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isNever ? scheme.onPrimary : scheme.primary,
                        fontWeight: isNever ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'Space Mono',
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: scheme.primary),
              // On date button
              Expanded(
                child: GestureDetector(
                  onTap: () => onChange('on_date', effectiveDate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isNever ? scheme.primary : scheme.surface,
                      borderRadius: AppBorders.zero,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      !isNever ? 'On date ■' : 'On date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: !isNever ? scheme.onPrimary : scheme.primary,
                        fontWeight: !isNever ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'Space Mono',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (!isNever) ...[
            Container(height: 1, color: scheme.primary),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: effectiveDate.isBefore(now) ? now : effectiveDate,
                  firstDate: now,
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  onChange('on_date', picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: scheme.surface,
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'End date: $dateLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Space Mono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Editable list of times per day (HH:MM).
class _TimesRow extends StatelessWidget {
  final List<String> times;
  final Future<void> Function({int? replaceIndex}) onPick;
  final void Function(int index) onRemove;

  const _TimesRow({
    required this.times,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: AppBorders.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (times.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                'Defaults to task time if none added.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontFamily: 'Space Mono',
                  fontSize: 10,
                ),
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < times.length; i++)
                _TimeChip(
                  time: times[i],
                  onTap: () => onPick(replaceIndex: i),
                  onDelete: () => onRemove(i),
                ),
              GestureDetector(
                onTap: () => onPick(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppBorders.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add time',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Space Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TimeChip({
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.primary, width: 1),
          borderRadius: AppBorders.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: scheme.primary,
                fontFamily: 'Space Mono',
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 14,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
