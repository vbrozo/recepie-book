import 'package:flutter/material.dart';

import '../../../models/recipe_version.dart';

class RecipeVersionTile extends StatelessWidget {
  const RecipeVersionTile({super.key, required this.version, required this.onRestore});

  final RecipeVersion version;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final hasNote = version.note != null && version.note!.trim().isNotEmpty;

    return ListTile(
      leading: CircleAvatar(child: Text('v${version.versionNumber}')),
      title: Text(hasNote ? version.note! : 'Verzija ${version.versionNumber}'),
      subtitle: Text(_formatDate(version.createdAt)),
      trailing: TextButton(onPressed: onRestore, child: const Text('Vrati')),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
