import 'package:flutter/material.dart';

import '../../../models/tag.dart';
import '../../../providers/recipe_notifier.dart';
import '../../../providers/recipe_state.dart';

const _prepTimePresets = [15, 30, 60];

/// Favorites / prep-time / tag filter controls for the recipe list.
class RecipeFilterBar extends StatelessWidget {
  const RecipeFilterBar({
    super.key,
    required this.state,
    required this.notifier,
    required this.tags,
  });

  final RecipeState state;
  final RecipeNotifier notifier;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Favoriti'),
                avatar: const Icon(Icons.favorite, size: 18),
                selected: state.favoritesOnly,
                onSelected: notifier.setFavoritesOnly,
              ),
              for (final minutes in _prepTimePresets)
                FilterChip(
                  label: Text('≤ $minutes min'),
                  selected: state.maxPrepTimeMinutes == minutes,
                  onSelected: (selected) =>
                      notifier.setMaxPrepTime(selected ? minutes : null),
                ),
              if (state.hasActiveFilters)
                ActionChip(
                  label: const Text('Očisti filtere'),
                  avatar: const Icon(Icons.clear, size: 18),
                  onPressed: notifier.clearFilters,
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final selected = state.tagFilterId == tag.id;
                  return FilterChip(
                    label: Text(tag.name),
                    selected: selected,
                    onSelected: (isSelected) =>
                        notifier.setTagFilter(isSelected ? tag.id : null),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
