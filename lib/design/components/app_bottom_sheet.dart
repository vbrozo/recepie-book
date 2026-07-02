import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Standard iOS-style sheet: rounded top corners, drag handle, title.
/// Used for filters (Lista recepata) and category/tag pickers.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.colors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.sheetRadius)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.colors.hairline, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Text(title, style: context.typography.sans(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.ink)),
            const SizedBox(height: 16),
            Builder(builder: builder),
          ],
        ),
      ),
    ),
  );
}
