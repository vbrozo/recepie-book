import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import 'tag_chip.dart';

/// Version history card. Active versions get an orange border + "Aktivna"
/// badge + a wrapping row of diff chips; past versions are plain with a
/// trailing chevron.
class VersionCard extends StatelessWidget {
  const VersionCard({
    super.key,
    required this.title,
    required this.dateLabel,
    this.isActive = false,
    this.note,
    this.addedChips = const [],
    this.removedChips = const [],
    this.onTap,
  });

  final String title;
  final String dateLabel;
  final bool isActive;
  final String? note;
  final List<String> addedChips;
  final List<String> removedChips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.orange : AppColors.hairline, width: isActive ? 1.5 : 1),
          boxShadow: isActive
              ? const [BoxShadow(color: AppColors.orangeShadow, blurRadius: 16, offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.sans(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)),
                ),
                if (isActive) const TagChip(label: 'Aktivna', variant: TagChipVariant.orange),
                if (!isActive && onTap != null)
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.faint),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: AppTypography.sans(fontSize: 12, color: AppColors.muted)),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note!, style: AppTypography.sans(fontSize: 13, color: AppColors.inkSecondary)),
            ],
            if (addedChips.isNotEmpty || removedChips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in addedChips) TagChip(label: '+ $label', variant: TagChipVariant.diffAdded),
                  for (final label in removedChips) TagChip(label: '− $label', variant: TagChipVariant.diffRemoved),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
