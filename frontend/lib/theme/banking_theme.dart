import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// FinPadi Premium Color Palette
const Color FinPadi_MidnightBlue = Color(0xFF0F172A);   // Primary: Deep richness
const Color FinPadi_ElectricTeal = Color(0xFF0EA5E9);   // Accent: Vibration & Energy
const Color FinPadi_SurfaceWhite = Color(0xFFFFFFFF);   // Pure white
const Color FinPadi_Background = Color(0xFFF8FAFC);     // Very subtle cool grey
const Color FinPadi_TextPrimary = Color(0xFF1E293B);    // Slate 800
const Color FinPadi_TextSecondary = Color(0xFF64748B);  // Slate 500
const Color FinPadi_Border = Color(0xFFE2E8F0);         // Slate 200
const Color FinPadi_Success = Color(0xFF10B981);        // Emerald 500
const Color FinPadi_Error = Color(0xFFEF4444);          // Red 500

// Compatibility Aliases (to fix build errors in other files)
const Color FinPadi_NavyBlue = FinPadi_MidnightBlue;
const Color FinPadi_ActionOrange = Color(0xFFF97316);   // Orange 500 (kept for mandates screen)
const Color FinPadi_ErrorRed = FinPadi_Error;
const Color FinPadi_SuccessGreen = FinPadi_Success;
const Color FinPadi_TextLabel = FinPadi_TextSecondary;

ThemeData finPadiTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: FinPadi_MidnightBlue,
      onPrimary: Colors.white,
      secondary: FinPadi_ElectricTeal,
      onSecondary: Colors.white,
      error: FinPadi_Error,
      onError: Colors.white,
      surface: FinPadi_SurfaceWhite,
      onSurface: FinPadi_TextPrimary,
      surfaceContainerHighest: FinPadi_Background,
    ),
    scaffoldBackgroundColor: FinPadi_Background,

    // Typography: Outfit for headers, Inter for body
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary, letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: FinPadi_TextPrimary, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: FinPadi_TextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.normal, color: FinPadi_TextSecondary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.normal, color: FinPadi_TextSecondary, height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: FinPadi_TextSecondary, letterSpacing: 0.5,
      ),
    ),

    // Card Theme: Subtle shadows, pillowy feel
    cardTheme: CardThemeData(
      color: FinPadi_SurfaceWhite,
      elevation: 0, // We'll often use manual shadows, but for default:
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: FinPadi_Border, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FinPadi_MidnightBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: FinPadi_MidnightBlue.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FinPadi_MidnightBlue,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        side: const BorderSide(color: FinPadi_Border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FinPadi_SurfaceWhite,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FinPadi_Border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FinPadi_Border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FinPadi_ElectricTeal, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: FinPadi_TextSecondary),
    ),
    
    // Bottom Nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: FinPadi_SurfaceWhite,
      selectedItemColor: FinPadi_ElectricTeal,
      unselectedItemColor: FinPadi_TextSecondary,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
    ),
  );
}

// Backward Compatibility / Aliases
const Color Banking_Primary = FinPadi_MidnightBlue;
const Color Banking_Secondary = Color(0xFF1E293B); // Slate 800
const Color Banking_Accent = FinPadi_ElectricTeal;
const Color Banking_app_Background = FinPadi_Background;
const Color Banking_Surface = FinPadi_SurfaceWhite;
const Color Banking_Border = FinPadi_Border;
const Color Banking_TextColorPrimary = FinPadi_TextPrimary;
const Color Banking_TextColorSecondary = FinPadi_TextSecondary;
const Color Banking_SuccessGreen = FinPadi_Success;
const Color Banking_ErrorRed = FinPadi_Error;
const Color Banking_WarningYellow = Color(0xFFF59E0B); // Amber 500

ThemeData bankingTheme() => finPadiTheme();
