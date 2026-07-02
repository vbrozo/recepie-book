import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/recipe_detail/recipe_detail_screen.dart';
import 'features/recipe_form/recipe_form_screen.dart';
import 'features/recipe_list/recipe_list_screen.dart';
import 'features/recipe_versions/recipe_versions_screen.dart';
import 'features/shopping_list/shopping_list_screen.dart';
import 'features/tags/tags_screen.dart';
import 'models/recipe_with_details.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RecipeListScreen(),
    ),
    GoRoute(
      path: '/recipe/new',
      builder: (context, state) => const RecipeFormScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) => RecipeDetailScreen(
        recipeId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/recipe/:id/edit',
      builder: (context, state) => RecipeFormScreen(
        existing: state.extra as RecipeWithDetails?,
      ),
    ),
    GoRoute(
      path: '/recipe/:id/versions',
      builder: (context, state) => RecipeVersionsScreen(
        recipeId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/tags',
      builder: (context, state) => const TagsScreen(),
    ),
    GoRoute(
      path: '/shopping-list',
      builder: (context, state) => const ShoppingListScreen(),
    ),
  ],
);

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Recipe Book',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
