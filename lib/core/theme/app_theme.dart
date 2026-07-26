import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryBlueDark = Color(0xFF357ABD);
  static const Color softGreen = Color(0xFF7ED321);
  static const Color warmNeutral = Color(0xFFF5F7FA);
  static const Color authGradientTop = Color(0xFFEBF4FF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static ElevatedButtonThemeData _buttonTheme(Color color) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  static NavigationBarThemeData _navBarTheme({
    required Color background,
    required Color indicator,
    required Brightness brightness,
  }) {
    return NavigationBarThemeData(
      elevation: 0,
      backgroundColor: background,
      indicatorColor: indicator,
      iconTheme: WidgetStateProperty.all(const IconThemeData()),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: brightness == Brightness.dark
              ? (states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.grey[400])
              : null,
        );
      }),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isLight ? warmNeutral : darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: brightness,
        primary: primaryBlue,
        surface: isLight ? warmNeutral : darkSurface,
      ),
    );

    return base.copyWith(
      // Poppins for text only — never set fontFamily on ThemeData root (breaks Material Icons).
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(),
      primaryIconTheme: IconThemeData(color: isLight ? textPrimary : Colors.white),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isLight ? textPrimary : Colors.white),
      ),
      navigationBarTheme: _navBarTheme(
        background: isLight ? Colors.white : darkSurface,
        indicator: primaryBlue.withValues(alpha: isLight ? 0.12 : 0.25),
        brightness: brightness,
      ),
      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: primaryBlue,
        suffixIconColor: isLight ? textSecondary : Colors.grey[400],
      ),
      elevatedButtonTheme: _buttonTheme(primaryBlue),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
