import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

/// 62px orange circle, plus icon, drop shadow. Present on Home, Lista
/// recepata and Shopping.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.fabSize,
      height: AppSpacing.fabSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
        boxShadow: [BoxShadow(color: AppColors.orangeShadow, blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
