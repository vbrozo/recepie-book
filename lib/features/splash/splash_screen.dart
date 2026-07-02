import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_typography.dart';

/// Brand moment on launch — auto-advances to Home. No user input.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(color: context.colors.orangeSoft, borderRadius: BorderRadius.circular(34)),
              child: Icon(Icons.ramen_dining_outlined, size: 48, color: context.colors.orange),
            ),
            const SizedBox(height: 20),
            Text('Kuharica', style: context.typography.serif(fontSize: 44)),
            const SizedBox(height: 8),
            Text('Tvoja osobna zbirka recepata', style: context.typography.sans(fontSize: 16, color: context.colors.mutedAlt)),
            const SizedBox(height: 64),
            _PulsingDots(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((controller.value - i * 0.2) % 1.0 + 1.0) % 1.0;
            final pulse = (t < 0.5) ? t * 2 : (1 - t) * 2;
            final scale = 0.85 + 0.15 * pulse;
            final opacity = 0.25 + 0.75 * pulse;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: context.colors.orange, shape: BoxShape.circle),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
