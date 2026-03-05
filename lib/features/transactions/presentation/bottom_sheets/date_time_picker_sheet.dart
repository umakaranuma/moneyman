import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

/// Date and time picker in a bottom sheet (no popup dialogs).
class DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onSelected;

  const DateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    required this.onSelected,
  });

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.initialDateTime;
  }

  void _onDone() {
    widget.onSelected(_dateTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _onDone,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CalendarDatePicker(
              initialDate: _dateTime,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              onDateChanged: (DateTime date) {
                final selected = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  _dateTime.hour,
                  _dateTime.minute,
                );
                widget.onSelected(selected);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onSelected;

  const TimePickerSheet({
    super.key,
    required this.initialDateTime,
    required this.onSelected,
  });

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.initialDateTime;
  }

  void _onDone() {
    widget.onSelected(_dateTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Time',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _onDone,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _dateTime,
                  use24hFormat:
                      MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: (DateTime value) {
                    setState(() {
                      _dateTime = DateTime(
                        _dateTime.year,
                        _dateTime.month,
                        _dateTime.day,
                        value.hour,
                        value.minute,
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
