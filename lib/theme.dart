import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFF6C63FF); // Deep Purple
  static const Color secondaryAccent = Color(0xFFFF6584); // Vibrant Pink
  static const Color neonCyan = Color(0xFF00FFCC); // Accent Cyan
  
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF2D3748);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        tertiary: neonCyan,
        surface: darkSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
        titleLarge: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w600, color: darkText),
        titleMedium: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: darkText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 8,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: neonCyan,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        secondary: secondaryAccent,
        tertiary: neonCyan,
        surface: lightSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.bold, color: lightText),
        titleLarge: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w600, color: lightText),
        titleMedium: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: lightText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: lightText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 8,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
        iconTheme: const IconThemeData(color: lightText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryAccent,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
