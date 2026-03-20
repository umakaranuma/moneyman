import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _labelController;
  late TextEditingController _noteController;

  late ReminderRecurrence _recurrence;
  late DateTime _dueDate;
  int? _dueTimeHour;
  int? _dueTimeMinute;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _labelController = TextEditingController(text: r?.label ?? '');
    _noteController = TextEditingController(text: r?.note ?? '');

    _recurrence = r?.recurrence ?? ReminderRecurrence.daily;
    _dueDate = r?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTimeHour = r?.dueTimeHour;
    _dueTimeMinute = r?.dueTimeMinute;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final hour = _dueTimeHour ?? 9;
    final minute = _dueTimeMinute ?? 0;
    final initial = TimeOfDay(hour: hour, minute: minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueTimeHour = picked.hour;
        _dueTimeMinute = picked.minute;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final id = widget.reminder?.id ?? Helpers.generateId();
    final normalizedLabel = _labelController.text.trim();

    final reminder = Reminder(
      id: id,
      type: ReminderType.general,
      title: _titleController.text.trim(),
      label: normalizedLabel.isEmpty ? null : normalizedLabel,
      createdAt: widget.reminder?.createdAt ?? now,
      dueDate: _dueDate,
      dueTimeHour: _dueTimeHour,
      dueTimeMinute: _dueTimeMinute,
      recurrence: _recurrence,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (widget.reminder != null) {
      await ReminderService.updateReminder(reminder);
    } else {
      await ReminderService.addReminder(reminder);
    }
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          widget.reminder != null ? 'Edit reminder' : 'Add reminder',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Save',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _recurrenceChip(ReminderRecurrence.daily, 'Daily'),
                      _recurrenceChip(ReminderRecurrence.monthly, 'Monthly'),
                      _recurrenceChip(ReminderRecurrence.annually, 'Annually'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Pay internet bill',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  border: InputBorder.none,
                  labelText: 'Title',
                  labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a title';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: TextFormField(
                controller: _labelController,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Bills (optional)',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  border: InputBorder.none,
                  labelText: 'Label',
                  labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _dateTimeCard(
              label: 'Date & time',
              date: _dueDate,
              onDateTap: () {
                _pickDueDate(context);
              },
              showTime: true,
              timeLabel: _dueTimeHour != null
                  ? '${_dueTimeHour.toString().padLeft(2, '0')}:${(_dueTimeMinute ?? 0).toString().padLeft(2, '0')}'
                  : 'Set time',
              onTimeTap: () {
                _pickTime(context);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                _recurrence == ReminderRecurrence.daily
                    ? 'Daily reminders notify every day at the selected time.'
                    : 'You will be notified one day before and on the day at the selected time.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            _card(
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  border: InputBorder.none,
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recurrenceChip(ReminderRecurrence recurrence, String label) {
    final selected = _recurrence == recurrence;
    return GestureDetector(
      onTap: () => setState(() => _recurrence = recurrence),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: child,
    );
  }

  Widget _dateTimeCard({
    required String label,
    required DateTime date,
    required VoidCallback onDateTap,
    bool showTime = false,
    String? timeLabel,
    VoidCallback? onTimeTap,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd.MM.yyyy').format(date),
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showTime && onTimeTap != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onTimeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel ?? 'Time',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
