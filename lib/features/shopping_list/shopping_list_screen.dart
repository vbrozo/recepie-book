import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/components/empty_state.dart';
import '../../providers/shopping_list_provider.dart';
import 'widgets/add_shopping_item_sheet.dart';
import 'widgets/shopping_list_item_tile.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingListProvider);
    final notifier = ref.read(shoppingListProvider.notifier);
    final grouped = state.groupedByCategory;
    final categories = grouped.keys.toList()..sort();
    final pending = state.items.where((item) => !item.isChecked).length;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shopping lista', style: context.typography.serif(fontSize: 34)),
                      if (state.hasCompleted)
                        TextButton(
                          onPressed: notifier.clearCompleted,
                          child: Text('Očisti', style: context.typography.sans(fontWeight: FontWeight.w600, color: context.colors.orange)),
                        ),
                    ],
                  ),
                  Text(
                    state.items.isEmpty ? 'Lista je prazna' : '$pending od ${state.items.length} preostalo',
                    style: context.typography.sans(fontSize: 13, color: context.colors.muted),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(state.errorMessage!, style: context.typography.sans(color: context.colors.orangeDeep, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          message: 'Lista je prazna.\nDodaj namirnicu ili je pošalji iz recepta.',
                          ctaLabel: 'Dodaj namirnicu',
                          onCtaTap: () => showAddShoppingItemSheet(context, ref),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            20,
                            AppSpacing.screenPadding,
                            140,
                          ),
                          children: [
                            for (final category in categories) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  category.toUpperCase(),
                                  style: context.typography.sans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.muted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: context.colors.hairline),
                                ),
                                child: Column(
                                  children: [
                                    for (final item in grouped[category]!)
                                      ShoppingListItemTile(
                                        item: item,
                                        onToggle: () => notifier.toggleChecked(item.id),
                                        onDelete: () => notifier.deleteItem(item.id),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            _AddItemAffordance(onTap: () => showAddShoppingItemSheet(context, ref)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemAffordance extends StatelessWidget {
  const _AddItemAffordance({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.faintAlt),
        ),
        child: Text(
          '+ Dodaj namirnicu',
          style: context.typography.sans(fontWeight: FontWeight.w600, color: context.colors.orangeDeep),
        ),
      ),
    );
  }
}
