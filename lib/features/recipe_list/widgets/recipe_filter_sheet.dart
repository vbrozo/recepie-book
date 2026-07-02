import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';
import '../../../design/components/app_bottom_sheet.dart';
import '../../../design/components/tag_chip.dart';
import '../../../models/tag.dart';
import '../../../providers/recipe_notifier.dart';
import '../../../providers/recipe_state.dart';

const _prepTimePresets = [15, 30, 60];

/// Filter controls (favorites / prep-time / tag) shown as a bottom sheet,
/// triggered by the filter icon on the search bar.
Future<void> showRecipeFilterSheet(
  BuildContext context, {
  required RecipeState state,
  required RecipeNotifier notifier,
  required List<Tag> tags,
}) {
  return showAppBottomSheet<void>(
    context,
    title: 'Filteri',
    builder: (context) => _RecipeFilterSheetContent(state: state, notifier: notifier, tags: tags),
  );
}

class _RecipeFilterSheetContent extends StatelessWidget {
  const _RecipeFilterSheetContent({required this.state, required this.notifier, required this.tags});

  final RecipeState state;
  final RecipeNotifier notifier;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TagChip(
              label: 'Favoriti',
              leading: Icons.favorite,
              variant: TagChipVariant.outline,
              selected: state.favoritesOnly,
              onTap: () => notifier.setFavoritesOnly(!state.favoritesOnly),
            ),
            for (final minutes in _prepTimePresets)
              TagChip(
                label: '≤ $minutes min',
                variant: TagChipVariant.outline,
                selected: state.maxPrepTimeMinutes == minutes,
                onTap: () => notifier.setMaxPrepTime(state.maxPrepTimeMinutes == minutes ? null : minutes),
              ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Tagovi', style: context.typography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                TagChip(
                  label: tag.name,
                  variant: TagChipVariant.outline,
                  selected: state.tagFilterId == tag.id,
                  onTap: () => notifier.setTagFilter(state.tagFilterId == tag.id ? null : tag.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            if (state.hasActiveFilters)
              TextButton(
                onPressed: notifier.clearFilters,
                child: Text('Očisti filtere', style: context.typography.sans(fontWeight: FontWeight.w600, color: context.colors.orangeDeep)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/tags');
              },
              child: Text('Upravljaj tagovima', style: context.typography.sans(fontWeight: FontWeight.w600, color: context.colors.muted)),
            ),
          ],
        ),
      ],
    );
  }
}
