import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_list_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Recepti')),
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
                : state.recipes.isEmpty
                    ? Center(
                        child: Text(
                          state.isSearching
                              ? 'Nema recepata za "${state.searchQuery}"'
                              : 'Nema recepata. Dodaj prvi!',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: notifier.loadRecipes,
                        child: ListView.builder(
                          itemCount: state.recipes.length,
                          itemBuilder: (context, index) {
                            final item = state.recipes[index];
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
