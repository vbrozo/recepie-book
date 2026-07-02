import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Height 54–58px, radius 16–18px, orange fill, white text, weight 700,
/// soft orange drop shadow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.flex,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: AppSpacing.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        boxShadow: onPressed == null
            ? null
            : [BoxShadow(color: context.colors.orangeButtonShadow, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.orange,
          disabledBackgroundColor: context.colors.orange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: context.typography.sans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                ],
              ),
      ),
    );

    return flex != null ? Expanded(flex: flex!, child: button) : button;
  }
}
