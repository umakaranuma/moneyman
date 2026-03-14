# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Notification receivers (must not be removed by R8)
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsReceiver { *; }

# Alarm manager & PendingIntent used for scheduling
-keep class android.app.AlarmManager { *; }
-keep class android.app.AlarmManager$AlarmClockInfo { *; }
-keep class android.app.PendingIntent { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Timezone plugin
-keep class com.bossylobster.** { *; }

# Work manager (used by some plugins)
-keep class androidx.work.** { *; }

# Play Core warnings
-dontwarn com.google.android.play.core.tasks.**
