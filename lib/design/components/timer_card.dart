import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

/// White bordered card, ring icon, tabular-numeral time display, play/pause.
class TimerCard extends StatelessWidget {
  const TimerCard({
    super.key,
    required this.timeLabel,
    required this.isRunning,
    required this.onToggle,
    this.progress = 0,
    this.label = 'Tajmer za kuhanje',
  });

  final String timeLabel;
  final bool isRunning;
  final VoidCallback onToggle;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 3,
                  backgroundColor: AppColors.hairline,
                  valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: AppTypography.sans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(label, style: AppTypography.sans(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
              child: Icon(isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
