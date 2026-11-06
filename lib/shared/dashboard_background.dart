import 'package:flutter/material.dart';

/// Primary YAN360 application background surface.
/// Uses the exact required #FEFEFA (RGB: 254, 254, 250) base canvas
/// with subtle #EAF5FF light-blue atmospheric depth in selected corners.
class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  static const Color primaryBackground = Color(0xFFFEFEFA);
  static const Color lightBlueAtmosphere = Color(0xFFEAF5FF);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ColoredBox(
        color: primaryBackground,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Subtle top-right light-blue atmospheric glow behind the swallow
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        lightBlueAtmosphere.withValues(alpha: 0.85),
                        lightBlueAtmosphere.withValues(alpha: 0.25),
                        primaryBackground.withValues(alpha: 0.0),
                      ],
                      stops: const <double>[0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Subtle top-left soft ambient light behind the shield emblem
            Positioned(
              top: 30,
              left: -80,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        lightBlueAtmosphere.withValues(alpha: 0.60),
                        primaryBackground.withValues(alpha: 0.0),
                      ],
                    ),
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