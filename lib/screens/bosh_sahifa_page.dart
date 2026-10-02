import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BoshSahifaPage extends StatefulWidget {
  const BoshSahifaPage({super.key});

  @override
  State<BoshSahifaPage> createState() => _BoshSahifaPageState();
}

class _BoshSahifaPageState extends State<BoshSahifaPage> {
  final _searchController = TextEditingController();

  static const _services = <_ServiceCardData>[
    _ServiceCardData(
      title: 'Sudga ariza\nyozish',
      caption: 'Sudga murojaat uchun ariza tayyorlash',
      icon: CupertinoIcons.doc_text_search,
      accentIcon: CupertinoIcons.checkmark,
      colors: [Color(0xFF405EA8), Color(0xFF263967)],
      iconColor: Color(0xFFC1C9FF),
    ),
    _ServiceCardData(
      title: 'Konsultatsiya',
      caption: 'Masalangiz bo‘yicha yuridik maslahat',
      icon: CupertinoIcons.person_2,
      accentIcon: CupertinoIcons.chat_bubble,
      colors: [Color(0xFF876B3E), Color(0xFF51402E)],
      iconColor: Color(0xFFFFD18B),
    ),
    _ServiceCardData(
      title: 'Advokat\nyollash',
      caption: 'Sizga mos advokatni topish',
      icon: CupertinoIcons.briefcase,
      accentIcon: CupertinoIcons.checkmark,
      colors: [Color(0xFF634D9C), Color(0xFF3E326D)],
      iconColor: Color(0xFFDCC8FF),
    ),
    _ServiceCardData(
      title: 'Bolaga aliment\nundirish',
      caption: 'Farzandingiz uchun aliment talab qilish',
      icon: CupertinoIcons.heart_fill,
      accentIcon: CupertinoIcons.person_fill,
      colors: [Color(0xFF854463), Color(0xFF552F4C)],
      iconColor: Color(0xFFFFB4C4),
    ),
    _ServiceCardData(
      title: 'Ona ta’minoti uchun\naliment undirish',
      caption: 'Ona ta’minoti uchun huquqiy yordam',
      icon: CupertinoIcons.heart,
      accentIcon: CupertinoIcons.person,
      colors: [Color(0xFF327D79), Color(0xFF24545A)],
      iconColor: Color(0xFF9DE9D9),
    ),
    _ServiceCardData(
      title: 'Bolaning yashash\njoyini belgilash',
      caption: 'Bola yashash joyini rasmiy belgilash',
      icon: CupertinoIcons.house_fill,
      accentIcon: CupertinoIcons.location,
      colors: [Color(0xFF386D8D), Color(0xFF294A6A)],
      iconColor: Color(0xFFA9DFFF),
    ),
    _ServiceCardData(
      title: 'Bola bilan ko‘rishish\ntartibini belgilash',
      caption: 'Ko‘rishish tartibini huquqiy belgilash',
      icon: CupertinoIcons.person_2,
      accentIcon: CupertinoIcons.heart_fill,
      colors: [Color(0xFF76538A), Color(0xFF4D3A68)],
      iconColor: Color(0xFFD9B8FF),
    ),
    _ServiceCardData(
      title: 'Nikohdan\najrashish',
      caption: 'Ajrashish arizasini tayyorlash',
      icon: CupertinoIcons.doc_text,
      accentIcon: CupertinoIcons.checkmark,
      colors: [Color(0xFF8A6541), Color(0xFF583F34)],
      iconColor: Color(0xFFFFD09B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<_ServiceCardData> get _visibleServices {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _services;

    return _services
        .where(
          (service) =>
              service.title.toLowerCase().contains(query) ||
              service.caption.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleServices = _visibleServices;

    return CustomScrollView(
      key: const ValueKey('home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildTopBar()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 29, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildGreeting()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 122),
          sliver: visibleServices.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = visibleServices[index];
                      return _LiquidServiceCard(
                        data: service,
                        onTap: () => _showServiceMessage(service),
                      );
                    },
                    childCount: visibleServices.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 176,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Text(
          'YAN360',
          style: TextStyle(
            color: Color(0xFFF3F6FF),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Bildirishnomalar',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.075),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 19,
                  color: Colors.white.withOpacity(0.82),
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF7D7D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xush\nkelibsiz',
          style: TextStyle(
            color: Color(0xFFF5F3F0),
            fontFamily: 'serif',
            fontSize: 33,
            fontWeight: FontWeight.w400,
            height: 0.98,
            letterSpacing: -0.9,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return CupertinoTextField(
      controller: _searchController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: Color(0xFFF2F5FA),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      placeholder: 'Xizmatni izlang',
      placeholderStyle: const TextStyle(
        color: Color(0xFF8793A3),
        fontSize: 14,
      ),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 16, right: 11),
        child: Icon(
          CupertinoIcons.search,
          color: Color(0xFF8A98AA),
          size: 18,
        ),
      ),
      suffix: _searchController.text.isEmpty
          ? null
          : GestureDetector(
              onTap: _searchController.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Color(0xFF738197),
                  size: 17,
                ),
              ),
            ),
      decoration: BoxDecoration(
        color: const Color(0xFF273546).withOpacity(0.88),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.105),
        ),
      ),
      cursorColor: const Color(0xFFADC4FF),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 31),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF6D8FD7).withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.search,
              color: Color(0xFF9DBBFF),
              size: 25,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Xizmat topilmadi',
            style: TextStyle(
              color: Color(0xFFF0F4FB),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Qidiruv so‘zini o‘zgartirib ko‘ring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.49),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _showServiceMessage(_ServiceCardData service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.title.replaceAll('\n', ' ')} — tez orada'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          98 + MediaQuery.of(context).padding.bottom,
        ),
        backgroundColor: const Color(0xFF2A3D58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ServiceCardData {
  final String title;
  final String caption;
  final IconData icon;
  final IconData accentIcon;
  final List<Color> colors;
  final Color iconColor;

  const _ServiceCardData({
    required this.title,
    required this.caption,
    required this.icon,
    required this.accentIcon,
    required this.colors,
    required this.iconColor,
  });
}

class _LiquidServiceCard extends StatefulWidget {
  final _ServiceCardData data;
  final VoidCallback onTap;

  const _LiquidServiceCard({
    required this.data,
    required this.onTap,
  });

  @override
  State<_LiquidServiceCard> createState() => _LiquidServiceCardState();
}

class _LiquidServiceCardState extends State<_LiquidServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Semantics(
      button: true,
      label: data.title.replaceAll('\n', ' '),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.colors.first.withOpacity(0.90),
                    Color.lerp(data.colors.first, data.colors.last, 0.52)!
                        .withOpacity(0.94),
                    data.colors.last.withOpacity(0.97),
                  ],
                  stops: const [0, 0.48, 1],
                ),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1.15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.colors.last.withOpacity(0.32),
                    blurRadius: 19,
                    offset: const Offset(0, 9),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -59,
                      left: -48,
                      child: Container(
                        width: 150,
                        height: 125,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              data.iconColor.withOpacity(0.30),
                              data.iconColor.withOpacity(0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -48,
                      bottom: -62,
                      child: Container(
                        width: 142,
                        height: 126,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 25,
                      right: 25,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LiquidServiceArtwork(
                              icon: data.icon,
                              accentIcon: data.accentIcon,
                              color: data.iconColor,
                            ),
                            const Spacer(),
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.arrow_up_right,
                                size: 13,
                                color: Colors.white.withOpacity(0.76),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          data.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF7F9FF),
                            fontSize: 13.2,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: -0.15,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 8.8,
                            height: 1.16,
                            letterSpacing: 0.02,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidServiceArtwork extends StatelessWidget {
  final IconData icon;
  final IconData accentIcon;
  final Color color;

  const _LiquidServiceArtwork({
    required this.icon,
    required this.accentIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 91,
      height: 75,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 9,
            top: 4,
            child: Container(
              width: 63,
              height: 63,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.35),
                    color.withOpacity(0.09),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 11,
            top: 11,
            child: Transform.rotate(
              angle: -0.13,
              child: Container(
                width: 48,
                height: 51,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.29),
                      color.withOpacity(0.25),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.44),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.42),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 5,
                      left: 7,
                      right: 7,
                      child: Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.40),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 27,
                      color: Colors.white.withOpacity(0.95),
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.9),
                          blurRadius: 11,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 49,
            top: 34,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 31,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(color, Colors.white, 0.48)!,
                      color.withOpacity(0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.58),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  accentIcon,
                  size: 17,
                  color: const Color(0xFF172439).withOpacity(0.88),
                ),
              ),
            ),
          ),
          Positioned(
            left: 1,
            top: 8,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.83),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.95),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
