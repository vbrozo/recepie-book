import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/recipe_list_provider.dart';
import '../../providers/tag_list_provider.dart';

/// Lists every tag in the app and lets the user delete one (which detaches
/// it from every recipe it was on, via the `recipe_tags` FK cascade).
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tagovi')),
      body: tags.isEmpty
          ? const Center(child: Text('Nema tagova još. Dodaj ih iz forme za recept.'))
          : ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(tag.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, tag.id, tag.name),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Obriši tag "$name"?'),
        content: const Text('Tag će biti uklonjen sa svih recepata.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Obriši')),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(tagListProvider.notifier).deleteTag(id);
    // Recipes already loaded in memory still carry the deleted tag until
    // we refetch them.
    await ref.read(recipeListProvider.notifier).loadRecipes();
  }
}
