import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Same height as [PrimaryButton], 1.5px border, no fill.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.flex,
    this.squareIconOnly = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final int? flex;

  /// Renders as a 54×54 square icon-only button (used for "Uredi" next to
  /// the Cook mode CTA on Detalji recepta).
  final bool squareIconOnly;

  @override
  Widget build(BuildContext context) {
    if (squareIconOnly) {
      return SizedBox(
        width: AppSpacing.buttonHeight,
        height: AppSpacing.buttonHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.outlineButtonBorder, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
      );
    }

    final button = SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.outlineButtonBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTypography.sans(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 16)),
          ],
        ),
      ),
    );

    return flex != null ? Expanded(flex: flex!, child: button) : button;
  }
}
