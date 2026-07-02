import 'package:flutter/material.dart';

import '../../../models/shopping_list_item.dart';

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

    return CheckboxListTile(
      value: item.isChecked,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        item.name,
        style: item.isChecked
            ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      subtitle: quantityLabel.isEmpty ? null : Text(quantityLabel),
      secondary: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
}
