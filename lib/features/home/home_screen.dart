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
import 'widgets/compact_recipe_row.dart';

const _weekdays = ['Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja'];
const _months = [
  'siječnja', 'veljače', 'ožujka', 'travnja', 'svibnja', 'lipnja',
  'srpnja', 'kolovoza', 'rujna', 'listopada', 'studenoga', 'prosinca',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeListProvider);
    final now = DateTime.now();
    final dateLabel = '${_weekdays[now.weekday - 1]}, ${now.day}. ${_months[now.month - 1]}';

    final recent = [...state.recipes]..sort((a, b) => b.recipe.createdAt.compareTo(a.recipe.createdAt));
    final favorites = state.recipes.where((item) => item.recipe.isFavorite).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: state.isLoading && state.recipes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null && state.recipes.isEmpty
                ? EmptyState(
                    icon: Icons.error_outline,
                    message: 'Recepti se nisu mogli učitati.\n${state.errorMessage}',
                    ctaLabel: 'Pokušaj ponovno',
                    onCtaTap: () => ref.read(recipeListProvider.notifier).loadRecipes(),
                  )
                : state.recipes.isEmpty
                    ? EmptyState(
                        icon: Icons.restaurant_menu,
                        message: 'Nema recepata još.\nDodaj svoj prvi recept!',
                        ctaLabel: 'Dodaj recept',
                        onCtaTap: () => context.push('/recipe/new'),
                      )
                    : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      16,
                      AppSpacing.screenPadding,
                      140,
                    ),
                    children: [
                      Text(dateLabel, style: context.typography.sans(fontSize: 14, color: context.colors.mutedAlt)),
                      const SizedBox(height: 4),
                      Text('Moji recepti', style: context.typography.serif(fontSize: 34)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go('/recipes'),
                        child: AbsorbPointer(
                          child: SearchBarField(controller: _searchController, onFilterTap: () {}),
                        ),
                      ),
                      if (recent.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nedavno dodano', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
                            GestureDetector(
                              onTap: () => context.go('/recipes'),
                              child: Text('Sve', style: context.typography.sans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.orange)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 210,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recent.take(10).length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = recent[index];
                              return RecipeCard(
                                item: item,
                                variant: RecipeCardVariant.large,
                                onTap: () => context.push('/recipe/${item.recipe.id}'),
                                onFavoriteToggle: () =>
                                    ref.read(recipeListProvider.notifier).toggleFavorite(item.recipe.id),
                              );
                            },
                          ),
                        ),
                      ],
                      if (favorites.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('Omiljeni', style: context.typography.sans(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
                        for (final item in favorites)
                          CompactRecipeRow(item: item, onTap: () => context.push('/recipe/${item.recipe.id}')),
                      ],
                    ],
                  ),
      ),
    );
  }
}
