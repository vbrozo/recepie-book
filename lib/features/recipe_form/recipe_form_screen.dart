import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../models/ingredient.dart';
import '../../models/recipe.dart';
import '../../models/recipe_step.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/recipe_list_provider.dart';
import 'widgets/ingredient_form_row.dart';
import 'widgets/step_form_row.dart';

const _uuid = Uuid();

/// Add/edit form for a recipe, its ingredients and its steps.
/// Pass [existing] to edit, or leave it null to create a new recipe.
class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.existing});

  final RecipeWithDetails? existing;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _servingsController;
  late final TextEditingController _prepController;
  late final TextEditingController _cookController;

  final List<IngredientFormRow> _ingredientRows = [];
  final List<StepFormRow> _stepRows = [];

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.existing?.recipe;

    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _servingsController = TextEditingController(text: recipe?.servings?.toString() ?? '');
    _prepController = TextEditingController(text: recipe?.prepTimeMinutes?.toString() ?? '');
    _cookController = TextEditingController(text: recipe?.cookTimeMinutes?.toString() ?? '');

    final existingIngredients = widget.existing?.ingredients ?? const [];
    if (existingIngredients.isEmpty) {
      _ingredientRows.add(IngredientFormRow(id: _uuid.v4()));
    } else {
      for (final ingredient in existingIngredients) {
        _ingredientRows.add(IngredientFormRow(
          id: ingredient.id,
          name: ingredient.name,
          quantity: ingredient.quantity?.toString() ?? '',
          unit: ingredient.unit ?? '',
        ));
      }
    }

    final existingSteps = widget.existing?.steps ?? const [];
    if (existingSteps.isEmpty) {
      _stepRows.add(StepFormRow(id: _uuid.v4()));
    } else {
      for (final step in existingSteps) {
        _stepRows.add(StepFormRow(
          id: step.id,
          instruction: step.instruction,
          duration: step.durationMinutes?.toString() ?? '',
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _prepController.dispose();
    _cookController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    for (final row in _stepRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() => _ingredientRows.add(IngredientFormRow(id: _uuid.v4())));
  }

  void _removeIngredientRow(int index) {
    setState(() {
      _ingredientRows[index].dispose();
      _ingredientRows.removeAt(index);
    });
  }

  void _addStepRow() {
    setState(() => _stepRows.add(StepFormRow(id: _uuid.v4())));
  }

  void _removeStepRow(int index) {
    setState(() {
      _stepRows[index].dispose();
      _stepRows.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final validIngredients =
        _ingredientRows.where((row) => row.nameController.text.trim().isNotEmpty).toList();
    final validSteps =
        _stepRows.where((row) => row.instructionController.text.trim().isNotEmpty).toList();

    if (validIngredients.isEmpty || validSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodaj barem jedan sastojak i jedan korak.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final recipeId = widget.existing?.recipe.id ?? _uuid.v4();

    final recipe = Recipe(
      id: recipeId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      servings: int.tryParse(_servingsController.text.trim()),
      prepTimeMinutes: int.tryParse(_prepController.text.trim()),
      cookTimeMinutes: int.tryParse(_cookController.text.trim()),
      isFavorite: widget.existing?.recipe.isFavorite ?? false,
      createdAt: widget.existing?.recipe.createdAt ?? now,
      updatedAt: now,
    );

    final ingredients = [
      for (var i = 0; i < validIngredients.length; i++)
        Ingredient(
          id: validIngredients[i].id,
          recipeId: recipeId,
          name: validIngredients[i].nameController.text.trim(),
          quantity: double.tryParse(
            validIngredients[i].quantityController.text.trim().replaceAll(',', '.'),
          ),
          unit: validIngredients[i].unitController.text.trim().isEmpty
              ? null
              : validIngredients[i].unitController.text.trim(),
          sortOrder: i,
          createdAt: now,
          updatedAt: now,
        ),
    ];

    final steps = [
      for (var i = 0; i < validSteps.length; i++)
        RecipeStep(
          id: validSteps[i].id,
          recipeId: recipeId,
          stepNumber: i + 1,
          instruction: validSteps[i].instructionController.text.trim(),
          durationMinutes: int.tryParse(validSteps[i].durationController.text.trim()),
          createdAt: now,
          updatedAt: now,
        ),
    ];

    // Images and tags aren't editable from this screen yet — keep whatever
    // the recipe already had so updateRecipe's wholesale-replace doesn't
    // silently drop them.
    final images = widget.existing?.images ?? const [];
    final tagIds = widget.existing?.tags.map((tag) => tag.id).toList() ?? const <String>[];

    final notifier = ref.read(recipeListProvider.notifier);
    if (_isEditing) {
      await notifier.updateRecipe(
        recipe: recipe,
        ingredients: ingredients,
        steps: steps,
        images: images,
        tagIds: tagIds,
      );
    } else {
      await notifier.createRecipe(
        recipe: recipe,
        ingredients: ingredients,
        steps: steps,
        tagIds: tagIds,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Uredi recept' : 'Novi recept')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Naziv *'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Naziv je obavezan' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Opis'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(labelText: 'Porcije'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _prepController,
                    decoration: const InputDecoration(labelText: 'Priprema (min)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _cookController,
                    decoration: const InputDecoration(labelText: 'Kuhanje (min)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sastojci', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addIngredientRow,
                ),
              ],
            ),
            for (var i = 0; i < _ingredientRows.length; i++)
              IngredientFormRowField(
                row: _ingredientRows[i],
                removeEnabled: _ingredientRows.length > 1,
                onRemove: () => _removeIngredientRow(i),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Koraci', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addStepRow,
                ),
              ],
            ),
            for (var i = 0; i < _stepRows.length; i++)
              StepFormRowField(
                index: i,
                row: _stepRows[i],
                removeEnabled: _stepRows.length > 1,
                onRemove: () => _removeStepRow(i),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }
}
