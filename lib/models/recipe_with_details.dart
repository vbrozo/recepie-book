import 'ingredient.dart';
import 'recipe.dart';
import 'recipe_image.dart';
import 'recipe_step.dart';
import 'tag.dart';

/// A [Recipe] together with everything that belongs to it. This is a
/// read-side composite (not backed by its own table) returned by
/// [RecipeRepository] whenever a full recipe needs to be assembled from
/// its child tables.
class RecipeWithDetails {
  final Recipe recipe;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeImage> images;
  final List<Tag> tags;

  const RecipeWithDetails({
    required this.recipe,
    this.ingredients = const [],
    this.steps = const [],
    this.images = const [],
    this.tags = const [],
  });

  RecipeWithDetails copyWith({
    Recipe? recipe,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    List<RecipeImage>? images,
    List<Tag>? tags,
  }) {
    return RecipeWithDetails(
      recipe: recipe ?? this.recipe,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      images: images ?? this.images,
      tags: tags ?? this.tags,
    );
  }
}
