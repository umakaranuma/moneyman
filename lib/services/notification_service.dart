import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int moneyManagerReminderId = 1;
  static const int todoListReminderId = 2;

  // Notification Channel IDs
  static const String moneyManagerChannelId = 'money_manager_reminder';
  static const String todoListChannelId = 'todo_list_reminder';

  static Future<void> init() async {
    try {
      // Initialize timezone with all timezone data
      tz.initializeTimeZones();

      // Verify Sri Lankan timezone is available
      try {
        final sriLankanLocation = tz.getLocation('Asia/Colombo');
        developer.log(
          'Sri Lankan timezone (Asia/Colombo) loaded successfully',
          name: 'NotificationService',
        );
        developer.log(
          'Current time in Asia/Colombo: ${tz.TZDateTime.now(sriLankanLocation)}',
          name: 'NotificationService',
        );
        developer.log(
          'Timezone offset: ${sriLankanLocation.currentTimeZone.offset}',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log(
          'Error loading Asia/Colombo timezone: $e',
          name: 'NotificationService',
        );
      }

      try {
        // Set timezone to Sri Lanka (Asia/Colombo)
        tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
        developer.log(
          'Timezone set to Asia/Colombo (Sri Lankan time)',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log('Timezone setup error: $e', name: 'NotificationService');
        // Fallback to UTC if Colombo timezone not available
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
          developer.log(
            'Fell back to UTC timezone',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'UTC fallback also failed: $e2',
            name: 'NotificationService',
          );
        }
      }

      // Create notification channels for Android (required for Android 8.0+)
      await _createNotificationChannels();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
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
      );

      if (initialized == true) {
        developer.log(
          'Notifications initialized successfully',
          name: 'NotificationService',
        );
      } else {
        developer.log(
          'Notifications initialization failed',
          name: 'NotificationService',
        );
      }

      // Request notification permissions (Android 13+)
      final hasPermission = await _requestPermissions();

      if (hasPermission) {
        developer.log(
          'Notification permission granted',
          name: 'NotificationService',
        );
        // Schedule default notifications
        await scheduleDefaultNotifications();
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

  /// Create notification channels for Android (required for Android 8.0+)
  static Future<void> _createNotificationChannels() async {
    // Money Manager Reminder Channel
    const moneyManagerChannel = AndroidNotificationChannel(
      moneyManagerChannelId,
      'Money Manager Reminder',
      description: 'Daily reminder to update your money manager',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Todo List Reminder Channel
    const todoListChannel = AndroidNotificationChannel(
      todoListChannelId,
      'Todo List Reminder',
      description: 'Daily reminder to create your todo list',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create channels
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(moneyManagerChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(todoListChannel);
  }

  static Future<bool> _requestPermissions() async {
    // Check notification permission
    bool hasNotificationPermission = false;
    if (await Permission.notification.isGranted) {
      hasNotificationPermission = true;
      developer.log(
        'Notification permission already granted',
        name: 'NotificationService',
      );
    } else {
      developer.log(
        'Requesting notification permission...',
        name: 'NotificationService',
      );
      final status = await Permission.notification.request();
      hasNotificationPermission = status.isGranted;
      developer.log(
        'Notification permission status: ${status.toString()}',
        name: 'NotificationService',
      );
    }

    // For Android 12+, exact alarm permission is handled by the system
    // The USE_EXACT_ALARM permission in manifest should be sufficient
    // SCHEDULE_EXACT_ALARM may require user approval on some devices
    developer.log(
      'Notification permission result: $hasNotificationPermission',
      name: 'NotificationService',
    );

    return hasNotificationPermission;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // You can navigate to specific screens based on notification ID
  }

  /// Schedule default notifications:
  /// - 12:45 AM daily (Sri Lankan time): Money manager reminder
  /// - 12:45 AM daily (Sri Lankan time): Todo list creation reminder
  static Future<void> scheduleDefaultNotifications() async {
    try {
      // Cancel existing notifications first
      await _notifications.cancel(moneyManagerReminderId);
      await _notifications.cancel(todoListReminderId);

      // Schedule 12:45 AM money manager reminder
      await scheduleMoneyManagerReminder();

      // Schedule 12:45 AM todo list reminder
      await scheduleTodoListReminder();

      developer.log(
        'Default notifications scheduled successfully',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 12:45 AM (midnight + 45 minutes, Sri Lankan time) for money manager reminder
  static Future<void> scheduleMoneyManagerReminder() async {
    try {
      // Get current time in Sri Lankan timezone
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      developer.log(
        '=== Scheduling Money Manager Reminder ===',
        name: 'NotificationService',
      );
      developer.log(
        'Current time in Sri Lankan timezone (Asia/Colombo): $now',
        name: 'NotificationService',
      );
      developer.log(
        'Current timezone offset: ${sriLankanLocation.currentTimeZone.offset}',
        name: 'NotificationService',
      );

      // Schedule for 12:45 AM (midnight + 45 minutes) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        0, // 12 AM (midnight)
        45, // 45 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        developer.log(
          '12:45 AM has passed today, scheduling for tomorrow',
          name: 'NotificationService',
        );
      }

      // Convert to UTC for verification
      final scheduledUtc = scheduledDate.toUtc();
      developer.log(
        'Scheduled time in Sri Lankan timezone: $scheduledDate',
        name: 'NotificationService',
      );
      developer.log(
        'Scheduled time in UTC: $scheduledUtc',
        name: 'NotificationService',
      );
      developer.log(
        'Time until notification: ${scheduledDate.difference(now).inMinutes} minutes (${(scheduledDate.difference(now).inHours)} hours)',
        name: 'NotificationService',
      );

      const androidDetails = AndroidNotificationDetails(
        moneyManagerChannelId,
        'Money Manager Reminder',
        channelDescription: 'Daily reminder to update your money manager',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notifications.zonedSchedule(
          moneyManagerReminderId,
          'Money Manager Reminder',
          'Don\'t forget to update your transactions and track your expenses!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        developer.log(
          'Money manager reminder scheduled successfully for: $scheduledDate (${scheduledDate.timeZoneName})',
          name: 'NotificationService',
        );
        developer.log(
          'This corresponds to: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} ${scheduledDate.hour >= 12 ? 'PM' : 'AM'} Sri Lankan time',
          name: 'NotificationService',
        );

        // Verify the notification was scheduled
        final pending = await _notifications.pendingNotificationRequests();
        final scheduled = pending.where((n) => n.id == moneyManagerReminderId);
        if (scheduled.isNotEmpty) {
          developer.log(
            'Verified: Notification ID ${scheduled.first.id} is scheduled',
            name: 'NotificationService',
          );
          developer.log(
            'Notification title: ${scheduled.first.title}',
            name: 'NotificationService',
          );
        } else {
          developer.log(
            'Warning: Notification ID $moneyManagerReminderId not found in pending list (${pending.length} total pending)',
            name: 'NotificationService',
          );
        }
      } catch (e) {
        developer.log(
          'Error in zonedSchedule for money manager: $e',
          name: 'NotificationService',
        );
        // Try with inexact scheduling as fallback
        try {
          await _notifications.zonedSchedule(
            moneyManagerReminderId,
            'Money Manager Reminder',
            'Don\'t forget to update your transactions and track your expenses!',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          developer.log(
            'Money manager reminder scheduled with inexact mode as fallback',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'Fallback scheduling also failed: $e2',
            name: 'NotificationService',
          );
          rethrow;
        }
      }
    } catch (e) {
      developer.log(
        'Error scheduling money manager reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 12:45 AM (midnight + 45 minutes, Sri Lankan time) for todo list creation reminder
  static Future<void> scheduleTodoListReminder() async {
    try {
      // Get current time in Sri Lankan timezone
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      developer.log(
        '=== Scheduling Todo List Reminder ===',
        name: 'NotificationService',
      );
      developer.log(
        'Current time in Sri Lankan timezone (Asia/Colombo): $now',
        name: 'NotificationService',
      );
      developer.log(
        'Current timezone offset: ${sriLankanLocation.currentTimeZone.offset}',
        name: 'NotificationService',
      );

      // Schedule for 12:45 AM (midnight + 45 minutes) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        0, // 12 AM (midnight)
        45, // 45 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        developer.log(
          '12:45 AM has passed today, scheduling for tomorrow',
          name: 'NotificationService',
        );
      }

      // Convert to UTC for verification
      final scheduledUtc = scheduledDate.toUtc();
      developer.log(
        'Scheduled time in Sri Lankan timezone: $scheduledDate',
        name: 'NotificationService',
      );
      developer.log(
        'Scheduled time in UTC: $scheduledUtc',
        name: 'NotificationService',
      );
      developer.log(
        'Time until notification: ${scheduledDate.difference(now).inMinutes} minutes (${(scheduledDate.difference(now).inHours)} hours)',
        name: 'NotificationService',
      );

      const androidDetails = AndroidNotificationDetails(
        todoListChannelId,
        'Todo List Reminder',
        channelDescription: 'Daily reminder to create your todo list',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notifications.zonedSchedule(
          todoListReminderId,
          'Create Today\'s Todo List',
          'Start your day right! Create your todo list for today.',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        developer.log(
          'Todo list reminder scheduled successfully for: $scheduledDate (${scheduledDate.timeZoneName})',
          name: 'NotificationService',
        );
        developer.log(
          'This corresponds to: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} ${scheduledDate.hour >= 12 ? 'PM' : 'AM'} Sri Lankan time',
          name: 'NotificationService',
        );

        // Verify the notification was scheduled
        final pending = await _notifications.pendingNotificationRequests();
        final scheduled = pending.where((n) => n.id == todoListReminderId);
        if (scheduled.isNotEmpty) {
          developer.log(
            'Verified: Notification ID ${scheduled.first.id} is scheduled',
            name: 'NotificationService',
          );
          developer.log(
            'Notification title: ${scheduled.first.title}',
            name: 'NotificationService',
          );
        } else {
          developer.log(
            'Warning: Notification ID $todoListReminderId not found in pending list (${pending.length} total pending)',
            name: 'NotificationService',
          );
        }
      } catch (e) {
        developer.log(
          'Error in zonedSchedule for todo list: $e',
          name: 'NotificationService',
        );
        // Try with inexact scheduling as fallback
        try {
          await _notifications.zonedSchedule(
            todoListReminderId,
            'Create Today\'s Todo List',
            'Start your day right! Create your todo list for today.',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          developer.log(
            'Todo list reminder scheduled with inexact mode as fallback',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'Fallback scheduling also failed: $e2',
            name: 'NotificationService',
          );
          rethrow;
        }
      }
    } catch (e) {
      developer.log(
        'Error scheduling todo list reminder: $e',
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

  /// Show a test notification immediately (for testing)
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      moneyManagerChannelId,
      'Money Manager Reminder',
      channelDescription: 'Daily reminder to update your money manager',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      ongoing: false,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification',
      'If you see this, notifications are working!',
      notificationDetails,
    );

    developer.log('Test notification shown', name: 'NotificationService');
  }

  /// Show scheduled notifications immediately (for testing)
  static Future<void> showScheduledNotificationsNow() async {
    developer.log(
      'Showing scheduled notifications immediately for testing...',
      name: 'NotificationService',
    );

    // Show money manager reminder
    const androidDetails1 = AndroidNotificationDetails(
      moneyManagerChannelId,
      'Money Manager Reminder',
      channelDescription: 'Daily reminder to update your money manager',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      ongoing: false,
      autoCancel: true,
    );

    const iosDetails1 = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      moneyManagerReminderId,
      'Money Manager Reminder',
      'Don\'t forget to update your transactions and track your expenses!',
      const NotificationDetails(android: androidDetails1, iOS: iosDetails1),
    );

    // Wait a bit before showing the second one
    await Future.delayed(const Duration(seconds: 1));

    // Show todo list reminder
    const androidDetails2 = AndroidNotificationDetails(
      todoListChannelId,
      'Todo List Reminder',
      channelDescription: 'Daily reminder to create your todo list',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      ongoing: false,
      autoCancel: true,
    );

    await _notifications.show(
      todoListReminderId,
      'Create Today\'s Todo List',
      'Start your day right! Create your todo list for today.',
      const NotificationDetails(android: androidDetails2, iOS: iosDetails1),
    );

    developer.log(
      'Both scheduled notifications shown immediately',
      name: 'NotificationService',
    );
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Log all pending notifications for debugging
  static Future<void> logPendingNotifications() async {
    try {
      final pending = await getPendingNotifications();
      developer.log(
        '=== Pending Notifications Debug ===',
        name: 'NotificationService',
      );
      developer.log(
        'Pending notifications count: ${pending.length}',
        name: 'NotificationService',
      );

      // Get current time in Sri Lankan timezone for comparison
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);
      developer.log(
        'Current time in Sri Lankan timezone: $now',
        name: 'NotificationService',
      );

      for (var notification in pending) {
        developer.log(
          '--- Notification ID: ${notification.id} ---',
          name: 'NotificationService',
        );
        developer.log(
          'Title: ${notification.title}',
          name: 'NotificationService',
        );
        developer.log(
          'Body: ${notification.body}',
          name: 'NotificationService',
        );

        // Check if it's one of our scheduled notifications
        if (notification.id == moneyManagerReminderId ||
            notification.id == todoListReminderId) {
          developer.log(
            'This is a scheduled daily reminder (should fire at 12:45 AM Sri Lankan time)',
            name: 'NotificationService',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error getting pending notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Diagnostic method to check timezone and scheduled notification times
  static Future<void> diagnoseNotificationTiming() async {
    try {
      developer.log(
        '=== Notification Timing Diagnostic ===',
        name: 'NotificationService',
      );

      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);
      final nowUtc = now.toUtc();

      developer.log(
        'Current time in Asia/Colombo: $now',
        name: 'NotificationService',
      );
      developer.log(
        'Current time in UTC: $nowUtc',
        name: 'NotificationService',
      );
      developer.log(
        'Timezone offset: ${sriLankanLocation.currentTimeZone.offset}',
        name: 'NotificationService',
      );

      // Calculate next 12:45 AM
      var next1245 = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        0,
        45,
      );

      if (next1245.isBefore(now)) {
        next1245 = next1245.add(const Duration(days: 1));
      }

      final next1245Utc = next1245.toUtc();

      developer.log(
        'Next 12:45 AM in Asia/Colombo: $next1245',
        name: 'NotificationService',
      );
      developer.log(
        'Next 12:45 AM in UTC: $next1245Utc',
        name: 'NotificationService',
      );
      developer.log(
        'Time until next 12:45 AM: ${next1245.difference(now).inHours} hours ${next1245.difference(now).inMinutes % 60} minutes',
        name: 'NotificationService',
      );

      // Check pending notifications
      final pending = await getPendingNotifications();
      developer.log(
        'Pending notifications: ${pending.length}',
        name: 'NotificationService',
      );

      for (var notif in pending) {
        if (notif.id == moneyManagerReminderId ||
            notif.id == todoListReminderId) {
          developer.log(
            'Found scheduled notification ID: ${notif.id}',
            name: 'NotificationService',
          );
        }
      }
    } catch (e) {
      developer.log('Error in diagnostic: $e', name: 'NotificationService');
    }
  }

  /// Force reschedule all notifications (useful after code changes)
  static Future<void> rescheduleAllNotifications() async {
    developer.log(
      'Force rescheduling all notifications...',
      name: 'NotificationService',
    );
    final hasPermission = await _requestPermissions();
    if (hasPermission) {
      await scheduleDefaultNotifications();
      await logPendingNotifications();
    } else {
      developer.log(
        'Cannot reschedule: notification permission not granted',
        name: 'NotificationService',
      );
    }
  }

  /// Check if notifications are still pending and show them if they should have fired
  static Future<void> checkAndShowMissedNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      final now = tz.TZDateTime.now(tz.getLocation('Asia/Colombo'));

      developer.log(
        'Checking missed notifications. Current time: $now, Pending count: ${pending.length}',
        name: 'NotificationService',
      );

      for (var notification in pending) {
        developer.log(
          'Pending notification ID: ${notification.id}, Title: ${notification.title}',
          name: 'NotificationService',
        );

        // If it's one of our scheduled notifications and it's past the scheduled time
        if (notification.id == moneyManagerReminderId ||
            notification.id == todoListReminderId) {
          // The notification should have fired, but might have been suppressed
          // Show it now manually
          developer.log(
            'Notification ${notification.id} should have fired. Showing now...',
            name: 'NotificationService',
          );
        }
      }

      // Show the notifications now since they should have fired
      await showScheduledNotificationsNow();
    } catch (e) {
      developer.log(
        'Error checking missed notifications: $e',
        name: 'NotificationService',
      );
    }
  }
}
