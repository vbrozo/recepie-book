import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Headings/recipe titles use Newsreader (serif); UI/body/labels use
/// Hanken Grotesque (sans). Both support Croatian diacritics via Google
/// Fonts' latin-ext subset.
class AppTypography {
  AppTypography._();

  static TextStyle serif({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.inkSecondary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.hankenGrotesque(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Uppercase eyebrow labels ("KORAK 1 OD 6", "NAZIV RECEPTA").
  static TextStyle eyebrow({Color color = AppColors.muted}) {
    return sans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.6,
    );
  }

  static TextTheme textTheme() {
    return TextTheme(
      displaySmall: serif(fontSize: 44),
      headlineLarge: serif(fontSize: 34),
      headlineMedium: serif(fontSize: 30),
      headlineSmall: serif(fontSize: 24),
      titleLarge: serif(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: sans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyLarge: sans(fontSize: 16, color: AppColors.inkSecondary),
      bodyMedium: sans(fontSize: 14, color: AppColors.inkSecondary),
      bodySmall: sans(fontSize: 13, color: AppColors.muted),
      labelLarge: sans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      labelMedium: sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
    );
  }
}
