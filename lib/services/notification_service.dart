import 'dart:developer' as developer;
import 'dart:typed_data' show Int64List;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

// Top-level function for background notification handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Background notification tap handler
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int moneyManagerReminderId = 1;
  static const int todoListReminderId = 2;

  // Notification Channel IDs
  static const String moneyManagerChannelId = 'money_manager_reminder';
  static const String todoListChannelId = 'todo_list_reminder';
  static const String remindersChannelId = 'reminders';

  /// Dedicated channel for alarm-style reminder sound & vibration (Android 8+ ties these to the channel).
  static const String remindersAlarmChannelId = 'reminders_alarm';

  static Future<void> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Set timezone - try Asia/Colombo first (Sri Lankan time)
      // This is reliable and works in both debug and release builds
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
        developer.log(
          'Timezone set to Asia/Colombo (Sri Lankan time)',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log(
          'Error setting Asia/Colombo timezone, trying UTC: $e',
          name: 'NotificationService',
        );
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
          developer.log(
            'Timezone set to UTC as fallback',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'UTC fallback also failed: $e2',
            name: 'NotificationService',
          );
        }
      }

      // Android initialization settings
      // Small icon: monochrome white (status bar / notification header)
      const androidSettings = AndroidInitializationSettings(
        'ic_notification_white',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized != true) {
        developer.log(
          'Notification initialization failed',
          name: 'NotificationService',
        );
        return;
      }

      developer.log(
        'Notification plugin initialized successfully',
        name: 'NotificationService',
      );

      // Create notification channels AFTER initialization
      await _createNotificationChannels();
      developer.log(
        'Notification channels created',
        name: 'NotificationService',
      );

      // Request notification permissions
      final hasPermission = await _requestPermissions();

      if (hasPermission) {
        developer.log(
          'Notification permission granted, scheduling notifications',
          name: 'NotificationService',
        );

        // Wait a bit to ensure permission is fully processed
        await Future.delayed(const Duration(milliseconds: 300));

        await scheduleDefaultNotifications();
        await checkAndTriggerMissedNotifications();

        // Verify notifications were scheduled
        await Future.delayed(const Duration(milliseconds: 500));
        final pending = await _notifications.pendingNotificationRequests();
        developer.log(
          'Notifications scheduled: ${pending.length} pending',
          name: 'NotificationService',
        );

        if (pending.isEmpty) {
          developer.log(
            'WARNING: No pending notifications found after scheduling!',
            name: 'NotificationService',
          );
          // Try rescheduling once more
          await Future.delayed(const Duration(milliseconds: 500));
          await scheduleDefaultNotifications();
          final pendingRetry = await _notifications
              .pendingNotificationRequests();
          developer.log(
            'After retry: ${pendingRetry.length} pending notifications',
            name: 'NotificationService',
          );
        }

        for (var notification in pending) {
          developer.log(
            'Pending notification: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}',
            name: 'NotificationService',
          );
        }
      } else {
        developer.log(
          'Notification permission denied',
          name: 'NotificationService',
        );
      }
    } catch (e) {
      developer.log(
        'Error initializing notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    try {
      const moneyManagerChannel = AndroidNotificationChannel(
        moneyManagerChannelId,
        'Money Manager Reminder',
        description: 'Daily reminder to update your money manager',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const todoListChannel = AndroidNotificationChannel(
        todoListChannelId,
        'Todo List Reminder',
        description: 'Daily reminder to create your todo list',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const remindersChannel = AndroidNotificationChannel(
        remindersChannelId,
        'Reminders',
        description: 'Alarm-style reminders – full screen, sound & vibration',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Alarm-style channel: sound and vibration are set at channel level on Android 8+.
      final alarmVibrationPattern = Int64List.fromList([
        0,
        1000,
        500,
        1000,
        500,
        1000,
      ]);
      final remindersAlarmChannel = AndroidNotificationChannel(
        remindersAlarmChannelId,
        'Reminder alarms',
        description: 'Rings like an alarm – use for important reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        vibrationPattern: alarmVibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          moneyManagerChannel,
        );
        developer.log(
          'Created money manager notification channel',
          name: 'NotificationService',
        );

        await androidImplementation.createNotificationChannel(todoListChannel);
        developer.log(
          'Created todo list notification channel',
          name: 'NotificationService',
        );
        await androidImplementation.createNotificationChannel(remindersChannel);
        developer.log(
          'Created reminders notification channel',
          name: 'NotificationService',
        );
        await androidImplementation.createNotificationChannel(
          remindersAlarmChannel,
        );
        developer.log(
          'Created reminders alarm channel (alarm sound & vibration)',
          name: 'NotificationService',
        );
      } else {
        developer.log(
          'Android implementation not available for channel creation',
          name: 'NotificationService',
        );
      }
    } catch (e) {
      developer.log(
        'Error creating notification channels: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<bool> _requestPermissions() async {
    try {
      // For Android 13+ (API 33+), use platform-specific permission request
      // This is REQUIRED for release builds
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        // Always check current permission status first
        final areNotificationsEnabled = await androidImplementation
            .areNotificationsEnabled();

        developer.log(
          'Initial notification permission status: $areNotificationsEnabled',
          name: 'NotificationService',
        );

        // If notifications are not enabled, request permission
        if (areNotificationsEnabled != true) {
          // Request notification permission (Android 13+)
          // This method returns:
          // - true if granted
          // - false if denied
          // - null if not applicable (Android < 13)
          final granted = await androidImplementation
              .requestNotificationsPermission();

          developer.log(
            'Permission request result: $granted',
            name: 'NotificationService',
          );

          // Wait a moment for the system to update the permission state
          await Future.delayed(const Duration(milliseconds: 500));

          // Check again after request
          final areNotificationsEnabledAfter = await androidImplementation
              .areNotificationsEnabled();

          developer.log(
            'Notification permission after request: $areNotificationsEnabledAfter',
            name: 'NotificationService',
          );

          // If still not enabled, permission was denied
          if (areNotificationsEnabledAfter != true) {
            developer.log(
              'Android notification permission denied. granted: $granted, enabled: $areNotificationsEnabledAfter',
              name: 'NotificationService',
            );
            return false;
          }
        }

        // Final verification - ensure notifications are enabled
        final finalCheck = await androidImplementation
            .areNotificationsEnabled();
        if (finalCheck != true) {
          developer.log(
            'Final check: Notifications are disabled in system settings',
            name: 'NotificationService',
          );
          return false;
        }

        developer.log(
          'Notification permission granted and enabled',
          name: 'NotificationService',
        );
        return true;
      } else {
        // Fallback for older Android versions or non-Android platforms
        final isGranted = await Permission.notification.isGranted;
        if (!isGranted) {
          developer.log(
            'Requesting notification permission (fallback method)',
            name: 'NotificationService',
          );
          final status = await Permission.notification.request();
          developer.log(
            'Permission request status: $status',
            name: 'NotificationService',
          );
          if (!status.isGranted) {
            developer.log(
              'Notification permission denied',
              name: 'NotificationService',
            );
            return false;
          }
        }
        return true;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting notification permissions: $e\n$stackTrace',
        name: 'NotificationService',
      );
      return false;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
  }

  /// Schedule default notifications:
  /// - 5:30 AM daily (local time): Todo list reminder
  /// - 10:00 PM daily (local time): Check todo and add expenses reminder
  static Future<void> scheduleDefaultNotifications() async {
    try {
      developer.log(
        'Starting to schedule default notifications',
        name: 'NotificationService',
      );

      // Cancel existing notifications first
      await _notifications.cancel(moneyManagerReminderId);
      await _notifications.cancel(todoListReminderId);
      developer.log(
        'Cancelled existing notifications',
        name: 'NotificationService',
      );

      // Schedule notifications
      await scheduleMorningTodoReminder();
      await scheduleEveningExpensesReminder();

      developer.log(
        'Default notifications scheduling completed',
        name: 'NotificationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error scheduling notifications: $e\n$stackTrace',
        name: 'NotificationService',
      );
    }
  }

  /// Premium Android notification details: BigText style, subText, optional large icon.
  static AndroidNotificationDetails _premiumAndroidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    String? bigText,
    String? subText,
    String? largeIconDrawable,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_notification_white',
      color: const Color(0xFFFFFFFF),
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      autoCancel: true,
      ongoing: false,
      styleInformation: BigTextStyleInformation(
        bigText ?? body,
        contentTitle: title,
        summaryText: subText ?? 'Finzo • Reminder',
      ),
      largeIcon: largeIconDrawable == null
          ? null
          : DrawableResourceAndroidBitmap(largeIconDrawable),
      subText: subText ?? 'Finzo • Reminder',
    );
  }

  /// Alarm/call-style notification details for reminders. Uses dedicated channel so sound/vibration ring like alarm.
  static AndroidNotificationDetails _reminderAlarmStyleDetails({
    required String title,
    required String body,
    String? bigText,
    String? subText,
  }) {
    return AndroidNotificationDetails(
      remindersAlarmChannelId,
      'Reminder alarms',
      channelDescription: 'Rings like an alarm – use for important reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: 'ic_notification_white',
      color: const Color(0xFFFFFFFF),
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      autoCancel: true,
      ongoing: false,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        bigText ?? body,
        contentTitle: title,
        summaryText: subText ?? 'Finzo • Reminder',
      ),
      subText: subText ?? 'Finzo • Reminder',
    );
  }

  /// Schedule daily notification at 5:30 AM (local time) for todo list planning
  static Future<void> scheduleMorningTodoReminder() async {
    try {
      // Use the current local timezone (set during init)
      final localLocation = tz.local;
      final now = tz.TZDateTime.now(localLocation);

      // Schedule for 5:30 AM local time
      var scheduledDate = tz.TZDateTime(
        localLocation,
        now.year,
        now.month,
        now.day,
        11, // 5 AM
        20, // 30 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const morningTitle = 'Daily Plan Reminder';
      const morningBody =
          'Plan your day by creating a simple to-do list and setting priorities.';

      final androidDetails = _premiumAndroidDetails(
        channelId: todoListChannelId,
        channelName: 'Todo List Reminder',
        channelDescription: 'Daily reminder to create your todo list',
        title: morningTitle,
        body: morningBody,
        bigText:
            'Plan your day by creating a simple to-do list and setting priorities.\n\n'
            'Tip: Start with 3 key tasks. Keep it realistic and focused.',
        subText: 'Finzo • Morning',
        largeIconDrawable: 'ic_notification_256',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Prefer exact alarm for reliable delivery; fallback to inexact
      bool scheduled = false;
      for (final mode in [
        AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
        AndroidScheduleMode.inexact,
      ]) {
        try {
          await _notifications.zonedSchedule(
            todoListReminderId,
            morningTitle,
            morningBody,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          developer.log(
            'Morning notification scheduled ($mode) for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
            name: 'NotificationService',
          );
          scheduled = true;
          break;
        } catch (e) {
          // exact_alarms_not_permitted is expected when user hasn't granted exact alarm; fallback to inexact
          final isExactNotPermitted =
              e is PlatformException &&
              (e.code == 'exact_alarms_not_permitted' ||
                  e.code == 'Exact alarms are not permitted');
          if (!isExactNotPermitted) {
            developer.log(
              'Morning schedule $mode failed: $e',
              name: 'NotificationService',
            );
          }
        }
      }

      if (!scheduled) {
        developer.log(
          'CRITICAL: Morning notification was NOT scheduled successfully!',
          name: 'NotificationService',
        );
      }
    } catch (e) {
      developer.log(
        'Error scheduling morning todo reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 9:00 PM (local time) for expenses and todo completion
  static Future<void> scheduleEveningExpensesReminder() async {
    try {
      // Use the current local timezone (set during init)
      final localLocation = tz.local;
      final now = tz.TZDateTime.now(localLocation);

      // Schedule for 9:00 PM (21:00) local time
      var scheduledDate = tz.TZDateTime(
        localLocation,
        now.year,
        now.month,
        now.day,
        11, // 9 PM
        30, // 0 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const eveningTitle = 'Daily Review Reminder';
      const eveningBody =
          'Review today\'s spending and update your transactions to keep records accurate.';

      final androidDetails = _premiumAndroidDetails(
        channelId: moneyManagerChannelId,
        channelName: 'Money Manager Reminder',
        channelDescription: 'Daily reminder to update your money manager',
        title: eveningTitle,
        body: eveningBody,
        bigText:
            'Review today\'s spending and update your transactions to keep records accurate.\n\n'
            'Update expenses, add missing entries, and prepare for tomorrow.',
        subText: 'Finzo • Evening',
        largeIconDrawable: 'ic_notification_256',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Prefer exact alarm for reliable delivery; fallback to inexact
      bool scheduled = false;
      for (final mode in [
        AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
        AndroidScheduleMode.inexact,
      ]) {
        try {
          await _notifications.zonedSchedule(
            moneyManagerReminderId,
            eveningTitle,
            eveningBody,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          developer.log(
            'Evening notification scheduled ($mode) for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
            name: 'NotificationService',
          );
          scheduled = true;
          break;
        } catch (e) {
          final isExactNotPermitted =
              e is PlatformException &&
              (e.code == 'exact_alarms_not_permitted' ||
                  e.code == 'Exact alarms are not permitted');
          if (!isExactNotPermitted) {
            developer.log(
              'Evening schedule $mode failed: $e',
              name: 'NotificationService',
            );
          }
        }
      }

      if (!scheduled) {
        developer.log(
          'CRITICAL: Evening notification was NOT scheduled successfully!',
          name: 'NotificationService',
        );
      }
    } catch (e) {
      developer.log(
        'Error scheduling evening expenses reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancel(moneyManagerReminderId);
    await _notifications.cancel(todoListReminderId);
  }

  /// Cancel money manager reminder
  static Future<void> cancelMoneyManagerReminder() async {
    await _notifications.cancel(moneyManagerReminderId);
  }

  /// Cancel todo list reminder
  static Future<void> cancelTodoListReminder() async {
    await _notifications.cancel(todoListReminderId);
  }

  /// Schedule a one-time reminder notification at the given date/time.
  /// [notificationId] must be unique (e.g. from ReminderService).
  static Future<bool> scheduleReminderNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final localLocation = tz.local;
      final tzScheduled = tz.TZDateTime.from(scheduledDate, localLocation);
      if (tzScheduled.isBefore(tz.TZDateTime.now(localLocation))) {
        developer.log(
          'Reminder $notificationId is in the past, skipping',
          name: 'NotificationService',
        );
        return false;
      }
      final androidDetails = _reminderAlarmStyleDetails(
        title: title,
        body: body,
        bigText: body,
        subText: 'Finzo • Reminder',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      for (final mode in [
        AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
        AndroidScheduleMode.inexact,
      ]) {
        try {
          await _notifications.zonedSchedule(
            notificationId,
            title,
            body,
            tzScheduled,
            notificationDetails,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          developer.log(
            'Scheduled reminder $notificationId at $scheduledDate',
            name: 'NotificationService',
          );
          return true;
        } catch (e) {
          final isExactNotPermitted =
              e is PlatformException &&
              (e.code == 'exact_alarms_not_permitted' ||
                  e.code == 'Exact alarms are not permitted');
          if (!isExactNotPermitted) {
            developer.log(
              'Reminder schedule $mode failed: $e',
              name: 'NotificationService',
            );
          }
        }
      }
      return false;
    } catch (e) {
      developer.log(
        'Error scheduling reminder: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Cancel a scheduled reminder by its notification ID.
  static Future<void> cancelReminderNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  /// Show a test notification immediately (for testing)
  static Future<void> showTestNotification() async {
    final androidDetails = _premiumAndroidDetails(
      channelId: moneyManagerChannelId,
      channelName: 'Money Manager Reminder',
      channelDescription: 'Daily reminder to update your money manager',
      title: 'Finzo',
      body: 'Notifications are set up correctly.',
      subText: 'Finzo • Test',
      largeIconDrawable: 'ic_notification_256',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Finzo',
      'Notifications are set up correctly.',
      notificationDetails,
    );
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications should have fired and manually trigger if needed
  static Future<void> checkAndTriggerMissedNotifications() async {
    try {
      // Use the current local timezone (set during init)
      final localLocation = tz.local;
      final now = tz.TZDateTime.now(localLocation);

      // Check if it's past 5:30 AM today (todo list notification)
      final morningTargetTime = tz.TZDateTime(
        localLocation,
        now.year,
        now.month,
        now.day,
        5, // 5 AM
        30, // 30 minutes
      );

      // Check if it's past 9:00 PM today (expenses notification)
      final eveningTargetTime = tz.TZDateTime(
        localLocation,
        now.year,
        now.month,
        now.day,
        21, // 9 PM
        0, // 0 minutes
      );

      // If current time is within 5 minutes of notification time
      bool isMorningWindow =
          now.isAfter(morningTargetTime) &&
          now.isBefore(morningTargetTime.add(const Duration(minutes: 5)));

      bool isEveningWindow =
          now.isAfter(eveningTargetTime) &&
          now.isBefore(eveningTargetTime.add(const Duration(minutes: 5)));

      if (isMorningWindow || isEveningWindow) {
        // Check pending notifications
        final pending = await _notifications.pendingNotificationRequests();
        final hasMoneyManager = pending.any(
          (n) => n.id == moneyManagerReminderId,
        );
        final hasTodoList = pending.any((n) => n.id == todoListReminderId);

        // Check which notification should have fired
        bool shouldTriggerMorning = isMorningWindow && hasTodoList;
        bool shouldTriggerEvening = isEveningWindow && hasMoneyManager;

        if (shouldTriggerMorning && hasTodoList) {
          const morningTitle = 'Daily Plan Reminder';
          const morningBody =
              'Plan your day by creating a simple to-do list and setting priorities.';
          final androidDetails = _premiumAndroidDetails(
            channelId: todoListChannelId,
            channelName: 'Todo List Reminder',
            channelDescription: 'Daily reminder to create your todo list',
            title: morningTitle,
            body: morningBody,
            bigText:
                'Plan your day by creating a simple to-do list and setting priorities.\n\n'
                'Tip: Start with 3 key tasks. Keep it realistic and focused.',
            subText: 'Finzo • Morning',
            largeIconDrawable: '@drawable/ic_notification_256',
          );
          await _notifications.show(
            todoListReminderId,
            morningTitle,
            morningBody,
            NotificationDetails(
              android: androidDetails,
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.active,
              ),
            ),
          );
        }

        if (shouldTriggerEvening && hasMoneyManager) {
          const eveningTitle = 'Daily Review Reminder';
          const eveningBody =
              'Review today\'s spending and update your transactions to keep records accurate.';
          final androidDetails = _premiumAndroidDetails(
            channelId: moneyManagerChannelId,
            channelName: 'Money Manager Reminder',
            channelDescription: 'Daily reminder to update your money manager',
            title: eveningTitle,
            body: eveningBody,
            bigText:
                'Review today\'s spending and update your transactions to keep records accurate.\n\n'
                'Update expenses, add missing entries, and prepare for tomorrow.',
            subText: 'Finzo • Evening',
            largeIconDrawable: '@drawable/ic_notification_256',
          );
          await _notifications.show(
            moneyManagerReminderId,
            eveningTitle,
            eveningBody,
            NotificationDetails(
              android: androidDetails,
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.active,
              ),
            ),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error checking missed notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Force reschedule all notifications
  /// Call this after permission is granted to ensure notifications are scheduled
  static Future<void> rescheduleAllNotifications() async {
    try {
      developer.log(
        'Rescheduling all notifications...',
        name: 'NotificationService',
      );

      final hasPermission = await _requestPermissions();
      if (hasPermission) {
        // Ensure channels are created
        await _createNotificationChannels();

        // Wait a moment for channels to be ready
        await Future.delayed(const Duration(milliseconds: 300));

        await scheduleDefaultNotifications();

        // Verify they were scheduled
        await Future.delayed(const Duration(milliseconds: 500));
        final pending = await _notifications.pendingNotificationRequests();
        developer.log(
          'Rescheduled notifications: ${pending.length} pending',
          name: 'NotificationService',
        );

        if (pending.isEmpty) {
          developer.log(
            'WARNING: No notifications scheduled after reschedule attempt!',
            name: 'NotificationService',
          );
        }
      } else {
        developer.log(
          'Cannot reschedule: Notification permission not granted',
          name: 'NotificationService',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error rescheduling notifications: $e\n$stackTrace',
        name: 'NotificationService',
      );
    }
  }

  /// Verify that notifications are properly scheduled
  /// Returns true if both notifications are scheduled, false otherwise
  static Future<bool> verifyNotificationsScheduled() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      final hasMorning = pending.any((n) => n.id == todoListReminderId);
      final hasEvening = pending.any((n) => n.id == moneyManagerReminderId);

      developer.log(
        'Notification verification: Morning=$hasMorning, Evening=$hasEvening, Total=${pending.length}',
        name: 'NotificationService',
      );

      return hasMorning && hasEvening;
    } catch (e) {
      developer.log(
        'Error verifying notifications: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Public method to check and request notification permissions
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestNotificationPermission() async {
    return await _requestPermissions();
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final areNotificationsEnabled = await androidImplementation
            .areNotificationsEnabled();
        return areNotificationsEnabled == true;
      } else {
        return await Permission.notification.isGranted;
      }
    } catch (e) {
      developer.log(
        'Error checking notification permission: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }
}
