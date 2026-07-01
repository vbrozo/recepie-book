import 'package:flutter/material.dart';

import '../../../models/recipe_with_details.dart';

class RecipeListTile extends StatelessWidget {
  const RecipeListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final RecipeWithDetails item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.restaurant_menu)),
      title: Text(recipe.title),
      subtitle: Text(
        '${item.ingredients.length} sastojaka · ${item.steps.length} koraka',
      ),
      trailing: IconButton(
        icon: Icon(
          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: recipe.isFavorite ? Colors.red : null,
        ),
        onPressed: onFavoriteToggle,
      ),
      onTap: onTap,
    );
  }
}
