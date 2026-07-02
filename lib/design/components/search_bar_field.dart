import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_typography.dart';

/// 48–52px pill/rounded-rect, leading search icon, optional trailing
/// filter icon (orange-tinted).
class SearchBarField extends StatelessWidget {
  const SearchBarField({
    super.key,
    required this.controller,
    this.hintText = 'Traži recepte…',
    this.onChanged,
    this.onFilterTap,
    this.height = 52,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: context.colors.faint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: context.typography.sans(fontSize: 15, color: context.colors.ink),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: context.typography.sans(fontSize: 15, color: context.colors.faint),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              icon: Icon(Icons.tune, color: context.colors.orange, size: 20),
              onPressed: onFilterTap,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
