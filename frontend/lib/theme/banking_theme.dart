import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors adapted from the banking template
const Banking_Primary = Color(0xFFff9a8d);
const Banking_Secondary = Color(0xFF4a536b);
const Banking_TextColorPrimary = Color(0xFF070706);
const Banking_TextColorSecondary = Color(0xFF747474);
const Banking_TextColorWhite = Color(0xFFffffff);
const Banking_TextColorYellow = Color(0xFFff8c42);
const Banking_TextLightGreenColor = Color(0xFF8ed16f);
const Banking_app_Background = Color(0xFFf3f5f9);
const Banking_view_color = Color(0XFFDADADA);

ThemeData bankingTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Banking_Primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Banking_app_Background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Banking_Secondary,
      foregroundColor: Banking_TextColorWhite,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: Banking_TextColorPrimary,
      displayColor: Banking_TextColorPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Banking_Primary,
        foregroundColor: Banking_TextColorWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const UnderlineInputBorder(),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Banking_view_color.withOpacity(0.8)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Banking_Secondary, width: 1),
      ),
      labelStyle: GoogleFonts.poppins(color: Banking_TextColorSecondary),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    dividerTheme: const DividerThemeData(color: Banking_view_color),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Banking_Primary,
      unselectedItemColor: Banking_TextColorSecondary,
      backgroundColor: Colors.white,
      elevation: 8,
    ),
  );
}
