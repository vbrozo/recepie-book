import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/components/app_bottom_sheet.dart';
import '../../../design/components/primary_button.dart';
import '../../../providers/shopping_list_provider.dart';

/// Shared "Dodaj namirnicu" sheet — used both by Shopping's dashed
/// affordance row and by the Shopping tab's FAB.
Future<void> showAddShoppingItemSheet(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final categoryController = TextEditingController();

  return showAppBottomSheet<void>(
    context,
    title: 'Dodaj namirnicu',
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Naziv')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Količina'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Jedinica'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategorija (opcionalno)')),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Dodaj',
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(shoppingListProvider.notifier).addManualItem(
                    name: name,
                    quantity: double.tryParse(quantityController.text.trim().replaceAll(',', '.')),
                    unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                    category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
