import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design/app_colors.dart';
import 'design/app_typography.dart';
import 'features/cook_mode/cook_mode_screen.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/home/home_screen.dart';
import 'features/recipe_detail/recipe_detail_screen.dart';
import 'features/recipe_form/recipe_form_screen.dart';
import 'features/recipe_list/recipe_list_screen.dart';
import 'features/recipe_versions/recipe_versions_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shopping_list/shopping_list_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/tags/tags_screen.dart';
import 'models/recipe_with_details.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // Persistent bottom-tab shell: Home / Recepti / Shopping / Postavke.
    // Everything else (detail, edit, versions, gallery, cook mode, tags) is
    // pushed on the root navigator so it renders fullscreen, without the
    // tab bar/FAB — matches the Figma spec ("always visible except in Cook
    // mode and full-screen editors/galleries").
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/recipes', builder: (context, state) => const RecipeListScreen())]),
        StatefulShellBranch(
          routes: [GoRoute(path: '/shopping-list', builder: (context, state) => const ShoppingListScreen())],
        ),
        StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())]),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/new',
      builder: (context, state) => const RecipeFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id',
      builder: (context, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id/edit',
      builder: (context, state) => RecipeFormScreen(existing: state.extra as RecipeWithDetails?),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id/versions',
      builder: (context, state) => RecipeVersionsScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id/gallery',
      builder: (context, state) => GalleryScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id/cook',
      builder: (context, state) => CookModeScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tags',
      builder: (context, state) => const TagsScreen(),
    ),
  ],
);

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kuharica',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          surface: AppColors.surface,
        ),
        textTheme: AppTypography.textTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
          ),
          labelStyle: AppTypography.eyebrow(),
          hintStyle: AppTypography.sans(color: AppColors.faint),
        ),
      ),
      routerConfig: _router,
    );
  }
}
