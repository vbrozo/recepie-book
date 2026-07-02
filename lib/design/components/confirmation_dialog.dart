import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Centered modal for destructive actions — orange primary action,
/// outline/text cancel.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Potvrdi',
  String cancelLabel = 'Odustani',
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.typography.serif(fontSize: 20)),
            const SizedBox(height: 8),
            Text(message, style: context.typography.sans(fontSize: 14, color: context.colors.muted)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelLabel, style: context.typography.sans(fontWeight: FontWeight.w600, color: context.colors.muted)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: destructive ? context.colors.orangeDeep : context.colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel, style: context.typography.sans(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed ?? false;
}
