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
      // Initialize timezone
      tz.initializeTimeZones();

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
    );

    // Todo List Reminder Channel
    const todoListChannel = AndroidNotificationChannel(
      todoListChannelId,
      'Todo List Reminder',
      description: 'Daily reminder to create your todo list',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
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
    } else {
      final status = await Permission.notification.request();
      hasNotificationPermission = status.isGranted;
    }

    // For Android 12+, also check exact alarm permission
    // Note: This permission might not be available on all devices
    try {
      // Check if exact alarm permission is needed and available
      // The permission_handler package might not support this directly
      // but we'll try to request it if possible
    } catch (e) {
      developer.log(
        'Error checking exact alarm permission: $e',
        name: 'NotificationService',
      );
    }

    return hasNotificationPermission;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // You can navigate to specific screens based on notification ID
  }

  /// Schedule default notifications:
  /// - 12:00 AM daily (Sri Lankan time): Money manager reminder
  /// - 12:00 AM daily (Sri Lankan time): Todo list creation reminder
  static Future<void> scheduleDefaultNotifications() async {
    try {
      // Cancel existing notifications first
      await _notifications.cancel(moneyManagerReminderId);
      await _notifications.cancel(todoListReminderId);

      // Schedule 12:00 AM money manager reminder
      await scheduleMoneyManagerReminder();

      // Schedule 12:00 AM todo list reminder
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

  /// Schedule daily notification at 12:00 AM (midnight, Sri Lankan time) for money manager reminder
  static Future<void> scheduleMoneyManagerReminder() async {
    try {
      // Get current time in Sri Lankan timezone
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      // Schedule for 12:00 AM (midnight) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        0, // 12 AM (midnight)
        10, // 0 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      developer.log(
        'Scheduling money manager reminder for: $scheduledDate (Sri Lankan time)',
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
        'Money manager reminder scheduled',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling money manager reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedule daily notification at 12:00 AM (midnight, Sri Lankan time) for todo list creation reminder
  static Future<void> scheduleTodoListReminder() async {
    try {
      // Get current time in Sri Lankan timezone
      final sriLankanLocation = tz.getLocation('Asia/Colombo');
      final now = tz.TZDateTime.now(sriLankanLocation);

      // Schedule for 12:00 AM (midnight) Sri Lankan time
      var scheduledDate = tz.TZDateTime(
        sriLankanLocation,
        now.year,
        now.month,
        now.day,
        0, // 12 AM (midnight)
        10, // 0 minutes
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      developer.log(
        'Scheduling todo list reminder for: $scheduledDate (Sri Lankan time)',
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
        'Todo list reminder scheduled',
        name: 'NotificationService',
      );
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
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
