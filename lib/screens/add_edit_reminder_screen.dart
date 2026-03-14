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
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late ReminderType _type;
  late DateTime _dueDate;
  int? _dueTimeHour;
  int? _dueTimeMinute;
  late DateTime _activationDate;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _amountController = TextEditingController(
      text: r?.loanAmount != null ? r!.loanAmount!.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: r?.note ?? '');

    _type = r?.type ?? ReminderType.general;
    _dueDate = r?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTimeHour = r?.dueTimeHour;
    _dueTimeMinute = r?.dueTimeMinute;
    _activationDate = r?.activationDate ?? DateTime.now();
    _expiryDate = r?.expiryDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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

  Future<void> _pickActivationDate(BuildContext context) async {
    final p = await showDatePicker(
      context: context,
      initialDate: _activationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (p != null && mounted) setState(() => _activationDate = p);
  }

  Future<void> _pickExpiryDate(BuildContext context) async {
    final p = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: _activationDate,
      lastDate: DateTime(2100),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (p != null && mounted) setState(() => _expiryDate = p);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final id = widget.reminder?.id ?? Helpers.generateId();

    double? amount;
    if (_type == ReminderType.loan && _amountController.text.trim().isNotEmpty) {
      amount = double.tryParse(_amountController.text.trim());
    }

    final reminder = Reminder(
      id: id,
      type: _type,
      title: _titleController.text.trim(),
      createdAt: widget.reminder?.createdAt ?? now,
      dueDate: _type == ReminderType.general || _type == ReminderType.loan ? _dueDate : null,
      dueTimeHour: _type == ReminderType.general || _type == ReminderType.loan ? _dueTimeHour : null,
      dueTimeMinute: _type == ReminderType.general || _type == ReminderType.loan ? _dueTimeMinute : null,
      loanAmount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      activationDate: _type == ReminderType.package ? _activationDate : null,
      expiryDate: _type == ReminderType.package ? _expiryDate : null,
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
            // Type selector
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type',
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
                      _typeChip(ReminderType.general, 'Date & time'),
                      _typeChip(ReminderType.loan, 'Loan due date'),
                      _typeChip(ReminderType.package, 'Package'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            _card(
              child: TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: _type == ReminderType.general
                      ? 'e.g. Call mom'
                      : _type == ReminderType.loan
                          ? 'e.g. John\'s loan'
                          : 'e.g. Cursor subscription',
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

            if (_type == ReminderType.general) ...[
              _dateTimeCard(
                label: 'Date & time',
                date: _dueDate,
                onDateTap: () { _pickDueDate(context); },
                showTime: true,
                timeLabel: _dueTimeHour != null
                    ? '${_dueTimeHour.toString().padLeft(2, '0')}:${(_dueTimeMinute ?? 0).toString().padLeft(2, '0')}'
                    : 'Set time',
                onTimeTap: () { _pickTime(context); },
              ),
              const SizedBox(height: 16),
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
            ] else if (_type == ReminderType.loan) ...[
              _dateTimeCard(
                label: 'Due date',
                date: _dueDate,
                onDateTap: () { _pickDueDate(context); },
                showTime: true,
                timeLabel: _dueTimeHour != null
                    ? '${_dueTimeHour.toString().padLeft(2, '0')}:${(_dueTimeMinute ?? 0).toString().padLeft(2, '0')}'
                    : 'Set time (optional)',
                onTimeTap: () { _pickTime(context); },
              ),
              const SizedBox(height: 16),
              _card(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Loan amount (optional)',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    border: InputBorder.none,
                    prefixText: 'Rs. ',
                    prefixStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ] else ...[
              _dateTimeCard(
                label: 'Activated on',
                date: _activationDate,
                onDateTap: () { _pickActivationDate(context); },
              ),
              const SizedBox(height: 12),
              _dateTimeCard(
                label: 'Expires on',
                date: _expiryDate,
                onDateTap: () { _pickExpiryDate(context); },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'You\'ll get a notification the day before expiry: "Your [title] was activated on [date], it will expire tomorrow – renew or activate."',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeChip(ReminderType type, String label) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
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
