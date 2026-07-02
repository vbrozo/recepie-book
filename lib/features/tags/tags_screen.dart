import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/components/confirmation_dialog.dart';
import '../../design/components/empty_state.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/tag_list_provider.dart';

/// Lists every tag in the app and lets the user delete one (which detaches
/// it from every recipe it was on, via the `recipe_tags` FK cascade). Not
/// part of the Figma flow — reachable from the Lista recepata filter sheet.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagListProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                  Text('Tagovi', style: context.typography.sans(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.ink)),
                ],
              ),
            ),
            Expanded(
              child: tags.isEmpty
                  ? const EmptyState(icon: Icons.label_outline, message: 'Nema tagova još.\nDodaj ih iz forme za recept.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.colors.hairline),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.label_outline, size: 18, color: context.colors.olive),
                              const SizedBox(width: 10),
                              Expanded(child: Text(tag.name, style: context.typography.sans(fontSize: 15, color: context.colors.ink))),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: context.colors.orangeDeep),
                                onPressed: () => _confirmDelete(context, ref, tag.id, tag.name),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Obriši tag "$name"?',
      message: 'Tag će biti uklonjen sa svih recepata.',
      confirmLabel: 'Obriši',
    );
    if (!confirmed) return;

    await ref.read(tagListProvider.notifier).deleteTag(id);
    // Recipes already loaded in memory still carry the deleted tag until
    // we refetch them.
    await ref.read(recipeListProvider.notifier).loadRecipes();
  }
}
