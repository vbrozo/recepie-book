import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/components/app_bottom_sheet.dart';
import '../../providers/theme_mode_provider.dart';
import 'widgets/settings_row.dart';

const _themeOptions = [
  (mode: ThemeMode.system, label: 'Sustav', icon: Icons.brightness_auto),
  (mode: ThemeMode.light, label: 'Svijetla', icon: Icons.light_mode_outlined),
  (mode: ThemeMode.dark, label: 'Tamna', icon: Icons.dark_mode_outlined),
];

/// App-level settings — the only non-recipe-content screen. Backup/
/// Import/Export rows are presentational only (per product decision) —
/// there is no import/export implementation behind them yet.
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
                  icon: Icons.cloud_done_outlined,
                  iconBackground: context.colors.oliveSoft,
                  iconColor: context.colors.olive,
                  label: 'Backup',
                  trailingText: 'Uključen',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.file_download_outlined,
                  iconBackground: context.colors.oliveSoft,
                  iconColor: context.colors.olive,
                  label: 'Import recepata',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.file_upload_outlined,
                  iconBackground: context.colors.oliveSoft,
                  iconColor: context.colors.olive,
                  label: 'Export recepata',
                  onTap: () => _comingSoon(context),
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

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uskoro dostupno.')));
  }
}
