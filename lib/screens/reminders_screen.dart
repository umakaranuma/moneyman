// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../core/router/app_router.dart';

class RemindersScreen extends StatefulWidget {
  /// When opened from a reminder notification tap, highlight this notification's reminder in the list.
  final int? highlightNotificationId;

  const RemindersScreen({super.key, this.highlightNotificationId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    setState(() {
      _reminders = ReminderService.getAllReminders();
    });
  }

  bool _isHighlighted(Reminder r) {
    final id = widget.highlightNotificationId;
    if (id == null) return false;
    return r.notificationIdDayBefore == id || r.notificationIdOnDay == id;
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete reminder',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove "${reminder.title}"? Notifications for this reminder will be cancelled.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderService.deleteReminder(reminder.id);
      _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final generalReminders = _reminders.where((r) => r.type == ReminderType.general).toList();
    final loanReminders = _reminders.where((r) => r.type == ReminderType.loan).toList();
    final packageReminders = _reminders.where((r) => r.type == ReminderType.package).toList();

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
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Reminders',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _reminders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async => _loadReminders(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (generalReminders.isNotEmpty) ...[
                    _sectionHeader('Reminders', Icons.notifications_active_rounded),
                    ...generalReminders.map((r) => _buildReminderCard(r, _isHighlighted(r))),
                  ],
                  if (loanReminders.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader('Loan reminders', Icons.account_balance_wallet_rounded),
                    ...loanReminders.map((r) => _buildReminderCard(r, _isHighlighted(r))),
                  ],
                  if (packageReminders.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader('Package / subscription', Icons.card_membership_rounded),
                    ...packageReminders.map((r) => _buildReminderCard(r, _isHighlighted(r))),
                  ],
                ],
              ),
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add loan due dates or package expiry reminders.\nYou\'ll get notified the day before and on the day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, bool isHighlighted) {
    final isGeneral = reminder.type == ReminderType.general;
    final isLoan = reminder.type == ReminderType.loan;
    final effectiveDate = reminder.effectiveDate;
    final isPast = effectiveDate != null && effectiveDate.isBefore(DateTime.now()) &&
        (effectiveDate.day != DateTime.now().day || effectiveDate.month != DateTime.now().month || effectiveDate.year != DateTime.now().year);

    Color borderColor = AppColors.surfaceVariant;
    if (isHighlighted) {
      borderColor = AppColors.primary;
    } else if (isPast) {
      borderColor = AppColors.textMuted.withValues(alpha: 0.3);
    } else if (isGeneral) {
      borderColor = AppColors.primary.withValues(alpha: 0.3);
    } else if (isLoan) {
      borderColor = AppColors.expense.withValues(alpha: 0.3);
    } else {
      borderColor = AppColors.secondary.withValues(alpha: 0.3);
    }

    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    if (isLoan) {
      icon = Icons.account_balance_wallet_rounded;
      iconColor = AppColors.expense;
    } else if (reminder.type == ReminderType.package) {
      icon = Icons.card_membership_rounded;
      iconColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.goToEditReminder(reminder);
            if (mounted) _loadReminders();
          },
          onLongPress: () => _deleteReminder(reminder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isHighlighted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_active_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Just notified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        reminder.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isGeneral && reminder.dueDate != null) ...[
                        Text(
                          '${DateFormat('dd.MM.yyyy').format(reminder.dueDate!)}'
                              '${reminder.dueTimeHour != null ? " at ${reminder.dueTimeHour!.toString().padLeft(2, '0')}:${(reminder.dueTimeMinute ?? 0).toString().padLeft(2, '0')}" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (reminder.note != null && reminder.note!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              reminder.note!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ] else if (isLoan && reminder.dueDate != null) ...[
                        Text(
                          'Due: ${DateFormat('dd.MM.yyyy').format(reminder.dueDate!)}'
                              '${reminder.dueTimeHour != null ? " at ${reminder.dueTimeHour!.toString().padLeft(2, '0')}:${(reminder.dueTimeMinute ?? 0).toString().padLeft(2, '0')}" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (reminder.loanAmount != null)
                          Text(
                            'Rs. ${reminder.loanAmount!.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.expense,
                            ),
                          ),
                      ] else if (reminder.type == ReminderType.package && reminder.expiryDate != null) ...[
                        Text(
                          'Expires: ${DateFormat('dd.MM.yyyy').format(reminder.expiryDate!)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (reminder.activationDate != null)
                          Text(
                            'Activated: ${DateFormat('dd.MM.yyyy').format(reminder.activationDate!)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await context.goToAddReminder();
        if (mounted) _loadReminders();
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Add reminder',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
