# 🛡️ SECURITY: ProGuard Configuration for TipsyTheoryy

# Flutter Specifics
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent obfuscation of Firebase classes to avoid initialization errors
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.libraries.maps.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# Pinput (Auth)
-keep class com.ib.pinput.** { *; }

# SSL Pinning Library
-keep class com.dieam.reactnativegooglesignin.** { *; }
-keep class com.http_certificate_pinning.** { *; }

# 🛡️ FIX: Prevent Obfuscation of JSON Models
# If models are obfuscated, the field names (e.g., "id", "name") change,
# which breaks communication with the backend JSON.
-keep class com.tipsytheoryy.tipsytheoryy_app.models.** { *; }
-keepclassmembers class com.tipsytheoryy.tipsytheoryy_app.models.** { *; }

# 🛡️ FIX: Missing Play Core classes
# Flutter's embedding references these classes for deferred components,
# but they are often missing in standard builds.
-dontwarn com.google.android.play.core.**

# Maintain annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
