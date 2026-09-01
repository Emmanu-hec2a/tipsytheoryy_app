# ── Flutter core ──────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Firebase + Google Play Services ──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.** { *; }

# ── Google Maps ───────────────────────────────────────────────────────────────
-keep class com.google.android.libraries.maps.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# ── flutter_secure_storage ────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── Geolocator ────────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── URL Launcher ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── App package (com.pourexpress.sip) ────────────────────────────────────────
-keep class com.pourexpress.sip.** { *; }
-keepclassmembers class com.pourexpress.sip.** {
    <fields>;
    <methods>;
}

# ── Play Core (suppress missing class warnings) ───────────────────────────────
-dontwarn com.google.android.play.core.**

# ── Remove these — React Native libraries, wrong ecosystem ───────────────────
# -keep class com.dieam.reactnativegooglesignin.** { *; }   ← REMOVED
# -keep class com.http_certificate_pinning.** { *; }         ← REMOVED
# -keep class com.ib.pinput.** { *; }                        ← REMOVED (Dart widget)

# ── Attributes ────────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses