import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Headings/recipe titles use Newsreader (serif); UI/body/labels use
/// Hanken Grotesque (sans). Both support Croatian diacritics via Google
/// Fonts' latin-ext subset.
///
/// Bound to a specific [AppColorPalette] so default text colors
/// (`color` left unset) resolve to the right ink/muted tone for the
/// current light/dark mode. Access via `context.typography.serif(...)` —
/// the [AppTypographyContext] extension below — rather than constructing
/// this directly, except in `app.dart` where both the light and dark
/// `ThemeData.textTheme` are built up front from [AppColorPalette.light]
/// and [AppColorPalette.dark] before any widget (and thus any context)
/// exists yet.
class AppTypography {
  const AppTypography(this.colors);

  final AppColorPalette colors;

  TextStyle serif({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? colors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? colors.inkSecondary,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Uppercase eyebrow labels ("KORAK 1 OD 6", "NAZIV RECEPTA").
  TextStyle eyebrow({Color? color}) {
    return sans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: color ?? colors.muted,
      letterSpacing: 0.6,
    );
  }

  TextTheme textTheme() {
    return TextTheme(
      displaySmall: serif(fontSize: 44),
      headlineLarge: serif(fontSize: 34),
      headlineMedium: serif(fontSize: 30),
      headlineSmall: serif(fontSize: 24),
      titleLarge: serif(fontSize: 19, fontWeight: FontWeight.w700, color: colors.ink),
      titleMedium: sans(fontSize: 16, fontWeight: FontWeight.w600, color: colors.ink),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w600, color: colors.ink),
      bodyLarge: sans(fontSize: 16, color: colors.inkSecondary),
      bodyMedium: sans(fontSize: 14, color: colors.inkSecondary),
      bodySmall: sans(fontSize: 13, color: colors.muted),
      labelLarge: sans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      labelMedium: sans(fontSize: 14, fontWeight: FontWeight.w600, color: colors.ink),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w600, color: colors.muted),
    );
  }
}

/// `context.typography.serif(...)` / `.sans(...)` — bound to whichever
/// [AppColorPalette] is active for the current theme, so unset `color`
/// arguments default to the right tone automatically.
extension AppTypographyContext on BuildContext {
  AppTypography get typography => AppTypography(colors);
}
