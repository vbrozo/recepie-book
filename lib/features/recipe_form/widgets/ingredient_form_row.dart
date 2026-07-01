import 'package:flutter/material.dart';

/// Local, non-persisted editing state for one ingredient row in the form.
/// Converted to an [Ingredient] model only on submit.
class IngredientFormRow {
  IngredientFormRow({
    required this.id,
    String name = '',
    String quantity = '',
    String unit = '',
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        unitController = TextEditingController(text: unit);

  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}

class IngredientFormRowField extends StatelessWidget {
  const IngredientFormRowField({
    super.key,
    required this.row,
    required this.onRemove,
    required this.removeEnabled,
  });

  final IngredientFormRow row;
  final VoidCallback onRemove;
  final bool removeEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.nameController,
              decoration: const InputDecoration(labelText: 'Sastojak'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.quantityController,
              decoration: const InputDecoration(labelText: 'Količina'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.unitController,
              decoration: const InputDecoration(labelText: 'Jed.'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: removeEnabled ? onRemove : null,
          ),
        ],
      ),
    );
  }
}
