# Flutter ProGuard rules
# Keep Flutter wrappers
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Hive
-keep class com.hive.** { *; }
-dontwarn com.hive.**

# Keep flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Keep flutter_background_service
-keep class id.flutter.** { *; }
-dontwarn id.flutter.**

# Keep file_picker
-keep class com.mr.** { *; }
-dontwarn com.mr.**

# Keep open_filex
-keep class com.crazecoder.** { *; }
-dontwarn com.crazecoder.**

# Keep saf
-keep class com.kineapps.** { *; }
-dontwarn com.kineapps.**

# Keep Play Core classes (for Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
