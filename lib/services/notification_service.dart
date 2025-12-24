import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

// Top-level function for background notification handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  developer.log(
    '🔔 === NOTIFICATION TAPPED/RECEIVED (BACKGROUND) ===',
    name: 'NotificationService',
  );
  developer.log('Timestamp: ${DateTime.now()}', name: 'NotificationService');
  developer.log('Notification ID: ${response.id}', name: 'NotificationService');
  developer.log(
    'Notification Action ID: ${response.actionId}',
    name: 'NotificationService',
  );
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
      developer.log(
        'Initializing notification plugin...',
        name: 'NotificationService',
      );

      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized == true) {
        developer.log(
          '✅ Notifications initialized successfully',
          name: 'NotificationService',
        );
      } else {
        developer.log(
          '❌ Notifications initialization failed',
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

        // Check if we missed any notifications (e.g., if app was closed when notification should fire)
        await checkAndTriggerMissedNotifications();
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
    // Using max importance to ensure notifications are not suppressed
    const moneyManagerChannel = AndroidNotificationChannel(
      moneyManagerChannelId,
      'Money Manager Reminder',
      description: 'Daily reminder to update your money manager',
      importance: Importance.max, // Changed to max for better reliability
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Todo List Reminder Channel
    // Using max importance to ensure notifications are not suppressed
    const todoListChannel = AndroidNotificationChannel(
      todoListChannelId,
      'Todo List Reminder',
      description: 'Daily reminder to create your todo list',
      importance: Importance.max, // Changed to max for better reliability
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create channels
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        moneyManagerChannel,
      );
      developer.log(
        'Money Manager notification channel created',
        name: 'NotificationService',
      );

      await androidImplementation.createNotificationChannel(todoListChannel);
      developer.log(
        'Todo List notification channel created',
        name: 'NotificationService',
      );
    } else {
      developer.log(
        'Android implementation not available',
        name: 'NotificationService',
      );
    }
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
    developer.log(
      '🔔 === NOTIFICATION TAPPED/RECEIVED (FOREGROUND) ===',
      name: 'NotificationService',
    );
    developer.log('Timestamp: ${DateTime.now()}', name: 'NotificationService');
    developer.log(
      'Notification ID: ${response.id}',
      name: 'NotificationService',
    );
    developer.log(
      'Notification Action ID: ${response.actionId}',
      name: 'NotificationService',
    );
    developer.log(
      'Notification Payload: ${response.payload}',
      name: 'NotificationService',
    );
    developer.log(
      'Notification Input: ${response.input}',
      name: 'NotificationService',
    );

    // Handle notification tap if needed
    // You can navigate to specific screens based on notification ID
  }

  /// Schedule default notifications:
  /// - 01:10 AM daily (Sri Lankan time): Money manager reminder
  /// - 01:10 AM daily (Sri Lankan time): Todo list creation reminder
  static Future<void> scheduleDefaultNotifications() async {
    try {
      developer.log(
        '🔄 === SCHEDULING DEFAULT NOTIFICATIONS ===',
        name: 'NotificationService',
      );
      developer.log(
        'Current time: ${DateTime.now()}',
        name: 'NotificationService',
      );

      // Cancel existing notifications first
      developer.log(
        'Cancelling existing notifications...',
        name: 'NotificationService',
      );
      await _notifications.cancel(moneyManagerReminderId);
      await _notifications.cancel(todoListReminderId);
      developer.log(
        'Existing notifications cancelled',
        name: 'NotificationService',
      );

      // Schedule 01:10 AM money manager reminder
      await scheduleMoneyManagerReminder();

      // Schedule 01:10 AM todo list reminder
      await scheduleTodoListReminder();

      developer.log(
        '✅ Default notifications scheduled successfully',
        name: 'NotificationService',
      );

      // Log all pending notifications for verification
      await logPendingNotifications();
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error scheduling notifications: $e',
        name: 'NotificationService',
      );
      developer.log('Stack trace: $stackTrace', name: 'NotificationService');
    }
  }

  /// Schedule daily notification at 01:10 AM (1 hour 10 minutes, Sri Lankan time) for money manager reminder
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

      // Schedule for 01:10 AM (1 hour 10 minutes) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        1, // 1 AM
        10, // 10 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        developer.log(
          '01:10 AM has passed today, scheduling for tomorrow',
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
        importance: Importance.max, // Max importance for better reliability
        priority: Priority.max, // Max priority
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
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

      // Use inexact scheduling as primary (more reliable on Android)
      // Exact alarms are often blocked by battery optimization
      bool scheduled = false;

      // Try inexactAllowWhileIdle first (most reliable)
      try {
        developer.log(
          '⏰ Attempting to schedule money manager notification...',
          name: 'NotificationService',
        );
        developer.log(
          'Scheduled time: $scheduledDate',
          name: 'NotificationService',
        );
        developer.log(
          'Scheduled time UTC: ${scheduledDate.toUtc()}',
          name: 'NotificationService',
        );
        developer.log('Current time: $now', name: 'NotificationService');
        developer.log(
          'Time difference: ${scheduledDate.difference(now).inMinutes} minutes',
          name: 'NotificationService',
        );

        await _notifications.zonedSchedule(
          moneyManagerReminderId,
          '💰 Update Your Finances',
          'Time to record your daily transactions and track your spending!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduled = true;
        developer.log(
          '✅ Money manager reminder scheduled with INEXACT_ALLOW_WHILE_IDLE mode for: $scheduledDate (${scheduledDate.timeZoneName})',
          name: 'NotificationService',
        );
        developer.log(
          '📅 This will repeat daily at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log(
          'InexactAllowWhileIdle scheduling failed, trying exact: $e',
          name: 'NotificationService',
        );
        // Try exact scheduling as fallback
        try {
          await _notifications.zonedSchedule(
            moneyManagerReminderId,
            '💰 Update Your Finances',
            'Time to record your daily transactions and track your spending!',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          scheduled = true;
          developer.log(
            'Money manager reminder scheduled with EXACT_ALLOW_WHILE_IDLE mode for: $scheduledDate (${scheduledDate.timeZoneName})',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'Exact scheduling also failed, trying basic inexact: $e2',
            name: 'NotificationService',
          );
          // Last resort: try without allowWhileIdle
          try {
            await _notifications.zonedSchedule(
              moneyManagerReminderId,
              '💰 Update Your Finances',
              'Time to record your daily transactions and track your spending!',
              scheduledDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexact,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            scheduled = true;
            developer.log(
              'Money manager reminder scheduled with basic INEXACT mode',
              name: 'NotificationService',
            );
          } catch (e3) {
            developer.log(
              'All scheduling methods failed: $e3',
              name: 'NotificationService',
            );
            rethrow;
          }
        }
      }

      if (scheduled) {
        developer.log(
          'This corresponds to: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} ${scheduledDate.hour >= 12 ? 'PM' : 'AM'} Sri Lankan time',
          name: 'NotificationService',
        );

        // Verify the notification was scheduled
        final pending = await _notifications.pendingNotificationRequests();
        final scheduledNotifications = pending.where(
          (n) => n.id == moneyManagerReminderId,
        );
        if (scheduledNotifications.isNotEmpty) {
          developer.log(
            'Verified: Notification ID ${scheduledNotifications.first.id} is scheduled',
            name: 'NotificationService',
          );
          developer.log(
            'Notification title: ${scheduledNotifications.first.title}',
            name: 'NotificationService',
          );
        } else {
          developer.log(
            'Warning: Notification ID $moneyManagerReminderId not found in pending list (${pending.length} total pending)',
            name: 'NotificationService',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error scheduling money manager reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 01:10 AM (1 hour 10 minutes, Sri Lankan time) for todo list creation reminder
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

      // Schedule for 01:10 AM (1 hour 10 minutes) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        1, // 1 AM
        15, // 10 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        developer.log(
          '01:10 AM has passed today, scheduling for tomorrow',
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
        importance: Importance.max, // Max importance for better reliability
        priority: Priority.max, // Max priority
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
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

      // Use inexact scheduling as primary (more reliable on Android)
      // Exact alarms are often blocked by battery optimization
      bool scheduled = false;

      // Try inexactAllowWhileIdle first (most reliable)
      try {
        developer.log(
          '⏰ Attempting to schedule todo list notification...',
          name: 'NotificationService',
        );
        developer.log(
          'Scheduled time: $scheduledDate',
          name: 'NotificationService',
        );
        developer.log(
          'Scheduled time UTC: ${scheduledDate.toUtc()}',
          name: 'NotificationService',
        );
        developer.log('Current time: $now', name: 'NotificationService');
        developer.log(
          'Time difference: ${scheduledDate.difference(now).inMinutes} minutes',
          name: 'NotificationService',
        );

        await _notifications.zonedSchedule(
          todoListReminderId,
          '📝 Plan Your Day',
          'Create your todo list for today and stay organized!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduled = true;
        developer.log(
          '✅ Todo list reminder scheduled with INEXACT_ALLOW_WHILE_IDLE mode for: $scheduledDate (${scheduledDate.timeZoneName})',
          name: 'NotificationService',
        );
        developer.log(
          '📅 This will repeat daily at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
          name: 'NotificationService',
        );
      } catch (e, stackTrace) {
        developer.log(
          '❌ InexactAllowWhileIdle scheduling failed, trying exact: $e',
          name: 'NotificationService',
        );
        developer.log('Stack trace: $stackTrace', name: 'NotificationService');
        // Try exact scheduling as fallback
        try {
          developer.log(
            '🔄 Trying EXACT_ALLOW_WHILE_IDLE mode...',
            name: 'NotificationService',
          );
          await _notifications.zonedSchedule(
            todoListReminderId,
            '📝 Plan Your Day',
            'Create your todo list for today and stay organized!',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          scheduled = true;
          developer.log(
            '✅ Todo list reminder scheduled with EXACT_ALLOW_WHILE_IDLE mode for: $scheduledDate (${scheduledDate.timeZoneName})',
            name: 'NotificationService',
          );
        } catch (e2, stackTrace2) {
          developer.log(
            '❌ Exact scheduling also failed, trying basic inexact: $e2',
            name: 'NotificationService',
          );
          developer.log(
            'Stack trace: $stackTrace2',
            name: 'NotificationService',
          );
          // Last resort: try without allowWhileIdle
          try {
            await _notifications.zonedSchedule(
              todoListReminderId,
              '📝 Plan Your Day',
              'Create your todo list for today and stay organized!',
              scheduledDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.inexact,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            scheduled = true;
            developer.log(
              'Todo list reminder scheduled with basic INEXACT mode',
              name: 'NotificationService',
            );
          } catch (e3) {
            developer.log(
              'All scheduling methods failed: $e3',
              name: 'NotificationService',
            );
            rethrow;
          }
        }
      }

      if (scheduled) {
        developer.log(
          'This corresponds to: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} ${scheduledDate.hour >= 12 ? 'PM' : 'AM'} Sri Lankan time',
          name: 'NotificationService',
        );

        // Verify the notification was scheduled
        developer.log(
          '🔍 Verifying scheduled notification...',
          name: 'NotificationService',
        );
        final pending = await _notifications.pendingNotificationRequests();
        developer.log(
          'Total pending notifications: ${pending.length}',
          name: 'NotificationService',
        );

        final scheduledNotifications = pending.where(
          (n) => n.id == todoListReminderId,
        );
        if (scheduledNotifications.isNotEmpty) {
          developer.log(
            '✅ Verified: Notification ID ${scheduledNotifications.first.id} is scheduled',
            name: 'NotificationService',
          );
          developer.log(
            'Notification title: ${scheduledNotifications.first.title}',
            name: 'NotificationService',
          );
          developer.log(
            'Notification body: ${scheduledNotifications.first.body}',
            name: 'NotificationService',
          );
        } else {
          developer.log(
            '⚠️ WARNING: Notification ID $todoListReminderId not found in pending list!',
            name: 'NotificationService',
          );
          developer.log(
            'This means the notification was NOT scheduled properly!',
            name: 'NotificationService',
          );
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
      '💰 Update Your Finances',
      'Time to record your daily transactions and track your spending!',
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
      '📝 Plan Your Day',
      'Create your todo list for today and stay organized!',
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
            'This is a scheduled daily reminder (should fire at 01:10 AM Sri Lankan time)',
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

  /// Check if notifications should have fired and manually trigger if needed
  /// Call this periodically or when app starts to catch missed notifications
  static Future<void> checkAndTriggerMissedNotifications() async {
    try {
      developer.log(
        '🔍 === CHECKING FOR MISSED NOTIFICATIONS ===',
        name: 'NotificationService',
      );

      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      developer.log('Current time: $now', name: 'NotificationService');

      // Check if it's past 01:10 AM today
      final targetTime = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        1, // 1 AM
        15, // 10 minutes
      );

      // If current time is between 01:10 and 01:15, and notification hasn't fired
      // This gives a 5-minute window to catch missed notifications
      if (now.isAfter(targetTime) &&
          now.isBefore(targetTime.add(const Duration(minutes: 5)))) {
        developer.log(
          '⏰ It\'s past 01:10 AM, checking if notifications fired...',
          name: 'NotificationService',
        );

        // Check pending notifications
        final pending = await _notifications.pendingNotificationRequests();
        final hasMoneyManager = pending.any(
          (n) => n.id == moneyManagerReminderId,
        );
        final hasTodoList = pending.any((n) => n.id == todoListReminderId);

        if (hasMoneyManager || hasTodoList) {
          developer.log(
            '⚠️ Notifications are still pending - they may not have fired!',
            name: 'NotificationService',
          );
          developer.log(
            'Money Manager pending: $hasMoneyManager, Todo List pending: $hasTodoList',
            name: 'NotificationService',
          );

          // Manually show the notifications
          developer.log(
            '🔔 Manually triggering notifications now...',
            name: 'NotificationService',
          );

          if (hasMoneyManager) {
            await _notifications.show(
              moneyManagerReminderId,
              '💰 Update Your Finances',
              'Time to record your daily transactions and track your spending!',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  moneyManagerChannelId,
                  'Money Manager Reminder',
                  channelDescription:
                      'Daily reminder to update your money manager',
                  importance: Importance.max,
                  priority: Priority.max,
                  showWhen: true,
                  enableVibration: true,
                  playSound: true,
                ),
              ),
            );
            developer.log(
              '✅ Money Manager notification manually triggered',
              name: 'NotificationService',
            );
          }

          if (hasTodoList) {
            await _notifications.show(
              todoListReminderId,
              '📝 Plan Your Day',
              'Create your todo list for today and stay organized!',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  todoListChannelId,
                  'Todo List Reminder',
                  channelDescription: 'Daily reminder to create your todo list',
                  importance: Importance.max,
                  priority: Priority.max,
                  showWhen: true,
                  enableVibration: true,
                  playSound: true,
                ),
              ),
            );
            developer.log(
              '✅ Todo List notification manually triggered',
              name: 'NotificationService',
            );
          }
        } else {
          developer.log(
            '✅ Notifications are not pending - they may have already fired',
            name: 'NotificationService',
          );
        }
      } else {
        developer.log(
          '⏰ Not yet time for notifications (current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')})',
          name: 'NotificationService',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error checking missed notifications: $e',
        name: 'NotificationService',
      );
      developer.log('Stack trace: $stackTrace', name: 'NotificationService');
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

      // Calculate next 01:10 AM
      var next0110 = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        1,
        10,
      );

      if (next0110.isBefore(now)) {
        next0110 = next0110.add(const Duration(days: 1));
      }

      final next0110Utc = next0110.toUtc();

      developer.log(
        'Next 01:10 AM in Asia/Colombo: $next0110',
        name: 'NotificationService',
      );
      developer.log(
        'Next 01:10 AM in UTC: $next0110Utc',
        name: 'NotificationService',
      );
      developer.log(
        'Time until next 01:10 AM: ${next0110.difference(now).inHours} hours ${next0110.difference(now).inMinutes % 60} minutes',
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
