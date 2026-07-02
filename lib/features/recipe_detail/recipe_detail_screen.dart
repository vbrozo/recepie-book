import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/image_storage_service.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/confirmation_dialog.dart';
import '../../design/components/glass_icon_button.dart';
import '../../design/components/outline_button.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/step_card.dart';
import '../../design/components/tag_chip.dart';
import '../../models/ingredient.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/image_storage_provider.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/recipe_notifier.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/recipe_image_thumbnail.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  /// Servings the ingredient list is currently scaled to — starts out equal
  /// to the recipe's own `servings`, adjustable via the stepper in
  /// [_StatsRow]. Session-only (not persisted): reopening the recipe resets
  /// it back to the recipe's stated serving count.
  int? _servings;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeListProvider);
    final notifier = ref.read(recipeListProvider.notifier);

    RecipeWithDetails? item;
    for (final recipe in state.recipes) {
      if (recipe.recipe.id == widget.recipeId) {
        item = recipe;
        break;
      }
    }

    if (item == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: state.isLoading ? const CircularProgressIndicator() : const Text('Recept nije pronađen.'),
        ),
      );
    }

    final recipe = item.recipe;
    _servings ??= recipe.servings;
    final originalServings = recipe.servings;
    final scale = (originalServings != null && originalServings > 0 && _servings != null)
        ? _servings! / originalServings
        : 1.0;

    String? coverPath;
    for (final image in item.images) {
      if (image.isPrimary) {
        coverPath = image.filePath;
        break;
      }
    }
    coverPath ??= item.images.isNotEmpty ? item.images.first.filePath : null;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 326,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverPath != null
                        ? RecipeImageThumbnail(relativePath: coverPath, width: double.infinity, height: 326, radius: 0)
                        : Container(color: context.colors.oliveSoft, child: Icon(Icons.restaurant_menu, size: 48, color: context.colors.olive)),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black38, Colors.transparent],
                          stops: [0, 0.34],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in item.tags) TagChip(label: tag.name, variant: TagChipVariant.olive),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(recipe.title, style: context.typography.serif(fontSize: 30)),
                        if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(recipe.description!, style: context.typography.sans(fontSize: 14, color: context.colors.inkSecondary)),
                        ],
                        const SizedBox(height: 16),
                        _StatsRow(
                          item: item,
                          servings: _servings,
                          onServingsChanged: originalServings == null || originalServings <= 0
                              ? null
                              : (value) => setState(() => _servings = value),
                        ),
                        const SizedBox(height: 8),
                        _ActionsRow(
                          onGallery: () => context.push('/recipe/${recipe.id}/gallery'),
                          onVersions: () => context.push('/recipe/${recipe.id}/versions'),
                          onShoppingList: item.ingredients.isEmpty
                              ? null
                              : () => _addToShoppingList(context, ref, recipe.id, _scaledIngredients(item!.ingredients, scale)),
                        ),
                        if (item.images.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 84,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: item.images.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) =>
                                  RecipeImageThumbnail(relativePath: item!.images[index].filePath, size: 84, radius: 14),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text('Sastojci', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
                        const SizedBox(height: 8),
                        if (item.ingredients.isEmpty)
                          Text('Nema unesenih sastojaka.', style: context.typography.sans(color: context.colors.muted))
                        else
                          for (final ingredient in item.ingredients)
                            _IngredientBulletRow(ingredient: ingredient, scale: scale),
                        const SizedBox(height: 24),
                        Text('Postupak', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
                        const SizedBox(height: 8),
                        if (item.steps.isEmpty)
                          Text('Nema unesenih koraka.', style: context.typography.sans(color: context.colors.muted))
                        else
                          for (final step in item.steps)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StepCard(
                                stepNumber: step.stepNumber,
                                instruction: step.durationMinutes != null
                                    ? '${step.instruction} (${step.durationMinutes} min)'
                                    : step.instruction,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                  Row(
                    children: [
                      GlassIconButton(
                        icon: recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: recipe.isFavorite ? context.colors.orange : Colors.white,
                        onTap: () => notifier.toggleFavorite(recipe.id),
                      ),
                      const SizedBox(width: 8),
                      GlassIconButton(
                        icon: Icons.delete_outline,
                        onTap: () => _confirmDelete(context, notifier, ref.read(imageStorageServiceProvider), recipe.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.hairline)),
                ),
                child: Row(
                  children: [
                    OutlineButton(
                      label: '',
                      icon: Icons.edit_outlined,
                      squareIconOnly: true,
                      onPressed: () => context.push('/recipe/${recipe.id}/edit', extra: item),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      label: 'Cook mode',
                      icon: Icons.local_fire_department_outlined,
                      flex: 1,
                      onPressed: item.steps.isEmpty ? null : () => context.push('/recipe/${recipe.id}/cook'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecipeNotifier notifier,
    ImageStorageService imageStorage,
    String id,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Obriši recept?',
      message: 'Ova radnja se ne može poništiti.',
      confirmLabel: 'Obriši',
    );
    if (!confirmed) return;

    final imagePaths = await notifier.deleteRecipe(id);
    await imageStorage.deleteImages(imagePaths);

    if (context.mounted) context.pop();
  }

  Future<void> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    String recipeId,
    List<Ingredient> ingredients,
  ) async {
    await ref.read(shoppingListProvider.notifier).addIngredientsFromRecipe(
          recipeId: recipeId,
          ingredients: ingredients,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sastojci dodani u shopping listu.')),
    );
  }

  /// Applies [scale] to every ingredient's quantity — used when sending
  /// ingredients to the shopping list, so a doubled-up recipe adds doubled
  /// quantities instead of the original recipe's amounts.
  List<Ingredient> _scaledIngredients(List<Ingredient> ingredients, double scale) {
    if (scale == 1.0) return ingredients;
    return [
      for (final ingredient in ingredients)
        ingredient.copyWith(quantity: ingredient.quantity != null ? ingredient.quantity! * scale : null),
    ];
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.item, required this.servings, required this.onServingsChanged});

  final RecipeWithDetails item;

  /// The currently selected serving count (may differ from
  /// `item.recipe.servings` once the user has used the stepper).
  final int? servings;

  /// Null when the recipe has no `servings` set — scaling has no baseline
  /// to work from, so the stepper is hidden rather than shown disabled.
  final ValueChanged<int>? onServingsChanged;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.hairline),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _StatColumn(value: recipe.prepTimeMinutes != null ? '${recipe.prepTimeMinutes} min' : '—', label: 'Vrijeme'),
          const _StatDivider(),
          onServingsChanged != null
              ? Expanded(
                  child: _ServingsStepper(
                    servings: servings ?? recipe.servings!,
                    onChanged: onServingsChanged!,
                  ),
                )
              : _StatColumn(value: recipe.servings != null ? '${recipe.servings}' : '—', label: 'Porcije'),
          const _StatDivider(),
          _StatColumn(value: '${item.ingredients.length}', label: 'Sastojci'),
        ],
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.servings, required this.onChanged});

  final int servings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(
              icon: Icons.remove,
              onTap: servings > 1 ? () => onChanged(servings - 1) : null,
            ),
            SizedBox(
              width: 28,
              child: Text(
                '$servings',
                textAlign: TextAlign.center,
                style: context.typography.sans(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.ink),
              ),
            ),
            _StepperButton(
              icon: Icons.add,
              onTap: () => onChanged(servings + 1),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Porcije', style: context.typography.sans(fontSize: 11, color: context.colors.muted)),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: onTap == null ? context.colors.faint : context.colors.orangeDeep),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: context.typography.sans(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.ink)),
          const SizedBox(height: 2),
          Text(label, style: context.typography.sans(fontSize: 11, color: context.colors.muted)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: context.colors.hairline);
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.onGallery, required this.onVersions, this.onShoppingList});

  final VoidCallback onGallery;
  final VoidCallback onVersions;
  final VoidCallback? onShoppingList;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionLink(icon: Icons.photo_library_outlined, label: 'Galerija', onTap: onGallery),
        _ActionLink(icon: Icons.history, label: 'Verzije', onTap: onVersions),
        if (onShoppingList != null)
          _ActionLink(icon: Icons.add_shopping_cart_outlined, label: 'U shopping listu', onTap: onShoppingList!),
      ],
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.colors.orangeDeep),
            const SizedBox(width: 4),
            Text(label, style: context.typography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.orangeDeep)),
          ],
        ),
      ),
    );
  }
}

class _IngredientBulletRow extends StatelessWidget {
  const _IngredientBulletRow({required this.ingredient, this.scale = 1.0});

  final Ingredient ingredient;

  /// Multiplier applied to `ingredient.quantity` for display — driven by
  /// the servings stepper in [_StatsRow]. 1.0 (the default) shows the
  /// recipe's original amounts unchanged.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scaledQuantity = ingredient.quantity != null ? ingredient.quantity! * scale : null;
    final quantity = [
      if (scaledQuantity != null) _formatQuantity(scaledQuantity),
      if (ingredient.unit != null && ingredient.unit!.isNotEmpty) ingredient.unit,
    ].join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.hairline))),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: context.colors.orange, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(ingredient.name, style: context.typography.sans(fontSize: 15, color: context.colors.inkSecondary))),
          if (quantity.isNotEmpty) Text(quantity, style: context.typography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.ink)),
        ],
      ),
    );
  }

  /// Rounds to 2 decimal places and trims trailing zeros — scaling
  /// (e.g. 1 / 3 servings * 2) produces long floating-point tails
  /// (0.6666666666666666) that `toString()` alone would show raw.
  String _formatQuantity(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
    return rounded
        .toString()
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
