import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/backup_service.dart';
import '../../core/backup/browser_download.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/components/app_bottom_sheet.dart';
import '../../providers/backup_service_provider.dart';
import '../../providers/recipe_list_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/tag_list_provider.dart';
import '../../providers/theme_mode_provider.dart';
import 'widgets/settings_row.dart';

const _themeOptions = [
  (mode: ThemeMode.system, label: 'Sustav', icon: Icons.brightness_auto),
  (mode: ThemeMode.light, label: 'Svijetla', icon: Icons.light_mode_outlined),
  (mode: ThemeMode.dark, label: 'Tamna', icon: Icons.dark_mode_outlined),
];

/// App-level settings — the only non-recipe-content screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeLabel = _themeOptions.firstWhere((option) => option.mode == themeMode).label;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 140),
          children: [
            Text('Postavke', style: context.typography.serif(fontSize: 34)),
            const SizedBox(height: 20),
            SettingsSection(
              header: 'IZGLED',
              rows: [
                SettingsRow(
                  icon: Icons.light_mode_outlined,
                  iconBackground: context.colors.orangeSoft,
                  iconColor: context.colors.orange,
                  label: 'Tema',
                  trailingText: themeLabel,
                  onTap: () => _openThemePicker(context, ref),
                ),
              ],
            ),
            SettingsSection(
              header: 'PODACI',
              rows: [
                SettingsRow(
                  icon: Icons.file_upload_outlined,
                  iconBackground: context.colors.oliveSoft,
                  iconColor: context.colors.olive,
                  label: 'Export recepata',
                  showChevron: false,
                  onTap: () => _exportRecipes(context, ref),
                ),
                SettingsRow(
                  icon: Icons.file_download_outlined,
                  iconBackground: context.colors.oliveSoft,
                  iconColor: context.colors.olive,
                  label: 'Import recepata',
                  showChevron: false,
                  onTap: () => _importRecipes(context, ref),
                ),
              ],
            ),
            SettingsSection(
              header: 'OSTALO',
              rows: [
                SettingsRow(
                  icon: Icons.info_outline,
                  iconBackground: context.colors.orangeSoft,
                  iconColor: context.colors.orange,
                  label: 'O aplikaciji',
                  trailingText: 'v1.0',
                  showChevron: false,
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openThemePicker(BuildContext context, WidgetRef ref) {
    return showAppBottomSheet<void>(
      context,
      title: 'Tema',
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(themeModeProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in _themeOptions)
                InkWell(
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(option.mode),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: selected == option.mode ? context.colors.orange : context.colors.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(option.label, style: context.typography.sans(fontSize: 15, color: context.colors.ink)),
                        ),
                        if (selected == option.mode) Icon(Icons.check, size: 20, color: context.colors.orange),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the whole recipe collection (+ tags, images, shopping list) into
  /// a single `.zip` and hands it to the user — a browser download on web,
  /// a native save dialog otherwise. See [BackupService] for the format.
  Future<void> _exportRecipes(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context, 'Izvoz recepata…');
    try {
      final bytes = await ref.read(backupServiceProvider).exportToZipBytes();
      final fileName = 'kuharica-backup-${_dateStamp(DateTime.now())}.zip';

      if (kIsWeb) {
        triggerBrowserDownload(bytes, fileName);
      } else {
        await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup spremljen ($fileName).')),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izvoz nije uspio: $error')),
      );
    }
  }

  /// Lets the user pick a `.zip` backup file and restores everything in it
  /// as new recipes/tags/shopping items — never overwrites what's already
  /// in the app (see [BackupService] doc comment).
  Future<void> _importRecipes(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Odabir datoteke nije uspio: $error')),
      );
      return;
    }
    if (picked == null || picked.files.isEmpty) return; // user cancelled

    final pickedFile = picked.files.single;
    Uint8List? bytes = pickedFile.bytes;
    if (bytes == null && pickedFile.path != null) {
      bytes = await File(pickedFile.path!).readAsBytes();
    }
    if (bytes == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odabrana datoteka nije čitljiva.')),
      );
      return;
    }

    if (!context.mounted) return;
    _showLoadingDialog(context, 'Uvoz recepata…');
    try {
      final result = await ref.read(backupServiceProvider).importFromZipBytes(bytes);

      // Every repository the import touched needs its provider state
      // refreshed — nothing in the app currently listens for DB writes
      // that didn't go through the notifier that owns that state.
      await ref.read(recipeListProvider.notifier).loadRecipes();
      await ref.read(tagListProvider.notifier).loadTags();
      await ref.read(shoppingListProvider.notifier).loadItems();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uvezeno ${result.recipeCount} ${result.recipeCount == 1 ? 'recept' : 'recepata'}'
            '${result.shoppingItemCount > 0 ? ' i ${result.shoppingItemCount} stavki liste' : ''}.',
          ),
        ),
      );
    } on BackupFormatException catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uvoz nije uspio: $error')),
      );
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 20),
              Expanded(child: Text(message, style: context.typography.sans(fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }

  String _dateStamp(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}';
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uskoro dostupno.')));
  }
}
