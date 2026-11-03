import 'package:flutter/material.dart';

class DashboardNavData {
  final IconData icon;
  final String label;

  const DashboardNavData(this.icon, this.label);
}

class DashboardNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DashboardNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const crispWhite = Color(0xFFFFFFFF);
    const inactiveIce = Color(0xFFD0E2FF);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.34),
                      const Color(0xFF5A88D6).withValues(alpha: 0.42),
                      const Color(0xFF28509C).withValues(alpha: 0.58),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.78),
                    width: 1.25,
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF66B2FF).withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? crispWhite
                    : inactiveIce.withValues(alpha: 0.78),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? crispWhite
                      : inactiveIce.withValues(alpha: 0.82),
                  fontSize: 10.0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}