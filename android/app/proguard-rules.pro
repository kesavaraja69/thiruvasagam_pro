# ============================================================
# Thiruvasagam Pro - ProGuard / R8 Keep Rules
# ============================================================

# --- androidx.work (WorkManager) ---
# Used by flutter_local_notifications for scheduled notifications.
# R8 strips WorkDatabase and its Room implementation without these rules.
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.background.** { *; }
-keep class androidx.work.impl.background.** { *; }

# --- androidx.room ---
# WorkManager's database is built on Room. Room generates subclasses
# at runtime via reflection — R8 must not rename or strip them.
-keep class androidx.room.** { *; }

# --- androidx.startup ---
# The crash originates from InitializationProvider (androidx.startup).
-keep class androidx.startup.** { *; }

# --- encrypt / pointycastle ---
# The encrypt package uses pointycastle for AES. pointycastle registers
# cipher implementations by class name via reflection.
-keep class org.bouncycastle.** { *; }
-keep class com.pointycastle.** { *; }
-dontwarn org.bouncycastle.**
-dontwarn com.pointycastle.**

# --- flutter_secure_storage ---
# Keys live in Android Keystore and the plugin is loaded by name.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# --- Google Mobile Ads ---
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# --- Google Play Core (in-app updates) ---
# Used by the in_app_update plugin. Play Core resolves its task listeners
# reflectively, so R8 must not rename or strip these classes.
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- in_app_update plugin ---
-keep class de.ffuf.in_app_update.** { *; }

# --- package_info_plus plugin ---
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# --- audio_service / just_audio background playback ---
# The media service builds notification controls reflectively and resolves
# drawable names at runtime. Keep the plugin classes through R8.
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# --- flutter_local_notifications ---
-keep class com.dexterous.** { *; }

# --- sqflite ---
-keep class com.ttllabs.** { *; }

# --- Keep all Flutter plugin generated classes ---
-keep class io.flutter.plugins.** { *; }

# --- Keep enum values (used by Room and WorkManager) ---
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Keep native methods ---
-keepclasseswithmembernames class * {
    native <methods>;
}
