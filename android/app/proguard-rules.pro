# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.** { *; }

# Keep notification receivers
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsReceiver { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep notification-related classes
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Activity

# Keep timezone classes
-keep class org.threeten.bp.** { *; }
-keep class java.time.** { *; }
-keep class com.github.benoitdion.ln.** { *; }
-keep class org.joda.time.** { *; }

# Keep timezone data
-keep class **.timezone.** { *; }
-keep class **.tzdata.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class *
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Core - Keep classes for split install features
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter Play Store split application classes
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep Play Core split install classes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Suppress warnings for Play Core (optional classes)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

