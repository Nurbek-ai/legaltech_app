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
              Color(0xFF102C60),
              Color(0xFF163A7A),
              Color(0xFF123168),
              Color(0xFF0D234F),
            ],
            stops: [0.0, 0.36, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Bright sky-cyan bloom in upper-right behind the flying swallow
            Positioned(
              top: -80,
              right: -50,
              child: Container(
                width: 360,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38B6FF).withValues(alpha: 0.32),
                      const Color(0xFF2B68E0).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Soft pearl-cobalt glow on upper-left behind the firm logo & cards
            Positioned(
              top: 160,
              left: -100,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4E86F0).withValues(alpha: 0.24),
                      const Color(0xFF2855B8).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Luminous azure-ice glow in the lower-right behind service cards
            Positioned(
              bottom: -110,
              right: -70,
              child: Container(
                width: 360,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38A8FF).withValues(alpha: 0.24),
                      const Color(0xFF1E56C2).withValues(alpha: 0.08),
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