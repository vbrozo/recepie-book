import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/image_storage_service.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/image_storage_provider.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/recipe_notifier.dart';
import '../../widgets/recipe_image_thumbnail.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeListProvider);
    final notifier = ref.read(recipeListProvider.notifier);

    RecipeWithDetails? item;
    for (final recipe in state.recipes) {
      if (recipe.recipe.id == recipeId) {
        item = recipe;
        break;
      }
    }

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: state.isLoading
              ? const CircularProgressIndicator()
              : const Text('Recept nije pronađen.'),
        ),
      );
    }

    final recipe = item.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: Icon(
              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: recipe.isFavorite ? Colors.red : null,
            ),
            onPressed: () => notifier.toggleFavorite(recipe.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/recipe/${recipe.id}/edit', extra: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(
              context,
              notifier,
              ref.read(imageStorageServiceProvider),
              recipe.id,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            Text(recipe.description!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (recipe.servings != null) _MetaChip(icon: Icons.people, label: '${recipe.servings} porcija'),
              if (recipe.prepTimeMinutes != null) _MetaChip(icon: Icons.schedule, label: 'Priprema ${recipe.prepTimeMinutes} min'),
              if (recipe.cookTimeMinutes != null) _MetaChip(icon: Icons.local_fire_department, label: 'Kuhanje ${recipe.cookTimeMinutes} min'),
            ],
          ),
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => RecipeImageThumbnail(
                  relativePath: item.images[index].filePath,
                  size: 96,
                ),
              ),
            ),
          ],
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [for (final tag in item.tags) Chip(label: Text(tag.name))],
            ),
          ],
          const SizedBox(height: 24),
          Text('Sastojci', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (item.ingredients.isEmpty)
            const Text('Nema unesenih sastojaka.')
          else
            for (final ingredient in item.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${[
                    if (ingredient.quantity != null) _formatQuantity(ingredient.quantity!),
                    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) ingredient.unit,
                    ingredient.name,
                  ].where((part) => part != null && part.toString().isNotEmpty).join(' ')}',
                ),
              ),
          const SizedBox(height: 24),
          Text('Koraci', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (item.steps.isEmpty)
            const Text('Nema unesenih koraka.')
          else
            for (final step in item.steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, child: Text('${step.stepNumber}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.durationMinutes != null
                            ? '${step.instruction} (${step.durationMinutes} min)'
                            : step.instruction,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecipeNotifier notifier,
    ImageStorageService imageStorage,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši recept?'),
        content: const Text('Ova radnja se ne može poništiti.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Obriši')),
        ],
      ),
    );

    if (confirmed != true) return;

    final imagePaths = await notifier.deleteRecipe(id);
    await imageStorage.deleteImages(imagePaths);

    if (context.mounted) context.pop();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
