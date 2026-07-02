import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import 'widgets/settings_row.dart';

/// App-level settings — the only non-recipe-content screen. Backup/
/// Import/Export rows are presentational only (per product decision) —
/// there is no import/export implementation behind them yet.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 140),
          children: [
            Text('Postavke', style: AppTypography.serif(fontSize: 34)),
            const SizedBox(height: 20),
            SettingsSection(
              header: 'IZGLED',
              rows: [
                SettingsRow(
                  icon: Icons.light_mode_outlined,
                  iconBackground: AppColors.orangeSoft,
                  iconColor: AppColors.orange,
                  label: 'Tema',
                  trailingText: 'Svijetla',
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
            SettingsSection(
              header: 'PODACI',
              rows: [
                SettingsRow(
                  icon: Icons.cloud_done_outlined,
                  iconBackground: AppColors.oliveSoft,
                  iconColor: AppColors.olive,
                  label: 'Backup',
                  trailingText: 'Uključen',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.file_download_outlined,
                  iconBackground: AppColors.oliveSoft,
                  iconColor: AppColors.olive,
                  label: 'Import recepata',
                  onTap: () => _comingSoon(context),
                ),
                SettingsRow(
                  icon: Icons.file_upload_outlined,
                  iconBackground: AppColors.oliveSoft,
                  iconColor: AppColors.olive,
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
                  iconBackground: AppColors.orangeSoft,
                  iconColor: AppColors.orange,
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

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uskoro dostupno.')));
  }
}
