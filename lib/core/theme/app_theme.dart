import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Define Primary Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color softGreen = Color(0xFF7ED321);
  static const Color warmNeutral = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3436);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
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
}

