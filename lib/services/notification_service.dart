import 'dart:developer' as developer;
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

  static Future<void> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      try {
        tz.setLocalLocation(tz.getLocation('Asia/Colombo'));
      } catch (e) {
        developer.log(
          'Error setting timezone: $e',
          name: 'NotificationService',
        );
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (e2) {
          developer.log(
            'UTC fallback failed: $e2',
            name: 'NotificationService',
          );
        }
      }

      // Create notification channels
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
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (initialized != true) {
        developer.log(
          'Notification initialization failed',
          name: 'NotificationService',
        );
        return;
      }

      // Request notification permissions
      final hasPermission = await _requestPermissions();

      if (hasPermission) {
        await scheduleDefaultNotifications();
        await checkAndTriggerMissedNotifications();

        // Verify notifications were scheduled
        final pending = await _notifications.pendingNotificationRequests();
        developer.log(
          'Notifications scheduled: ${pending.length} pending',
          name: 'NotificationService',
        );
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

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        moneyManagerChannel,
      );
      await androidImplementation.createNotificationChannel(todoListChannel);
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
  /// - 06:00 AM daily (Sri Lankan time): Morning todo list reminder
  /// - 09:00 PM daily (Sri Lankan time): Evening expenses and todo completion reminder
  static Future<void> scheduleDefaultNotifications() async {
    try {
      // Cancel existing notifications first
      await _notifications.cancel(moneyManagerReminderId);
      await _notifications.cancel(todoListReminderId);

      // Schedule notifications
      await scheduleMorningTodoReminder();
      await scheduleEveningExpensesReminder();
    } catch (e) {
      developer.log(
        'Error scheduling notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 06:00 AM (morning, Sri Lankan time) for todo list planning
  static Future<void> scheduleMorningTodoReminder() async {
    try {
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      // Schedule for 06:00 AM Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        6, // 6 AM
        0, // 0 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        todoListChannelId,
        'Todo List Reminder',
        channelDescription: 'Daily reminder to create your todo list',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Try inexactAllowWhileIdle first (most reliable)
      try {
        await _notifications.zonedSchedule(
          todoListReminderId,
          '🌅 Good Morning! Plan Your Day',
          'Start your day right! Create your todo list and set your goals for today. ✨',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        developer.log(
          'Morning notification scheduled for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log(
          'Error scheduling morning notification: $e',
          name: 'NotificationService',
        );
        // Try exact scheduling as fallback
        try {
          await _notifications.zonedSchedule(
            todoListReminderId,
            '🌅 Good Morning! Plan Your Day',
            'Start your day right! Create your todo list and set your goals for today. ✨',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e2) {
          // Last resort: try without allowWhileIdle
          await _notifications.zonedSchedule(
            todoListReminderId,
            '🌅 Good Morning! Plan Your Day',
            'Start your day right! Create your todo list and set your goals for today. ✨',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error scheduling morning todo reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 09:00 PM (evening, Sri Lankan time) for expenses and todo completion
  static Future<void> scheduleEveningExpensesReminder() async {
    try {
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      // Schedule for 09:00 PM Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        21, // 9 PM (21:00)
        0, // 0 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        moneyManagerChannelId,
        'Money Manager Reminder',
        channelDescription: 'Daily reminder to update your money manager',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        ongoing: false,
        autoCancel: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Try inexactAllowWhileIdle first (most reliable)
      try {
        await _notifications.zonedSchedule(
          moneyManagerReminderId,
          '🌙 Evening Review Time',
          'Mark your expenses, update transactions, and check off completed todos! 📊✅',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        developer.log(
          'Evening notification scheduled for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
          name: 'NotificationService',
        );
      } catch (e) {
        developer.log(
          'Error scheduling evening notification: $e',
          name: 'NotificationService',
        );
        // Try exact scheduling as fallback
        try {
          await _notifications.zonedSchedule(
            moneyManagerReminderId,
            '🌙 Evening Review Time',
            'Mark your expenses, update transactions, and check off completed todos! 📊✅',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e2) {
          // Last resort: try without allowWhileIdle
          await _notifications.zonedSchedule(
            moneyManagerReminderId,
            '🌙 Evening Review Time',
            'Mark your expenses, update transactions, and check off completed todos! 📊✅',
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
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

  /// Show a test notification immediately (for testing)
  static Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
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
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification',
      'If you see this, notifications are working!',
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
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      // Check if it's past 06:00 AM today (morning notification)
      final morningTargetTime = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        6, // 6 AM
        0, // 0 minutes
      );

      // Check if it's past 09:00 PM today (evening notification)
      final eveningTargetTime = tz.TZDateTime(
        sriLankanLocation,
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
          await _notifications.show(
            todoListReminderId,
            '🌅 Good Morning! Plan Your Day',
            'Start your day right! Create your todo list and set your goals for today. ✨',
            NotificationDetails(
              android: AndroidNotificationDetails(
                todoListChannelId,
                'Todo List Reminder',
                channelDescription: 'Daily reminder to create your todo list',
                importance: Importance.max,
                priority: Priority.max,
                showWhen: true,
                enableVibration: true,
                playSound: true,
                icon: '@mipmap/ic_launcher',
                largeIcon: const DrawableResourceAndroidBitmap(
                  '@mipmap/ic_launcher',
                ),
              ),
            ),
          );
        }

        if (shouldTriggerEvening && hasMoneyManager) {
          await _notifications.show(
            moneyManagerReminderId,
            '🌙 Evening Review Time',
            'Mark your expenses, update transactions, and check off completed todos! 📊✅',
            NotificationDetails(
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
                icon: '@mipmap/ic_launcher',
                largeIcon: const DrawableResourceAndroidBitmap(
                  '@mipmap/ic_launcher',
                ),
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
  static Future<void> rescheduleAllNotifications() async {
    final hasPermission = await _requestPermissions();
    if (hasPermission) {
      await scheduleDefaultNotifications();
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
