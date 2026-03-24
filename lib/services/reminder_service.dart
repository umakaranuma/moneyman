import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../utils/helpers.dart';

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

  /// Schedules notifications:
  /// - general daily = repeats every day at selected time
  /// - general monthly/annually = day-before + on-day at selected time
  /// - loan = day-before + on-day
  /// - package = day-before expiry
  static Future<Reminder> scheduleNotificationsForReminder(
    Reminder reminder,
  ) async {
    await _cancelReminderNotifications(reminder);

    // General reminder recurrence scheduling.
    if (reminder.type == ReminderType.general) {
      final due = reminder.dueDate;
      if (due == null) return reminder;
      final hour = reminder.dueTimeHour ?? 9;
      final minute = reminder.dueTimeMinute ?? 0;
      final recurrence = reminder.recurrence;

      if (recurrence == ReminderRecurrence.daily) {
        final now = DateTime.now();
        var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        scheduled = _normalizeRecurringStart(
          scheduled,
          ReminderRecurrence.daily,
        );
        final id = _nextId();
        final body = (reminder.note ?? reminder.title).trim().isNotEmpty
            ? (reminder.note ?? reminder.title)
            : 'Reminder: ${reminder.title}';
        final bigText = StringBuffer()
          ..writeln('Repeats: Daily at ${_formatTime(hour, minute)}')
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
              subText: 'Finzo • Daily',
              largeIconDrawable: 'ic_notification_256',
              matchDateTimeComponents: DateTimeComponents.time,
            );
        return reminder.copyWith(
          notificationIdDayBefore: scheduledOk ? id : null,
          notificationIdOnDay: null,
        );
      }

      int? idDayBefore;
      int? idOnDay;
      final onDayScheduled = _normalizeRecurringStart(
        DateTime(due.year, due.month, due.day, hour, minute),
        recurrence,
      );
      final dayBefore = _normalizeRecurringStart(
        onDayScheduled.subtract(const Duration(days: 1)),
        recurrence,
      );
      final repeatType = recurrence == ReminderRecurrence.monthly
          ? 'Monthly'
          : 'Annual';
      final repeatComponents = recurrence == ReminderRecurrence.monthly
          ? DateTimeComponents.dayOfMonthAndTime
          : DateTimeComponents.dateAndTime;

      idDayBefore = _nextId();
      final scheduledDayBefore =
          await NotificationService.scheduleReminderNotification(
            notificationId: idDayBefore,
            title: '⏰ ${reminder.title} is tomorrow',
            body:
                '${reminder.title} reminder is tomorrow at ${_formatTime(hour, minute)}.',
            scheduledDate: dayBefore,
            bigText:
                'Reminder: ${reminder.title}\n'
                'Repeats: $repeatType\n'
                'Next alert: tomorrow at ${_formatTime(hour, minute)}',
            subText: 'Finzo • $repeatType',
            largeIconDrawable: 'ic_notification_256',
            matchDateTimeComponents: repeatComponents,
          );
      if (!scheduledDayBefore) idDayBefore = null;

      idOnDay = _nextId();
      final scheduledOnDay = await NotificationService.scheduleReminderNotification(
        notificationId: idOnDay,
        title: '🔔 ${reminder.title}',
        body:
            '${reminder.title} reminder is now (${_formatTime(hour, minute)}).',
        scheduledDate: onDayScheduled,
        bigText:
            'Reminder: ${reminder.title}\n'
            'Repeats: $repeatType\n'
            'Time: ${_formatTime(hour, minute)}',
        subText: 'Finzo • $repeatType',
        largeIconDrawable: 'ic_notification_256',
        matchDateTimeComponents: repeatComponents,
      );
      if (!scheduledOnDay) idOnDay = null;

      return reminder.copyWith(
        notificationIdDayBefore: idDayBefore,
        notificationIdOnDay: idOnDay,
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
          ? 'Amount: ${_currency(reminder.loanAmount!)}\n\n'
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
          ? 'Amount: ${_currency(reminder.loanAmount!)}\n\n'
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

  static String _currency(double value) => Helpers.formatCurrency(value);

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static String _formatTime(int h, int m) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  static DateTime _normalizeRecurringStart(
    DateTime scheduled,
    ReminderRecurrence recurrence,
  ) {
    final now = DateTime.now();
    if (!scheduled.isBefore(now)) return scheduled;

    if (_isSameMinute(scheduled, now)) {
      return now.add(const Duration(seconds: 5));
    }

    if (recurrence == ReminderRecurrence.daily) {
      while (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    if (recurrence == ReminderRecurrence.monthly) {
      while (!scheduled.isAfter(now)) {
        scheduled = DateTime(
          scheduled.year,
          scheduled.month + 1,
          scheduled.day,
          scheduled.hour,
          scheduled.minute,
        );
      }
      return scheduled;
    }

    while (!scheduled.isAfter(now)) {
      scheduled = DateTime(
        scheduled.year + 1,
        scheduled.month,
        scheduled.day,
        scheduled.hour,
        scheduled.minute,
      );
    }
    return scheduled;
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
