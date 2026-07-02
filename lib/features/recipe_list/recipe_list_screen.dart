import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/components/empty_state.dart';
import '../../design/components/recipe_card.dart';
import '../../design/components/search_bar_field.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/tag_list_provider.dart';
import 'widgets/recipe_filter_sheet.dart';

/// Also serves as the search-results view: arriving with an active
/// `searchQuery` (set from Home's search bar) just shows filtered results
/// here instead of a separate screen.
class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(recipeListProvider).searchQuery);
  }

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

    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
      _searchController.selection = TextSelection.collapsed(offset: _searchController.text.length);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Recepti', style: AppTypography.serif(fontSize: 34)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${state.recipes.length} recepta',
                          style: AppTypography.sans(fontSize: 14, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SearchBarField(
                    controller: _searchController,
                    height: 48,
                    onChanged: notifier.searchRecipes,
                    onFilterTap: () => showRecipeFilterSheet(context, state: state, notifier: notifier, tags: tags),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(state.errorMessage!, style: AppTypography.sans(color: AppColors.orangeDeep, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.recipes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visibleRecipes.isEmpty
                      ? EmptyState(
                          icon: state.isSearching || state.hasActiveFilters ? Icons.search_off : Icons.restaurant_menu,
                          message: state.isSearching
                              ? 'Nema recepata za "${state.searchQuery}"'
                              : state.hasActiveFilters
                                  ? 'Nema recepata za odabrane filtere.'
                                  : 'Nema recepata. Dodaj prvi!',
                          ctaLabel: state.isSearching || state.hasActiveFilters ? null : 'Dodaj recept',
                          onCtaTap: state.isSearching || state.hasActiveFilters ? null : () => context.push('/recipe/new'),
                        )
                      : RefreshIndicator(
                          onRefresh: notifier.loadRecipes,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              16,
                              AppSpacing.screenPadding,
                              140,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: visibleRecipes.length,
                            itemBuilder: (context, index) {
                              final item = visibleRecipes[index];
                              return RecipeCard(
                                item: item,
                                onTap: () => context.push('/recipe/${item.recipe.id}'),
                                onFavoriteToggle: () => notifier.toggleFavorite(item.recipe.id),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
