import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_typography.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    this.trailingText,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String? trailingText;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: context.typography.sans(fontSize: 15, color: context.colors.ink))),
            if (trailingText != null)
              Text(trailingText!, style: context.typography.sans(fontSize: 13, color: context.colors.muted)),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: context.colors.faint),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.header, required this.rows});

  final String header;
  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              header,
              style: context.typography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.muted, letterSpacing: 0.6),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i != rows.length - 1) Divider(height: 1, color: context.colors.hairline, indent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
