import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardNavData {
  final IconData icon;
  final String label;
  final String? badge;

  const DashboardNavData(
    this.icon,
    this.label, {
    this.badge,
  });
}

class DashboardNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const DashboardNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.activeColor = const Color(0xFF1677D2),
  });

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF102B57);
    const mutedNavy = Color(0xFF5A7196);
    const successGreen = Color(0xFF10C995);

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
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            // Single solid #1677D2 background for active item
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 20.5,
                    color: selected ? Colors.white : mutedNavy,
                  ),
                  const SizedBox(height: 3.5),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : navyColor,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              if (badge != null && badge!.isNotEmpty)
                Positioned(
                  top: -2,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.1),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.2,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.items,
    this.accentColor = const Color(0xFF1677D2),
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DashboardNavData>? items;
  final Color accentColor;

  /// Default 4-tab YAN360 navigation structure:
  /// 1. Bosh sahifa | 2. Arizalarim | 3. Advokatxona | 4. Profil
  static const List<DashboardNavData> defaultItems = <DashboardNavData>[
    DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
    DashboardNavData(CupertinoIcons.doc_text_fill, 'Arizalarim'),
    DashboardNavData(CupertinoIcons.building_2_fill, 'Advokatxona'),
    DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? defaultItems;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.96),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF102B57).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF1677D2).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List<Widget>.generate(
                navItems.length,
                (index) => Expanded(
                  child: DashboardNavItem(
                    icon: navItems[index].icon,
                    label: navItems[index].label,
                    badge: navItems[index].badge,
                    selected: selectedIndex == index,
                    activeColor: const Color(0xFF1677D2),
                    onTap: () => onSelected(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}