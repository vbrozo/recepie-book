import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

enum TagChipVariant { olive, orange, diffAdded, diffRemoved, diffChanged, outline }

/// Pill chip. Olive = category/existing tag, orange = selected/active/diff,
/// diffAdded/diffRemoved/diffChanged = version-diff summaries, outline =
/// unselected filter chip.
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
    final (bg, fg) = _colors(context);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: variant == TagChipVariant.outline && !selected
            ? Border.all(color: context.colors.outlineButtonBorder, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: context.typography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );

    return onTap == null ? chip : GestureDetector(onTap: onTap, child: chip);
  }

  (Color, Color) _colors(BuildContext context) {
    switch (variant) {
      case TagChipVariant.olive:
        return (context.colors.oliveSoft, context.colors.olive);
      case TagChipVariant.orange:
        return (context.colors.orangeSoft, context.colors.orangeDeep);
      case TagChipVariant.diffAdded:
        return (context.colors.oliveSoft, context.colors.olive);
      case TagChipVariant.diffRemoved:
        return (context.colors.diffSoft, context.colors.diffText);
      case TagChipVariant.diffChanged:
        return (context.colors.orangeSoftAlt, context.colors.orangeDeep);
      case TagChipVariant.outline:
        return selected ? (context.colors.orange, Colors.white) : (Colors.transparent, context.colors.ink);
    }
  }
}
