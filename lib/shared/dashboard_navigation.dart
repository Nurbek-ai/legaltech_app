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
  final Color accentColor;
  final VoidCallback onTap;

  const DashboardNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.accentColor = const Color(0xFF7CE7FF),
  });

  @override
  Widget build(BuildContext context) {
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
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFF8AB4FA).withValues(alpha: 0.42),
                      const Color(0xFF4A78D0).withValues(alpha: 0.34),
                      const Color(0xFF234794).withValues(alpha: 0.52),
                    ],
                  )
                : null,
            border: selected
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.62),
                    width: 1.15,
                  )
                : null,
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 20.5,
                    color: selected
                        ? Colors.white
                        : const Color(0xFFDCEBFF).withValues(alpha: 0.62),
                  ),
                  const SizedBox(height: 4.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFDCEBFF).withValues(alpha: 0.65),
                        fontSize: 10.2,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              if (badge != null && badge!.isNotEmpty)
                Positioned(
                  top: 5,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Color(0xFF071633),
                        fontSize: 8.2,
                        fontWeight: FontWeight.w900,
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
    this.accentColor = const Color(0xFF7CE7FF),
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DashboardNavData>? items;
  final Color accentColor;

  static const List<DashboardNavData> defaultItems = <DashboardNavData>[
    DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
    DashboardNavData(CupertinoIcons.doc_on_doc_fill, 'Arizalarim'),
    DashboardNavData(CupertinoIcons.building_2_fill, 'Advokatxona'),
    DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? defaultItems;
    return RepaintBoundary(
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xFF6B94DE).withValues(alpha: 0.42),
              const Color(0xFF3962B0).withValues(alpha: 0.48),
              const Color(0xFF1A3875).withValues(alpha: 0.78),
              const Color(0xFF102757).withValues(alpha: 0.90),
            ],
            stops: const <double>[0.0, 0.35, 0.72, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFFDCEBFF).withValues(alpha: 0.42),
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF06122E).withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 18,
              spreadRadius: -2,
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
                accentColor: accentColor,
                onTap: () => onSelected(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}