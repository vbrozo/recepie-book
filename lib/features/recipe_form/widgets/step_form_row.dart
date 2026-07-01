import 'package:flutter/material.dart';

/// Local, non-persisted editing state for one step row in the form.
/// Converted to a [RecipeStep] model only on submit.
class StepFormRow {
  StepFormRow({
    required this.id,
    String instruction = '',
    String duration = '',
  })  : instructionController = TextEditingController(text: instruction),
        durationController = TextEditingController(text: duration);

  final String id;
  final TextEditingController instructionController;
  final TextEditingController durationController;

  void dispose() {
    instructionController.dispose();
    durationController.dispose();
  }
}

class StepFormRowField extends StatelessWidget {
  const StepFormRowField({
    super.key,
    required this.index,
    required this.row,
    required this.onRemove,
    required this.removeEnabled,
  });

  final int index;
  final StepFormRow row;
  final VoidCallback onRemove;
  final bool removeEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CircleAvatar(radius: 14, child: Text('${index + 1}')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: row.instructionController,
              decoration: const InputDecoration(labelText: 'Opis koraka'),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: row.durationController,
              decoration: const InputDecoration(labelText: 'min'),
              keyboardType: TextInputType.number,
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
