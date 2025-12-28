import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// FinPadi Color Palette (from Figma Design)
const Color FinPadi_NavyBlue = Color(0xFF1D3A70);       // Primary color
const Color FinPadi_ActionOrange = Color(0xFFF56C2A);   // Accent/CTA color
const Color FinPadi_White = Color(0xFFFFFFFF);          // Card backgrounds
const Color FinPadi_Background = Color(0xFFF8F9FA);     // Light grey background
const Color FinPadi_TextPrimary = Color(0xFF000000);    // Titles
const Color FinPadi_TextSecondary = Color(0xFF4F4F4F);  // Body text
const Color FinPadi_TextLabel = Color(0xFF828282);      // Labels
const Color FinPadi_Border = Color(0xFFE5E5E5);         // Card borders
const Color FinPadi_SuccessGreen = Color(0xFF27AE60);   // Success states
const Color FinPadi_ErrorRed = Color(0xFFEB5757);       // Error states

ThemeData finPadiTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: FinPadi_NavyBlue,
      secondary: FinPadi_ActionOrange,
      surface: FinPadi_White,
      error: FinPadi_ErrorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: FinPadi_TextPrimary,
    ),
    scaffoldBackgroundColor: FinPadi_Background,
    
    // Typography - Clean modern sans-serif (Inter)
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary),
      displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: FinPadi_TextPrimary),
      headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: FinPadi_TextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: FinPadi_TextSecondary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: FinPadi_TextSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: FinPadi_TextLabel),
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: FinPadi_Background,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: FinPadi_NavyBlue),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: FinPadi_TextPrimary,
      ),
    ),
    
    // Card Theme - White cards with 16px rounded corners
    cardTheme: CardThemeData(
      color: FinPadi_White,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    
    // Elevated Button Theme - Primary Navy Blue
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FinPadi_NavyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Capsule shape
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FinPadi_NavyBlue,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: FinPadi_NavyBlue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FinPadi_NavyBlue,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration Theme - Minimalist outlined fields
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: FinPadi_White,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FinPadi_Border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FinPadi_Border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FinPadi_NavyBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FinPadi_ErrorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FinPadi_ErrorRed, width: 2),
      ),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextLabel),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: FinPadi_TextLabel),
      prefixIconColor: FinPadi_TextLabel,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: FinPadi_White,
      selectedItemColor: FinPadi_NavyBlue,
      unselectedItemColor: FinPadi_TextLabel,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FinPadi_ActionOrange,
     foregroundColor: Colors.white,
      elevation: 4,
    ),
  );
}

// Backward compatibility mappings for existing screens
// Maps old Banking_ constants to new FinPadi constants
const Color Banking_Primary = FinPadi_NavyBlue;
const Color Banking_Secondary = Color(0xFF2A4A85); // Slightly lighter navy
const Color Banking_Accent = FinPadi_ActionOrange;
const Color Banking_app_Background = FinPadi_Background;
const Color Banking_Surface = FinPadi_White;
const Color Banking_Border = FinPadi_Border;
const Color Banking_TextColorPrimary = FinPadi_TextPrimary;
const Color Banking_TextColorSecondary = FinPadi_TextSecondary;
const Color Banking_SuccessGreen = FinPadi_SuccessGreen;
const Color Banking_ErrorRed = FinPadi_ErrorRed;
const Color Banking_WarningYellow = Color(0xFFF2994A);

/// Legacy theme function for backward compatibility
ThemeData bankingTheme() => finPadiTheme();
