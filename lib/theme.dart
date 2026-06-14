import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFF00FFCC); // Neon Cyan
  static const Color secondaryAccent = Color(0xFFB026FF); // Neon Purple
  
  static const Color darkBackground = Color(0xFF0B0D17);
  static const Color darkCard = Color(0x20FFFFFF); // Glassmorphism base
  static const Color darkText = Colors.white;
  
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF111827);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: darkBackground,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
        titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: darkText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: darkText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1F2937).withOpacity(0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: primaryAccent,
        unselectedItemColor: Colors.white54,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: secondaryAccent,
      colorScheme: const ColorScheme.light(
        primary: secondaryAccent,
        secondary: primaryAccent,
        surface: lightBackground,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: lightText),
        titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: lightText),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: lightText),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: lightText),
        iconTheme: const IconThemeData(color: lightText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: secondaryAccent,
        unselectedItemColor: Colors.black54,
      ),
      useMaterial3: true,
    );
  }
}
