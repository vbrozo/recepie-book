import 'dart:ui';

import 'package:flutter/material.dart';

/// Floating glass-style circular icon button, used over hero images
/// (Detalji recepta) and fullscreen viewers.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.color = Colors.white});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withValues(alpha: 0.25),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, color: color, size: 20)),
          ),
        ),
      ),
    );
  }
}
