import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF101E30),
              Color(0xFF0B1726),
              Color(0xFF09121D),
            ],
            stops: [0, 0.48, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -100,
              child: Container(
                width: 300,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF557AC2).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -100,
              child: Container(
                width: 320,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF355B9C).withValues(alpha: 0.10),
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

