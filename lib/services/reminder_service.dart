import 'dart:developer' as developer;
import '../models/reminder.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ReminderService {
  /// Base ID for user reminder notifications (must not clash with 1, 2 used by app).
  static const int _reminderNotificationIdBase = 10000;
  static int _nextNotificationId = _reminderNotificationIdBase;
  static bool _idInitialized = false;

  static int _nextId() {
    if (!_idInitialized) {
      _idInitialized = true;
      int maxId = _reminderNotificationIdBase - 1;
      for (final r in StorageService.getAllReminders()) {
        if (r.notificationIdDayBefore != null &&
            r.notificationIdDayBefore! > maxId) {
          maxId = r.notificationIdDayBefore!;
        }
        if (r.notificationIdOnDay != null && r.notificationIdOnDay! > maxId) {
          maxId = r.notificationIdOnDay!;
        }
      }
      _nextNotificationId = maxId + 1;
    }
    return _nextNotificationId++;
  }

  static List<Reminder> getAllReminders() {
    return StorageService.getAllReminders();
  }

  static Reminder? getReminder(String id) {
    return StorageService.getReminder(id);
  }

  static Future<void> _cancelReminderNotifications(Reminder reminder) async {
    if (reminder.notificationIdDayBefore != null) {
      await NotificationService.cancelReminderNotification(
        reminder.notificationIdDayBefore!,
      );
    }
    if (reminder.notificationIdOnDay != null) {
      await NotificationService.cancelReminderNotification(
        reminder.notificationIdOnDay!,
      );
    }
  }

  /// Schedules notifications: for general = one at date+time; for loan = day-before + on-day; for package = day-before expiry.
  static Future<Reminder> scheduleNotificationsForReminder(
    Reminder reminder,
  ) async {
    await _cancelReminderNotifications(reminder);

    // General reminder: single notification at the chosen date and time
    if (reminder.type == ReminderType.general) {
      final due = reminder.dueDate;
      if (due == null) return reminder;
      final hour = reminder.dueTimeHour ?? 9;
      final minute = reminder.dueTimeMinute ?? 0;
      final scheduled = DateTime(due.year, due.month, due.day, hour, minute);
      final id = _nextId();
      final dateStr = _formatDate(due);
      final timeStr = _formatTime(hour, minute);
      final body = (reminder.note ?? reminder.title).trim().isNotEmpty
          ? (reminder.note ?? reminder.title)
          : 'Reminder: ${reminder.title}';
      final bigText = StringBuffer()
        ..writeln('When: $dateStr at $timeStr')
        ..writeln()
        ..write(
          reminder.note?.trim().isNotEmpty == true
              ? 'Note: ${reminder.note}'
              : 'Reminder: ${reminder.title}',
        );
      final scheduledOk =
          await NotificationService.scheduleReminderNotification(
            notificationId: id,
            title: '🔔 ${reminder.title}',
            body: body,
            scheduledDate: scheduled,
            bigText: bigText.toString(),
            subText: 'Finzo • Reminder',
            largeIconDrawable: 'ic_notification_256',
          );
      return reminder.copyWith(
        notificationIdDayBefore: scheduledOk ? id : null,
        notificationIdOnDay: null,
      );
    }

    final effectiveDate = reminder.effectiveDate;
    if (effectiveDate == null) return reminder;

    final localDate = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    int hour = 9;
    int minute = 0;
    if (reminder.type == ReminderType.loan &&
        reminder.dueTimeHour != null &&
        reminder.dueTimeMinute != null) {
      hour = reminder.dueTimeHour!;
      minute = reminder.dueTimeMinute!;
    }

    int? idDayBefore;
    int? idOnDay;

    // Day before: same time or 9:00 AM
    final dayBefore = localDate.subtract(const Duration(days: 1));
    final dayBeforeScheduled = DateTime(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      hour,
      minute,
    );

    String titleDayBefore;
    String bodyDayBefore;
    String bigTextDayBefore;
    if (reminder.type == ReminderType.loan) {
      titleDayBefore = '💰 Loan due tomorrow';
      bodyDayBefore =
          '${reminder.title} is due tomorrow at ${_formatTime(hour, minute)}. Don\'t forget to repay.';
      final amountLine = reminder.loanAmount != null
          ? 'Amount: Rs. ${reminder.loanAmount!.toStringAsFixed(0)}\n\n'
          : '';
      bigTextDayBefore =
          'Loan: ${reminder.title}\n'
          'Due: ${_formatDate(reminder.dueDate!)} at ${_formatTime(hour, minute)}\n\n'
          '$amountLine'
          'Don\'t forget to repay on time.';
    } else {
      titleDayBefore = '📦 ${reminder.title} expires tomorrow';
      bodyDayBefore =
          'Your ${reminder.title} will expire tomorrow. Renew or activate to avoid interruption.';
      final activatedLine = reminder.activationDate != null
          ? 'Activated on ${_formatDate(reminder.activationDate!)}.\n\n'
          : '';
      bigTextDayBefore =
          'Package: ${reminder.title}\n'
          'Expires: ${_formatDate(reminder.expiryDate!)}\n\n'
          '$activatedLine'
          'Renew or activate to avoid interruption.';
    }

    idDayBefore = _nextId();
    final scheduledDayBefore =
        await NotificationService.scheduleReminderNotification(
          notificationId: idDayBefore,
          title: titleDayBefore,
          body: bodyDayBefore,
          scheduledDate: dayBeforeScheduled,
          bigText: bigTextDayBefore,
          subText: reminder.type == ReminderType.loan
              ? 'Finzo • Loan'
              : 'Finzo • Package',
          largeIconDrawable: 'ic_notification_256',
        );
    if (!scheduledDayBefore) idDayBefore = null;

    // On the day: only for loan (full reminder + alarm-like)
    if (reminder.type == ReminderType.loan) {
      final onDayScheduled = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        hour,
        minute,
      );
      final amountLineOnDay = reminder.loanAmount != null
          ? 'Amount: Rs. ${reminder.loanAmount!.toStringAsFixed(0)}\n\n'
          : '';
      final bigTextOnDay =
          'Loan: ${reminder.title}\n'
          'Due today at ${_formatTime(hour, minute)}\n\n'
          '$amountLineOnDay'
          'Please repay as scheduled.';
      idOnDay = _nextId();
      final scheduledOnDay = await NotificationService.scheduleReminderNotification(
        notificationId: idOnDay,
        title: '⚠️ Loan due today – ${reminder.title}',
        body:
            '${reminder.title} is due today at ${_formatTime(hour, minute)}. Please repay as scheduled.',
        scheduledDate: onDayScheduled,
        bigText: bigTextOnDay,
        subText: 'Finzo • Loan',
        largeIconDrawable: 'ic_notification_256',
      );
      if (!scheduledOnDay) idOnDay = null;
    }

    return reminder.copyWith(
      notificationIdDayBefore: idDayBefore,
      notificationIdOnDay: idOnDay,
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static String _formatTime(int h, int m) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static Future<void> addReminder(Reminder reminder) async {
    final withNotifications = await scheduleNotificationsForReminder(reminder);
    await StorageService.addReminder(withNotifications);
    developer.log(
      'Added reminder ${reminder.id} (${reminder.type.name})',
      name: 'ReminderService',
    );
  }

  static Future<void> updateReminder(Reminder reminder) async {
    final withNotifications = await scheduleNotificationsForReminder(reminder);
    await StorageService.updateReminder(withNotifications);
    developer.log('Updated reminder ${reminder.id}', name: 'ReminderService');
  }

  static Future<void> deleteReminder(String id) async {
    final reminder = StorageService.getReminder(id);
    if (reminder != null) {
      await _cancelReminderNotifications(reminder);
    }
    await StorageService.deleteReminder(id);
    developer.log('Deleted reminder $id', name: 'ReminderService');
  }
}
