# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Timezone
-keep class org.threeten.bp.** { *; }
-keep class java.time.** { *; }

# Play Core tasks (Flutter deferred components not used)
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

