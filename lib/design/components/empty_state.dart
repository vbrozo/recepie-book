import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import 'primary_button.dart';

/// Centered icon in a soft-tinted circle (matching the Splash logo
/// treatment), short message, optional primary CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
  });

  final IconData icon;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: context.colors.orangeSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: context.colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.typography.sans(fontSize: 15, color: context.colors.muted),
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(label: ctaLabel!, onPressed: onCtaTap, icon: Icons.add),
            ],
          ],
        ),
      ),
    );
  }
}
