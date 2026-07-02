import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../models/shopping_list_item.dart';

/// Circular 24px checkbox row. Checked: olive fill + white check, text
/// strikethrough + muted. Unchecked: 2px outline circle, normal ink text.
class ShoppingListItemTile extends StatelessWidget {
  const ShoppingListItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final quantityLabel = [
      if (item.quantity != null) _formatQuantity(item.quantity!),
      if (item.unit != null && item.unit!.trim().isNotEmpty) item.unit!.trim(),
    ].join(' ');

    final checked = item.isChecked;
    final textColor = checked ? context.colors.mutedAlt : context.colors.ink;
    final metaColor = checked ? context.colors.faintAlt : context.colors.muted;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.colors.diffSoft,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: context.colors.orangeDeep),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked ? context.colors.olive : Colors.transparent,
                  border: checked ? null : Border.all(color: const Color(0xFFD8CDB6), width: 2),
                ),
                child: checked ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: context.typography.sans(
                    fontSize: 15,
                    color: textColor,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (quantityLabel.isNotEmpty)
                Text(quantityLabel, style: context.typography.sans(fontSize: 13, color: metaColor)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
}
