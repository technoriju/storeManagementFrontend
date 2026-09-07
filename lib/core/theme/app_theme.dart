import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Reference UI Colors
  static const Color primaryColor = Color(0xFFFF9F43); // Orange from screenshot
  static const Color primaryLight = Color(0xFFFFF5EA);
  static const Color secondaryColor = Color(0xFF2A2D3E);
  static const Color bgColor = Color(0xFF212332);
  static const Color errorColor = Color(0xFFDE350B);

  // Light Theme equivalents
  static const Color lightBgColor = Color(0xFFF4F5F7); // or F8F9FA
  static const Color lightSecondaryColor = Colors.white;

  // Spacing
  static const double defaultPadding = 16.0;

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgColor,
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: Colors.white),
      canvasColor: secondaryColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: secondaryColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: secondaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding * 1.5,
            vertical: defaultPadding,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: secondaryColor,
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.bold),
        dataTextStyle: GoogleFonts.nunito(color: Colors.white70),
        dividerThickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBgColor,
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme)
          .apply(bodyColor: const Color(0xFF333333)),
      canvasColor: lightSecondaryColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: lightSecondaryColor,
        surface: lightSecondaryColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSecondaryColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: lightSecondaryColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding * 1.5,
            vertical: defaultPadding,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
