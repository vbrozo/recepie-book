import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

class TabSpec {
  const TabSpec({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// 4-tab bottom bar: Home / Recepti / Shopping / Postavke. Active tab is
/// orange + weight 600, inactive is muted.
class AppBottomTabBar extends StatelessWidget {
  const AppBottomTabBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const tabs = [
    TabSpec(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    TabSpec(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Recepti'),
    TabSpec(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Shopping'),
    TabSpec(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Postavke'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: AppSpacing.tabBarHeight,
      padding: EdgeInsets.only(bottom: bottomInset, top: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.hairline, width: 1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(child: _TabButton(spec: tabs[i], selected: i == currentIndex, onTap: () => onTap(i))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.spec, required this.selected, required this.onTap});

  final TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.orange : context.colors.mutedAlt;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? spec.activeIcon : spec.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            spec.label,
            style: context.typography.sans(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
