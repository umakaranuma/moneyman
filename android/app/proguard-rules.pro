# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# flutter_local_notifications - required for scheduled notifications in release APK
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }
# Keep BroadcastReceivers so system can deliver scheduled notifications
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsReceiver { *; }
# Gson (used for serializing scheduled notification payloads) - avoid TypeToken stripping
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Timezone - Keep all timezone related classes
-keep class org.threeten.bp.** { *; }
-keep class java.time.** { *; }
-keep class timezone.** { *; }
-keep class com.beyondeye.kbloc.** { *; }

# Play Core tasks (Flutter deferred components not used)
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

