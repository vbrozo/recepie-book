import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

/// White card, leading circular step-number badge, instruction body text.
class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.stepNumber, required this.instruction});

  final int stepNumber;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
            child: Text(
              '$stepNumber',
              style: AppTypography.sans(fontWeight: FontWeight.w700, color: AppColors.orangeDeep, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: AppTypography.sans(fontSize: 15, color: AppColors.inkSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
