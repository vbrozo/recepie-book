import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import 'tag_chip.dart';

/// White card, drag handle, bold quantity, name, trailing delete "×".
/// [editing] shows a text-edit-styled variant; [changed] adds the
/// "izmijenjeno" diff chip (Uredi recept screen).
class IngredientRow extends StatelessWidget {
  const IngredientRow({
    super.key,
    required this.quantityLabel,
    required this.name,
    this.onDelete,
    this.changed = false,
    this.showDragHandle = true,
  });

  final String quantityLabel;
  final String name;
  final VoidCallback? onDelete;
  final bool changed;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          if (showDragHandle) ...[
            const Icon(Icons.drag_indicator, size: 18, color: AppColors.faint),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 56,
            child: Text(quantityLabel, style: AppTypography.sans(fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          Expanded(
            child: Text(name, style: AppTypography.sans(color: AppColors.inkSecondary)),
          ),
          if (changed) ...[
            const TagChip(label: 'izmijenjeno', variant: TagChipVariant.diffRemoved),
            const SizedBox(width: 8),
          ],
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 18, color: AppColors.faint),
            ),
        ],
      ),
    );
  }
}

/// Dashed "+ Dodaj sastojak" affordance row that ends an ingredient list.
class AddIngredientRow extends StatelessWidget {
  const AddIngredientRow({super.key, required this.onTap, this.label = '+ Dodaj sastojak'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.faintAlt, style: BorderStyle.solid),
        ),
        child: Text(label, style: AppTypography.sans(fontWeight: FontWeight.w600, color: AppColors.orangeDeep)),
      ),
    );
  }
}
