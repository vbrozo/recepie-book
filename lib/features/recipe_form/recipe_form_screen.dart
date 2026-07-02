import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/ingredient_row.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/tag_chip.dart';
import '../../models/ingredient.dart';
import '../../models/recipe.dart';
import '../../models/recipe_image.dart';
import '../../models/recipe_step.dart';
import '../../models/recipe_with_details.dart';
import '../../models/tag.dart';
import '../../providers/image_storage_provider.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/recipe_versions_provider.dart';
import '../../providers/tag_list_provider.dart';
import 'widgets/image_form_item.dart';
import 'widgets/image_form_thumbnail.dart';
import 'widgets/ingredient_form_row.dart';
import 'widgets/step_form_row.dart';

const _uuid = Uuid();

/// Add/edit form for a recipe, its ingredients and its steps, as a 2-step
/// wizard (Osnovni podaci → Sastojci & Postupak) matching the Figma flow.
///
/// Editing an existing recipe auto-saves the result as a new
/// [RecipeVersion] on save (per product rule — edits never overwrite
/// silently), which is why the footer banner shows "Spremi kao Verziju N".
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
  final List<ImageFormItem> _imageItems = [];
  final List<Tag> _selectedTags = [];
  final _tagInputController = TextEditingController();

  /// What changed in this edit ("više soli, manje brašna") — shown on the
  /// version's timeline card afterward. Only used when editing (see
  /// [_isEditing]); a brand-new recipe's first version gets a fixed note
  /// instead (see [_save]).
  final _versionNoteController = TextEditingController();

  String? _primaryImageId;
  bool _isSaving = false;
  int _currentStep = 0;

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

    final existingImages = widget.existing?.images ?? const [];
    for (final image in existingImages) {
      _imageItems.add(ImageFormItem.existing(id: image.id, relativePath: image.filePath));
      if (image.isPrimary) {
        _primaryImageId = image.id;
      }
    }
    if (_primaryImageId == null && _imageItems.isNotEmpty) {
      _primaryImageId = _imageItems.first.id;
    }

    _selectedTags.addAll(widget.existing?.tags ?? const []);
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
    _tagInputController.dispose();
    _versionNoteController.dispose();
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

  Future<void> _pickImages() async {
    // Downscaled at the source: on web the picked bytes are stored inline
    // as a base64 `data:` URL (see ImageStorageService), so an un-resized
    // photo straight off a phone camera would bloat every recipe-list
    // query and stay in memory for the lifetime of the app session.
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (files.isEmpty) return;

    setState(() {
      for (final file in files) {
        final item = ImageFormItem.picked(id: _uuid.v4(), file: file);
        _imageItems.add(item);
        _primaryImageId ??= item.id;
      }
    });
  }

  void _removeImageRow(int index) {
    setState(() {
      final removed = _imageItems.removeAt(index);
      if (_primaryImageId == removed.id) {
        _primaryImageId = _imageItems.isNotEmpty ? _imageItems.first.id : null;
      }
    });
  }

  void _setPrimaryImage(String id) {
    setState(() => _primaryImageId = id);
  }

  Future<void> _addTagByName(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;

    if (_selectedTags.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
      _tagInputController.clear();
      return;
    }

    final tag = await ref.read(tagListProvider.notifier).getOrCreateTag(name);
    if (!mounted) return;
    setState(() {
      _selectedTags.add(tag);
      _tagInputController.clear();
    });
  }

  void _addExistingTag(Tag tag) {
    if (_selectedTags.any((selected) => selected.id == tag.id)) return;
    setState(() => _selectedTags.add(tag));
  }

  void _removeTag(Tag tag) {
    setState(() => _selectedTags.removeWhere((selected) => selected.id == tag.id));
  }

  void _goNext() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _currentStep = 1);
  }

  void _goBack() {
    if (_currentStep == 0) {
      context.pop();
    } else {
      setState(() => _currentStep = 0);
    }
  }

  Future<void> _save() async {
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

    final imageStorage = ref.read(imageStorageServiceProvider);
    final images = <RecipeImage>[];
    final newlySavedPaths = <String>[];
    for (var i = 0; i < _imageItems.length; i++) {
      final item = _imageItems[i];
      String relativePath;
      if (item.existingRelativePath != null) {
        relativePath = item.existingRelativePath!;
      } else {
        relativePath = await imageStorage.saveImage(
          recipeId: recipeId,
          imageId: item.id,
          source: item.pickedFile!,
        );
        newlySavedPaths.add(relativePath);
      }
      images.add(RecipeImage(
        id: item.id,
        recipeId: recipeId,
        filePath: relativePath,
        isPrimary: item.id == _primaryImageId,
        sortOrder: i,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Files for images removed from an existing recipe during this edit —
    // computed now, but only actually deleted from disk once the DB write
    // below has confirmed succeeded (see below). Deleting them earlier
    // would risk broken image references if the save then failed: the DB
    // row still points at the old path, but the file backing it would
    // already be gone.
    final keptExistingPaths = _imageItems
        .map((item) => item.existingRelativePath)
        .whereType<String>()
        .toSet();
    final removedPaths = (widget.existing?.images ?? const [])
        .map((image) => image.filePath)
        .where((path) => !keptExistingPaths.contains(path))
        .toList();

    final tagIds = _selectedTags.map((tag) => tag.id).toList();

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
        images: images,
        tagIds: tagIds,
      );
    }

    // createRecipe/updateRecipe swallow repository errors into
    // state.errorMessage instead of throwing (so a failed save doesn't
    // crash the widget tree) — check for one here, otherwise a DB failure
    // would silently look like a successful save: the form would close as
    // if nothing happened while the recipe never actually got persisted.
    final saveError = ref.read(recipeListProvider).errorMessage;
    if (saveError != null) {
      // The DB write failed, so the old recipe row (and its old image
      // paths) is still what's persisted — clean up only the files that
      // got copied to disk during this attempt (orphaned, unreferenced by
      // any DB row now), and leave the removed-but-still-referenced ones
      // alone.
      await imageStorage.deleteImages(newlySavedPaths);

      // Also to the browser console — the SnackBar truncates/auto-dismisses
      // long messages, the console doesn't.
      debugPrint('[Kuharica] Recipe save failed: $saveError');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recept nije spremljen: $saveError'),
          duration: const Duration(seconds: 10),
        ),
      );
      return;
    }

    // Only now that the DB write is confirmed committed is it safe to
    // remove the files for images the user dropped during this edit.
    await imageStorage.deleteImages(removedPaths);

    // Every save (create or edit) becomes a new version — saving an edit
    // never silently overwrites the recipe's history.
    final savedSnapshot = RecipeWithDetails(
      recipe: recipe,
      ingredients: ingredients,
      steps: steps,
      images: images,
      tags: _selectedTags,
    );
    final versionNote = _versionNoteController.text.trim();
    await ref.read(recipeVersionsProvider(recipeId).notifier).createVersion(
          recipe: savedSnapshot,
          note: _isEditing ? (versionNote.isEmpty ? null : versionNote) : 'Prvi zapis recepta',
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final existingVersions =
        _isEditing ? ref.watch(recipeVersionsProvider(widget.existing!.recipe.id)).versions : const [];
    final nextVersionNumber = existingVersions.isEmpty ? 1 : existingVersions.first.versionNumber + 1;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Header(
                title: _isEditing ? 'Uredi recept' : 'Novi recept',
                onBack: _goBack,
                onCancel: () => context.pop(),
              ),
              const SizedBox(height: 12),
              _ProgressBar(currentStep: _currentStep),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currentStep == 0 ? 'KORAK 1 OD 2 · OSNOVNI PODACI' : 'KORAK 2 OD 2 · SASTOJCI',
                    style: context.typography.eyebrow(),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _VersionBanner(nextVersionNumber: nextVersionNumber),
                ),
              ],
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: _currentStep == 0 ? _buildStepOne(context) : _buildStepTwo(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _currentStep == 0
                    ? PrimaryButton(label: 'Dalje', onPressed: _goNext)
                    : PrimaryButton(
                        label: _isEditing ? 'Spremi kao Verziju $nextVersionNumber' : 'Spremi recept',
                        icon: Icons.check,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _save,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepOne(BuildContext context) {
    return [
      Text('NASLOVNA SLIKA', style: context.typography.eyebrow()),
      const SizedBox(height: 8),
      _HeroImagePicker(
        imageItems: _imageItems,
        primaryImageId: _primaryImageId,
        onPick: _pickImages,
        onSetPrimary: _setPrimaryImage,
        onRemove: _removeImageRow,
      ),
      const SizedBox(height: 20),
      Text('NAZIV RECEPTA', style: context.typography.eyebrow()),
      const SizedBox(height: 8),
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(hintText: 'npr. Njoki s kaduljom'),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Naziv je obavezan' : null,
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(labelText: 'Opis'),
        maxLines: 3,
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VRIJEME (MIN)', style: context.typography.eyebrow()),
                const SizedBox(height: 8),
                TextFormField(controller: _prepController, keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PORCIJE', style: context.typography.eyebrow()),
                const SizedBox(height: 8),
                TextFormField(controller: _servingsController, keyboardType: TextInputType.number),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KUHANJE (MIN)', style: context.typography.eyebrow()),
          const SizedBox(height: 8),
          TextFormField(controller: _cookController, keyboardType: TextInputType.number),
        ],
      ),
      const SizedBox(height: 20),
      Text('TAGOVI', style: context.typography.eyebrow()),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in _selectedTags)
            TagChip(label: tag.name, variant: TagChipVariant.olive, onTap: () => _removeTag(tag)),
          _AddTagChip(controller: _tagInputController, onSubmit: _addTagByName),
        ],
      ),
      Consumer(
        builder: (context, ref, _) {
          final allTags = ref.watch(tagListProvider);
          final available = allTags.where((tag) => !_selectedTags.any((s) => s.id == tag.id)).toList();
          if (available.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in available)
                  TagChip(label: tag.name, variant: TagChipVariant.outline, onTap: () => _addExistingTag(tag)),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildStepTwo(BuildContext context) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Sastojci', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
          IconButton(icon: Icon(Icons.add_circle_outline, color: context.colors.orange), onPressed: _addIngredientRow),
        ],
      ),
      for (var i = 0; i < _ingredientRows.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IngredientFormRowField(
            row: _ingredientRows[i],
            removeEnabled: _ingredientRows.length > 1,
            onRemove: () => _removeIngredientRow(i),
          ),
        ),
      AddIngredientRow(onTap: _addIngredientRow),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Postupak', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
          IconButton(icon: Icon(Icons.add_circle_outline, color: context.colors.orange), onPressed: _addStepRow),
        ],
      ),
      for (var i = 0; i < _stepRows.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StepFormRowField(
            index: i,
            row: _stepRows[i],
            removeEnabled: _stepRows.length > 1,
            onRemove: () => _removeStepRow(i),
          ),
        ),
      if (_isEditing) ...[
        const SizedBox(height: 24),
        Text('BILJEŠKA UZ VERZIJU', style: context.typography.eyebrow()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _versionNoteController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'npr. više soli, manje brašna (opcionalno)'),
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, required this.onCancel});

  final String title;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: context.typography.sans(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text('Odustani', style: context.typography.sans(color: context.colors.mutedAlt, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(2, (i) {
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: i == 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= currentStep ? context.colors.orange : context.colors.hairline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _VersionBanner extends StatelessWidget {
  const _VersionBanner({required this.nextVersionNumber});

  final int nextVersionNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.colors.orangeSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.orangeDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Promjene se ne spremaju preko originala — nastat će Verzija $nextVersionNumber.',
              style: context.typography.sans(fontSize: 13, color: context.colors.orangeDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTagChip extends StatefulWidget {
  const _AddTagChip({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  State<_AddTagChip> createState() => _AddTagChipState();
}

class _AddTagChipState extends State<_AddTagChip> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return GestureDetector(
        onTap: () => setState(() => _editing = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: context.colors.faintAlt),
          ),
          child: Text('+ dodaj', style: context.typography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.muted)),
        ),
      );
    }

    return SizedBox(
      width: 140,
      child: TextField(
        controller: widget.controller,
        autofocus: true,
        style: context.typography.sans(fontSize: 13),
        decoration: const InputDecoration(isDense: true, hintText: 'Naziv taga'),
        onSubmitted: (value) {
          widget.onSubmit(value);
          setState(() => _editing = false);
        },
        onTapOutside: (_) {
          if (widget.controller.text.trim().isNotEmpty) widget.onSubmit(widget.controller.text);
          setState(() => _editing = false);
        },
      ),
    );
  }
}

class _HeroImagePicker extends StatelessWidget {
  const _HeroImagePicker({
    required this.imageItems,
    required this.primaryImageId,
    required this.onPick,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final List<ImageFormItem> imageItems;
  final String? primaryImageId;
  final VoidCallback onPick;
  final ValueChanged<String> onSetPrimary;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 164,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.faintAlt),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: context.colors.muted, size: 28),
                const SizedBox(height: 8),
                Text('+ Dodaj naslovnu sliku', style: context.typography.sans(color: context.colors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (imageItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageItems.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ImageFormThumbnail(
                item: imageItems[index],
                isPrimary: imageItems[index].id == primaryImageId,
                onSetPrimary: () => onSetPrimary(imageItems[index].id),
                onRemove: () => onRemove(index),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
