import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

enum TagChipVariant { olive, orange, diffAdded, diffRemoved, outline }

/// Pill chip. Olive = category/existing tag, orange = selected/active/diff,
/// diffAdded/diffRemoved = version-diff summaries, outline = unselected
/// filter chip.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.variant = TagChipVariant.olive,
    this.onTap,
    this.selected = false,
    this.leading,
  });

  final String label;
  final TagChipVariant variant;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: variant == TagChipVariant.outline && !selected
            ? Border.all(color: AppColors.outlineButtonBorder, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );

    return onTap == null ? chip : GestureDetector(onTap: onTap, child: chip);
  }

  (Color, Color) _colors() {
    switch (variant) {
      case TagChipVariant.olive:
        return (AppColors.oliveSoft, AppColors.olive);
      case TagChipVariant.orange:
        return (AppColors.orangeSoft, AppColors.orangeDeep);
      case TagChipVariant.diffAdded:
        return (AppColors.oliveSoft, AppColors.olive);
      case TagChipVariant.diffRemoved:
        return (AppColors.diffSoft, AppColors.diffText);
      case TagChipVariant.outline:
        return selected ? (AppColors.orange, Colors.white) : (Colors.transparent, AppColors.ink);
    }
  }
}
