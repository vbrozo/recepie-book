import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe_snapshot.dart';
import '../../models/recipe_version.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/recipe_versions_provider.dart';
import 'widgets/recipe_version_tile.dart';

/// History of saved snapshots for one recipe, with the ability to save the
/// current state as a new version and to restore an old one.
class RecipeVersionsScreen extends ConsumerWidget {
  const RecipeVersionsScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeState = ref.watch(recipeListProvider);
    RecipeWithDetails? current;
    for (final recipe in recipeState.recipes) {
      if (recipe.recipe.id == recipeId) {
        current = recipe;
        break;
      }
    }

    final versionState = ref.watch(recipeVersionsProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(current != null ? 'Verzije — ${current.recipe.title}' : 'Verzije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Spremi trenutnu verziju',
            onPressed: current == null ? null : () => _saveVersion(context, ref, current!),
          ),
        ],
      ),
      body: current == null
          ? Center(
              child: recipeState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Recept nije pronađen.'),
            )
          : versionState.isLoading && versionState.versions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : versionState.versions.isEmpty
                  ? const Center(child: Text('Još nema spremljenih verzija.'))
                  : ListView.builder(
                      itemCount: versionState.versions.length,
                      itemBuilder: (context, index) {
                        final version = versionState.versions[index];
                        return RecipeVersionTile(
                          version: version,
                          onRestore: () => _restore(context, ref, version, current!),
                        );
                      },
                    ),
    );
  }

  Future<void> _saveVersion(BuildContext context, WidgetRef ref, RecipeWithDetails current) async {
    final note = await _promptForNote(context, title: 'Spremi verziju');
    if (note == null) return;

    await ref
        .read(recipeVersionsProvider(current.recipe.id).notifier)
        .createVersion(recipe: current, note: note);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verzija spremljena.')));
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    RecipeVersion version,
    RecipeWithDetails current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vratiti na verziju v${version.versionNumber}?'),
        content: const Text(
          'Trenutno stanje recepta bit će automatski spremljeno kao nova verzija prije vraćanja.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Vrati')),
        ],
      ),
    );
    if (confirmed != true) return;

    final recipeId = current.recipe.id;
    final versionsNotifier = ref.read(recipeVersionsProvider(recipeId).notifier);

    // Safety net: never let a restore be a dead end.
    await versionsNotifier.createVersion(
      recipe: current,
      note: 'Automatski spremljeno prije vraćanja na v${version.versionNumber}',
    );

    final snapshot = RecipeSnapshot.fromVersion(version);
    final restoredRecipe = snapshot.recipe.copyWith(
      id: recipeId,
      isFavorite: current.recipe.isFavorite,
      createdAt: current.recipe.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(recipeListProvider.notifier).updateRecipe(
          recipe: restoredRecipe,
          ingredients: snapshot.ingredients.map((i) => i.copyWith(recipeId: recipeId)).toList(),
          steps: snapshot.steps.map((s) => s.copyWith(recipeId: recipeId)).toList(),
          images: current.images,
          tagIds: snapshot.tagIds,
        );

    await versionsNotifier.loadVersions();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recept vraćen na verziju v${version.versionNumber}.')),
      );
    }
  }

  Future<String?> _promptForNote(BuildContext context, {required String title}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Bilješka (opcionalno)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Spremi'),
          ),
        ],
      ),
    );
  }
}
