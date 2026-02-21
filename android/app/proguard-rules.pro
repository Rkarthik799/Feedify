# Keep Flutter engine and plugin entry points used by reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Keep MainActivity to avoid obfuscation-related launch issues.
-keep class com.example.social_media.MainActivity { *; }

# Keep Kotlin metadata and annotation attributes used at runtime.
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Keep video player plugin classes (uses reflection on some Android versions).
-keep class io.flutter.plugins.videoplayer.** { *; }
