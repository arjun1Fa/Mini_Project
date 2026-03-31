import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base palette
  static const cream = Color(0xFFF5F0E8);
  static const creamDark = Color(0xFFEDE6D6);
  static const ink = Color(0xFF1A1714);
  static const inkSoft = Color(0xFF3D3530);
  static const inkMuted = Color(0xFF7A6F66);
  static const inkFaint = Color(0xFFB5AC9F);

  // Accent colors
  static const leaf = Color(0xFF2D6A4F);
  static const leafLight = Color(0xFF52B788);
  static const leafPale = Color(0xFFD8F3DC);
  static const amber = Color(0xFFE76F51);
  static const amberPale = Color(0xFFFDE8DF);
  static const gold = Color(0xFFC9A84C);
  static const goldPale = Color(0xFFFDF3D9);
  static const sky = Color(0xFF457B9D);
  static const skyPale = Color(0xFFDAF0FF);

  // UI
  static const border = Color(0x1A1A1714);
  static const borderMid = Color(0x2E1A1714);
  static const white = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.leaf,
          surface: AppColors.cream,
          onSurface: AppColors.ink,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
          displayMedium: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
          displaySmall: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
          headlineLarge: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
          headlineMedium: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
          headlineSmall: GoogleFonts.dmSerifDisplay(color: AppColors.ink),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.cream.withOpacity(0.9),
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.ink,
          selectedIconTheme: const IconThemeData(color: AppColors.white),
          unselectedIconTheme: IconThemeData(color: AppColors.inkFaint),
          selectedLabelTextStyle: GoogleFonts.dmSans(
              color: AppColors.white, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle:
              GoogleFonts.dmSans(color: AppColors.inkFaint),
          indicatorColor: AppColors.leaf,
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.leafLight, width: 1.5),
          ),
          hintStyle: GoogleFonts.dmSans(color: AppColors.inkFaint),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
      );
}
