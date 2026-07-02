import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/components/app_bottom_tab_bar.dart';
import '../../design/components/app_fab.dart';
import '../shopping_list/widgets/add_shopping_item_sheet.dart';

/// App-wide shell: persistent bottom tab bar (Home / Recepti / Shopping /
/// Postavke) + a floating "+" FAB, hidden on Postavke (and, by virtue of
/// being pushed outside the shell, hidden entirely on Cook mode/fullscreen
/// editors/gallery — see app.dart's route tree).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  bool get _showFab => navigationShell.currentIndex != 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: AppSpacing.tabBarHeight,
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
          if (_showFab)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.tabBarHeight + 24,
              child: Center(child: AppFab(onPressed: () => _onFabTap(context, ref))),
            ),
        ],
      ),
    );
  }

  void _onFabTap(BuildContext context, WidgetRef ref) {
    // Home and Recepti both start "add recipe". Shopping's FAB instead
    // quick-adds a manual shopping item via a small sheet, since the
    // shopping list has no separate "new recipe"-style flow.
    if (navigationShell.currentIndex == 2) {
      showAddShoppingItemSheet(context, ref);
    } else {
      context.push('/recipe/new');
    }
  }
}
