import 'package:flutter/material.dart';

class AppTheme {
  // Premium Color Palette
  static const Color primaryColor = Color(0xFF0D3B30); // Deep Forest Green
  static const Color accentColor = Color(0xFFF97316);  // Vibrant Orange/Amber
  static const Color goldColor = Color(0xFFC5A059);    // Luxury Gold
  
  // Light Theme Specifics
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Specifics (Luxury Midnight)
  static const Color darkBackground = Color(0xFF051410); // Ultra Deep Green-Black
  static const Color darkSurface = Color(0xFF0C241E);    // Deep Forest Surface
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Shimmer Colors
  static Color get shimmerBase => Colors.grey.shade100;
  static Color get shimmerHighlight => Colors.white;
  static Color get darkShimmerBase => const Color(0xFF0C241E);
  static Color get darkShimmerHighlight => const Color(0xFF1B3D35);

  // Deprecated: Use Theme.of(context).scaffoldBackgroundColor or cardColor instead
  static Color get backgroundColor => lightBackground;
  static Color get surfaceColor => lightSurface;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      canvasColor: lightSurface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        brightness: Brightness.light,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(Brightness.light),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
      textTheme: _textTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      canvasColor: darkSurface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        brightness: Brightness.dark,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: accentColor,
        contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(Brightness.dark),
      inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
      textTheme: _textTheme(Brightness.dark),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final Color color = brightness == Brightness.light ? lightTextPrimary : darkTextPrimary;
    return TextTheme(
      headlineLarge: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: color, fontWeight: FontWeight.w900),
      titleLarge: TextStyle(color: color, fontWeight: FontWeight.w800),
      bodyLarge: TextStyle(color: color),
      bodyMedium: TextStyle(color: color),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Brightness brightness) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkSurface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 14),
    );
  }

  static const String midnightMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#143a33"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#183e35"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1b4d42"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b4d42"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f564b"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]''';
}
