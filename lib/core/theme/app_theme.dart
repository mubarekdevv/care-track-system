import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Light Mode colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color softGreen = Color(0xFF7ED321);
  static const Color warmNeutral = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  //1. Dark Mode colors

  static const Color darkBackground  = Color(0xFF121212); // Deep Black/Grey
  static const Color darkSurface = Color(0xFF1E1E1E); // Card color
  static const Color primaryBlueDark = Color(0xFF64B5F6); // Lighter blue for dark mode

  //Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: softGreen,
        surface: warmNeutral,
      ),
      // 2. Set Global Font
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge:
            const TextStyle(color: textDark, fontWeight: FontWeight.bold),
      ),
      // 3. Global Button Style (Rounded)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryBlue,
        primary: primaryBlueDark,
        surface: darkSurface,
        background: darkBackground,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        scaffoldBackgroundColor: darkBackground
    );
  }
}

