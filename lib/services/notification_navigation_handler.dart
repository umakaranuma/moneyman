import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// Holds the pending route when the app is opened from a notification tap.
/// - Morning (todo) notification → open todos screen; back goes to home.
/// - Evening (money manager) or other → open home.
/// - Reminder notification → open reminders list with that reminder highlighted.
/// Uses Hive (same as rest of app) for persistence when tap happens in background isolate.
class NotificationNavigationHandler {
  /// In-memory pending route (foreground tap).
  static String? _pendingRoute;

  /// Set pending route from main isolate (foreground notification tap).
  static void setPendingRoute(String route) {
    _pendingRoute = route;
  }

  /// Set pending route from background isolate (app was in background or terminated).
  /// Initializes Hive with app documents path and writes to the same settings box.
  static Future<void> setPendingRouteFromBackground(String route) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      final box = await Hive.openBox(StorageService.settingsBoxName);
      await box.put(StorageService.pendingNotificationRouteKey, route);
      await box.close();
    } catch (_) {
      // Ignore; main isolate may use getNotificationAppLaunchDetails when app opens
    }
  }

  /// Take and clear the pending route. Returns null if none.
  /// Checks in-memory first, then Hive (for tap when app was in background).
  static Future<String?> takePendingRoute() async {
    final inMemory = _pendingRoute;
    if (inMemory != null && inMemory.isNotEmpty) {
      _pendingRoute = null;
      return inMemory;
    }
    var stored = await StorageService.getAndClearPendingNotificationRoute();
    if (stored == null || stored.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      stored = await StorageService.getAndClearPendingNotificationRoute();
    }
    return stored;
  }

  /// Route constants for notification types.
  static const String routeTodos = 'todos';
  static const String routeHome = 'home';

  static String routeRemindersWithHighlight(int notificationId) =>
      'reminders|$notificationId';

  /// Map notification id (and optional payload) to a navigation route.
  /// Used by both foreground and background tap handlers.
  static String? routeFromNotification(int id, String? payload) {
    if (id == 2) return routeTodos; // todoListReminderId
    if (id == 1) return routeHome; // moneyManagerReminderId
    if (id >= 10000) return routeRemindersWithHighlight(id);
    return null;
  }
}
