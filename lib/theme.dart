import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bg = Color(0xFFEFEFEB);
  static const surface = Color(0xFFE8E6E0);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFF2D2D28);
  static const muted = Color(0xFF8A8878);
  static const green = Color(0xFF3A6B4A);
  static const red = Color(0xFF8B3A3A);
  static const border = Color(0x14000000);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.light(
          background: bg,
          surface: card,
          primary: accent,
          secondary: green,
          error: red,
        ),
        scaffoldBackgroundColor: bg,
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: accent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: muted),
        ),
      );

  static TextStyle get displayFont => GoogleFonts.dmSerifDisplay(
        color: accent,
      );
}
