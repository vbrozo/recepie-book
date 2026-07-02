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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.colors.orangeSoft, shape: BoxShape.circle),
            child: Text(
              '$stepNumber',
              style: context.typography.sans(fontWeight: FontWeight.w700, color: context.colors.orangeDeep, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: context.typography.sans(fontSize: 15, color: context.colors.inkSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
