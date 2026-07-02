import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/confirmation_dialog.dart';
import '../../design/components/empty_state.dart';
import '../../design/components/version_card.dart';
import '../../models/recipe_snapshot.dart';
import '../../models/recipe_version.dart';
import '../../models/recipe_with_details.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/recipe_versions_provider.dart';
import 'version_diff.dart';

/// History of saved snapshots for one recipe: a vertical timeline, newest
/// (active) first, with a diff of ingredient changes against the version
/// right before it. Tapping a past version offers to restore it.
class RecipeVersionsScreen extends ConsumerWidget {
  const RecipeVersionsScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeState = ref.watch(recipeListProvider);
    RecipeWithDetails? current;
    for (final recipe in recipeState.recipes) {
      if (recipe.recipe.id == recipeId) {
        current = recipe;
        break;
      }
    }

    final versionState = ref.watch(recipeVersionsProvider(recipeId));
    final versions = versionState.versions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                  Expanded(
                    child: Text(
                      'Verzije recepta',
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  if (current != null)
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined),
                      tooltip: 'Spremi trenutnu verziju',
                      onPressed: () => _saveVersion(context, ref, current!),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.recipe.title, style: AppTypography.serif(fontSize: 24)),
                    const SizedBox(height: 2),
                    Text(
                      versions.isEmpty ? 'Nema spremljenih verzija' : '${versions.length} ${versions.length == 1 ? 'verzija' : 'verzija'}',
                      style: AppTypography.sans(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: versionState.isLoading && versions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : versions.isEmpty
                      ? const EmptyState(icon: Icons.history, message: 'Još nema spremljenih verzija.')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          itemCount: versions.length,
                          itemBuilder: (context, index) {
                            final version = versions[index];
                            final previous = index + 1 < versions.length ? versions[index + 1] : null;
                            final diff = computeVersionDiff(previous, version);
                            final isActive = index == 0;
                            final isOriginal = previous == null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VersionCard(
                                  title: 'Verzija ${version.versionNumber}',
                                  dateLabel: _formatDate(version.createdAt),
                                  isActive: isActive,
                                  note: isOriginal
                                      ? (version.note ?? 'Prvi zapis recepta')
                                      : version.note,
                                  addedChips: diff.added,
                                  removedChips: diff.removed,
                                  onTap: isActive || current == null
                                      ? null
                                      : () => _restore(context, ref, version, current!),
                                ),
                                if (index != versions.length - 1)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 24),
                                    child: SizedBox(
                                      height: 20,
                                      child: VerticalDivider(width: 2, thickness: 2, color: Color(0xFFE0D6C2)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _saveVersion(BuildContext context, WidgetRef ref, RecipeWithDetails current) async {
    await ref.read(recipeVersionsProvider(current.recipe.id).notifier).createVersion(recipe: current);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verzija spremljena.')));
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    RecipeVersion version,
    RecipeWithDetails current,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Vratiti na verziju v${version.versionNumber}?',
      message: 'Trenutno stanje recepta bit će automatski spremljeno kao nova verzija prije vraćanja.',
      confirmLabel: 'Vrati',
      destructive: false,
    );
    if (!confirmed) return;

    final recipeId = current.recipe.id;
    final versionsNotifier = ref.read(recipeVersionsProvider(recipeId).notifier);

    await versionsNotifier.createVersion(
      recipe: current,
      note: 'Automatski spremljeno prije vraćanja na v${version.versionNumber}',
    );

    final snapshot = RecipeSnapshot.fromVersion(version);
    final restoredRecipe = snapshot.recipe.copyWith(
      id: recipeId,
      isFavorite: current.recipe.isFavorite,
      createdAt: current.recipe.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(recipeListProvider.notifier).updateRecipe(
          recipe: restoredRecipe,
          ingredients: snapshot.ingredients.map((i) => i.copyWith(recipeId: recipeId)).toList(),
          steps: snapshot.steps.map((s) => s.copyWith(recipeId: recipeId)).toList(),
          images: current.images,
          tagIds: snapshot.tagIds,
        );

    await versionsNotifier.loadVersions();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recept vraćen na verziju v${version.versionNumber}.')),
      );
    }
  }
}
