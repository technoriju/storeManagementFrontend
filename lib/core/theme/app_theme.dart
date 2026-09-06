import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF0052CC);
  static const Color secondaryColor = Color(0xFF172B4D);
  static const Color backgroundColorLight = Color(0xFFF4F5F7);
  static const Color surfaceColorLight = Colors.white;
  static const Color backgroundColorDark = Color(0xFF121212);
  static const Color surfaceColorDark = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFDE350B);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Typography
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColorLight,
        error: errorColor,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorLight,
        foregroundColor: secondaryColor,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceColorLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingMd, vertical: spacingSm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: surfaceColorLight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: secondaryColor),
        contentTextStyle:
            _textTheme.bodyMedium?.copyWith(color: secondaryColor),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: _textTheme.labelLarge
            ?.copyWith(color: secondaryColor, fontWeight: FontWeight.bold),
        dataTextStyle: _textTheme.bodyMedium?.copyWith(color: secondaryColor),
        dividerThickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColorDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Colors.white70,
        surface: surfaceColorDark,
        error: errorColor,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorDark,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceColorDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingMd, vertical: spacingSm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: surfaceColorDark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColorDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.white),
        contentTextStyle:
            _textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: _textTheme.labelLarge
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        dataTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white70),
        dividerThickness: 1,
      ),
    );
  }
}
