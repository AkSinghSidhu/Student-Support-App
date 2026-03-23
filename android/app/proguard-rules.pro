# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Hive
-keep class hive.** { *; }
-keep class com.hivedb.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,
    androidx.work.WorkerParameters);
}

# Keep app models (update package when applicationId changes)
-keep class com.example.student_support_app.** { *; }

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
