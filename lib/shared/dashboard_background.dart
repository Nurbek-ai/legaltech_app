import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06152D),
              Color(0xFF040D1E),
              Color(0xFF020712),
            ],
            stops: [0.0, 0.50, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient cyan-azure glow in upper-right behind the flying swallow
            Positioned(
              top: -90,
              right: -60,
              child: Container(
                width: 340,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C8FF).withValues(alpha: 0.18),
                      const Color(0xFF0066FF).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Soft sapphire depth glow on middle-left
            Positioned(
              top: 240,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1A6BFF).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle bottom-right liquid-blue glow
            Positioned(
              bottom: -140,
              right: -90,
              child: Container(
                width: 320,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00B4FF).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}