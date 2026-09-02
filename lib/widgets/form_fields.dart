import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/app_colors.dart';

/// Tappable field that opens a date picker for a required date.
class DatePickerTile extends StatelessWidget {
  const DatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          dateFormat.format(date),
          style: const TextStyle(color: ink),
        ),
      ),
    );
  }
}

/// Same as [DatePickerTile] but the date may be absent and can be cleared.
class OptionalDatePickerTile extends StatelessWidget {
  const OptionalDatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2018),
          lastDate: DateTime(2038),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_available_outlined),
          suffixIcon: date == null
              ? null
              : IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(
          date == null ? 'Not detected' : dateFormat.format(date!),
          style: TextStyle(
            color: date == null ? ink.withValues(alpha: 0.52) : ink,
          ),
        ),
      ),
    );
  }
}
