import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_list_provider.dart';
import '../../providers/tag_list_provider.dart';
import 'widgets/recipe_filter_bar.dart';
import 'widgets/recipe_list_tile.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeListProvider);
    final notifier = ref.read(recipeListProvider.notifier);
    final tags = ref.watch(tagListProvider);
    final visibleRecipes = state.filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Tagovi',
            onPressed: () => context.push('/tags'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži recepte...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchRecipes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: notifier.searchRecipes,
            ),
          ),
          RecipeFilterBar(state: state, notifier: notifier, tags: tags),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: state.isLoading && state.recipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : visibleRecipes.isEmpty
                    ? Center(
                        child: Text(
                          state.isSearching
                              ? 'Nema recepata za "${state.searchQuery}"'
                              : state.hasActiveFilters
                                  ? 'Nema recepata za odabrane filtere.'
                                  : 'Nema recepata. Dodaj prvi!',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: notifier.loadRecipes,
                        child: ListView.builder(
                          itemCount: visibleRecipes.length,
                          itemBuilder: (context, index) {
                            final item = visibleRecipes[index];
                            return RecipeListTile(
                              item: item,
                              onTap: () =>
                                  context.push('/recipe/${item.recipe.id}'),
                              onFavoriteToggle: () =>
                                  notifier.toggleFavorite(item.recipe.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recipe/new'),
        tooltip: 'Dodaj recept',
        child: const Icon(Icons.add),
      ),
    );
  }
}
