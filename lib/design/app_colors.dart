import 'package:flutter/material.dart';

/// Design tokens for one visual mode (light or dark) — see [light] and
/// [dark]. Registered on `ThemeData.extensions` in `app.dart`; read via
/// `context.colors.xxx` (the [AppColorPaletteContext] extension below),
/// never by constructing/comparing an [AppColorPalette] directly.
///
/// Orange is the only accent color (CTAs, favorites, active nav state);
/// olive is used only for category/tag chips — same rule as the original
/// Figma handoff, just re-expressed per-mode instead of as flat constants.
class AppColorPalette extends ThemeExtension<AppColorPalette> {
  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.hairline,
    required this.ink,
    required this.inkSecondary,
    required this.muted,
    required this.mutedAlt,
    required this.faint,
    required this.faintAlt,
    required this.orange,
    required this.orangeDeep,
    required this.orangeSoft,
    required this.orangeSoftAlt,
    required this.olive,
    required this.oliveSoft,
    required this.diffSoft,
    required this.diffText,
    required this.outlineButtonBorder,
    required this.orangeShadow,
    required this.orangeButtonShadow,
  });

  final Color background;
  final Color surface;
  final Color hairline;

  final Color ink;
  final Color inkSecondary;
  final Color muted;
  final Color mutedAlt;
  final Color faint;
  final Color faintAlt;

  final Color orange;
  final Color orangeDeep;
  final Color orangeSoft;
  final Color orangeSoftAlt;

  final Color olive;
  final Color oliveSoft;

  final Color diffSoft;
  final Color diffText;

  final Color outlineButtonBorder;

  final Color orangeShadow;
  final Color orangeButtonShadow;

  static const light = AppColorPalette(
    background: Color(0xFFFAF6EF),
    surface: Color(0xFFFFFFFF),
    hairline: Color(0xFFEFE7D6),
    ink: Color(0xFF2B2A26),
    inkSecondary: Color(0xFF4A463E),
    muted: Color(0xFF8C8472),
    mutedAlt: Color(0xFFA79E8C),
    faint: Color(0xFFB4AB98),
    faintAlt: Color(0xFFC9C0AE),
    orange: Color(0xFFE8794A),
    orangeDeep: Color(0xFFC85E32),
    orangeSoft: Color(0xFFFBEBE0),
    orangeSoftAlt: Color(0xFFFBEDE2),
    olive: Color(0xFF6E7355),
    oliveSoft: Color(0xFFEEF0E4),
    diffSoft: Color(0xFFF9E6DC),
    diffText: Color(0xFFC85E32),
    outlineButtonBorder: Color(0xFFE4DAC7),
    orangeShadow: Color(0x6BE8794A),
    orangeButtonShadow: Color(0x52E8794A),
  );

  /// Warm-dark palette (not pure black) matching the paper-like warmth of
  /// [light] — background/surface keep a slight brown tint instead of
  /// going neutral gray, and ink/muted tones are inverted (light text,
  /// darker mutes) while orange/olive are brightened so they still read
  /// as accents against a dark backdrop instead of looking desaturated.
  static const dark = AppColorPalette(
    background: Color(0xFF1C1B18),
    surface: Color(0xFF26241F),
    hairline: Color(0xFF3A372E),
    ink: Color(0xFFF3EEE3),
    inkSecondary: Color(0xFFD8D1C1),
    muted: Color(0xFFA79E8C),
    mutedAlt: Color(0xFF8C8472),
    faint: Color(0xFF6E6858),
    faintAlt: Color(0xFF56513F),
    orange: Color(0xFFF08F5F),
    orangeDeep: Color(0xFFF3A377),
    orangeSoft: Color(0xFF3D2A20),
    orangeSoftAlt: Color(0xFF3D2C22),
    olive: Color(0xFFA9AF8B),
    oliveSoft: Color(0xFF2E3126),
    diffSoft: Color(0xFF3D2A20),
    diffText: Color(0xFFF3A377),
    outlineButtonBorder: Color(0xFF474235),
    orangeShadow: Color(0x6BF08F5F),
    orangeButtonShadow: Color(0x52F08F5F),
  );

  @override
  AppColorPalette copyWith({
    Color? background,
    Color? surface,
    Color? hairline,
    Color? ink,
    Color? inkSecondary,
    Color? muted,
    Color? mutedAlt,
    Color? faint,
    Color? faintAlt,
    Color? orange,
    Color? orangeDeep,
    Color? orangeSoft,
    Color? orangeSoftAlt,
    Color? olive,
    Color? oliveSoft,
    Color? diffSoft,
    Color? diffText,
    Color? outlineButtonBorder,
    Color? orangeShadow,
    Color? orangeButtonShadow,
  }) {
    return AppColorPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      hairline: hairline ?? this.hairline,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      muted: muted ?? this.muted,
      mutedAlt: mutedAlt ?? this.mutedAlt,
      faint: faint ?? this.faint,
      faintAlt: faintAlt ?? this.faintAlt,
      orange: orange ?? this.orange,
      orangeDeep: orangeDeep ?? this.orangeDeep,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      orangeSoftAlt: orangeSoftAlt ?? this.orangeSoftAlt,
      olive: olive ?? this.olive,
      oliveSoft: oliveSoft ?? this.oliveSoft,
      diffSoft: diffSoft ?? this.diffSoft,
      diffText: diffText ?? this.diffText,
      outlineButtonBorder: outlineButtonBorder ?? this.outlineButtonBorder,
      orangeShadow: orangeShadow ?? this.orangeShadow,
      orangeButtonShadow: orangeButtonShadow ?? this.orangeButtonShadow,
    );
  }

  @override
  AppColorPalette lerp(ThemeExtension<AppColorPalette>? other, double t) {
    if (other is! AppColorPalette) return this;
    return AppColorPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedAlt: Color.lerp(mutedAlt, other.mutedAlt, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      faintAlt: Color.lerp(faintAlt, other.faintAlt, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeDeep: Color.lerp(orangeDeep, other.orangeDeep, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      orangeSoftAlt: Color.lerp(orangeSoftAlt, other.orangeSoftAlt, t)!,
      olive: Color.lerp(olive, other.olive, t)!,
      oliveSoft: Color.lerp(oliveSoft, other.oliveSoft, t)!,
      diffSoft: Color.lerp(diffSoft, other.diffSoft, t)!,
      diffText: Color.lerp(diffText, other.diffText, t)!,
      outlineButtonBorder: Color.lerp(outlineButtonBorder, other.outlineButtonBorder, t)!,
      orangeShadow: Color.lerp(orangeShadow, other.orangeShadow, t)!,
      orangeButtonShadow: Color.lerp(orangeButtonShadow, other.orangeButtonShadow, t)!,
    );
  }
}

/// `context.colors.background` instead of
/// `Theme.of(context).extension<AppColorPalette>()!.background` everywhere
/// a widget needs a design-token color. Falls back to [AppColorPalette.light]
/// only if the extension was somehow never registered (defensive — `app.dart`
/// always registers one on both `theme` and `darkTheme`).
extension AppColorPaletteContext on BuildContext {
  AppColorPalette get colors => Theme.of(this).extension<AppColorPalette>() ?? AppColorPalette.light;
}
