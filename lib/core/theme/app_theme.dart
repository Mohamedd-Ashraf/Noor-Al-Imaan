import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme({required bool isArabicUi}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.onSurface,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        titleTextStyle: (isArabicUi ? GoogleFonts.cairo : GoogleFonts.poppins)(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      textTheme:
          (isArabicUi
                  ? GoogleFonts.cairoTextTheme
                  : GoogleFonts.poppinsTextTheme)(ThemeData.light().textTheme)
              .copyWith(
                bodySmall:
                    (isArabicUi ? GoogleFonts.cairo : GoogleFonts.poppins)(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
              ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme({required bool isArabicUi}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Color(0xFF121212),
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: Color(0xFFE0E0E0),
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        titleTextStyle: (isArabicUi ? GoogleFonts.cairo : GoogleFonts.poppins)(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      textTheme:
          (isArabicUi
                  ? GoogleFonts.cairoTextTheme
                  : GoogleFonts.poppinsTextTheme)(ThemeData.dark().textTheme)
              .copyWith(
                bodySmall:
                    (isArabicUi ? GoogleFonts.cairo : GoogleFonts.poppins)(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFFB0B0B0),
                    ),
              ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: (isArabicUi ? GoogleFonts.cairo : GoogleFonts.poppins)(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
