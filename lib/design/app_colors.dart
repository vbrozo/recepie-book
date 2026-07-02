import 'package:flutter/material.dart';

/// Design tokens straight from the Figma handoff (Kuharica UX Flow).
/// Orange is the only accent color (CTAs, favorites, active nav state);
/// olive is used only for category/tag chips.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFAF6EF);
  static const surface = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFEFE7D6);

  static const ink = Color(0xFF2B2A26);
  static const inkSecondary = Color(0xFF4A463E);
  static const muted = Color(0xFF8C8472);
  static const mutedAlt = Color(0xFFA79E8C);
  static const faint = Color(0xFFB4AB98);
  static const faintAlt = Color(0xFFC9C0AE);

  static const orange = Color(0xFFE8794A);
  static const orangeDeep = Color(0xFFC85E32);
  static const orangeSoft = Color(0xFFFBEBE0);
  static const orangeSoftAlt = Color(0xFFFBEDE2);

  static const olive = Color(0xFF6E7355);
  static const oliveSoft = Color(0xFFEEF0E4);

  static const diffSoft = Color(0xFFF9E6DC);
  static const diffText = orangeDeep;

  static const outlineButtonBorder = Color(0xFFE4DAC7);

  static const orangeShadow = Color(0x6BE8794A); // rgba(232,121,74,.42)
  static const orangeButtonShadow = Color(0x52E8794A); // rgba(232,121,74,.32)
}
