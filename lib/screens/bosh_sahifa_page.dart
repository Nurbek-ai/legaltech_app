import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../shared/user_profile.dart';
import '../shared/profile_widgets.dart';

import 'services/alimony_claim_page.dart';
import 'services/bolaning_yashash_joyi_page.dart';
import 'services/nikohdan_ajrashish_page.dart';

class BoshSahifaPage extends StatefulWidget {
  const BoshSahifaPage({super.key});

  @override
  State<BoshSahifaPage> createState() => _BoshSahifaPageState();
}

class _BoshSahifaPageState extends State<BoshSahifaPage> {
  final _searchController = TextEditingController();

  static const _services = <_ServiceCardData>[
    _ServiceCardData(
      title: 'Sudga ariza yozish',
      caption: 'Sudga murojaat uchun ariza tayyorlash',
      artwork: 'assets/service_artwork/court_filing.png',
      colors: [Color(0xFF405EA8), Color(0xFF263967)],
      glow: Color(0xFF8EA7FF),
    ),
    _ServiceCardData(
      title: 'Konsultatsiya',
      caption: 'Masalangiz bo\'yicha yuridik maslahat',
      artwork: 'assets/service_artwork/consultation.png',
      colors: [Color(0xFF876B3E), Color(0xFF51402E)],
      glow: Color(0xFFFFD18B),
    ),
    _ServiceCardData(
      title: 'Advokat yollash',
      caption: 'Sizga mos advokatni topish',
      artwork: 'assets/service_artwork/lawyer.png',
      colors: [Color(0xFF634D9C), Color(0xFF3E326D)],
      glow: Color(0xFFDCC8FF),
    ),
    _ServiceCardData(
      title: 'Bolaga aliment undirish',
      caption: 'Farzandingiz uchun aliment talab qilish',
      artwork: 'assets/service_artwork/child_support.png',
      colors: [Color(0xFF854463), Color(0xFF552F4C)],
      glow: Color(0xFFFFB4C4),
    ),
    _ServiceCardData(
      title: 'Ona ta\'minoti uchun aliment undirish',
      caption: 'Ona ta\'minoti uchun huquqiy yordam',
      artwork: 'assets/service_artwork/mother_support.png',
      colors: [Color(0xFF327D79), Color(0xFF24545A)],
      glow: Color(0xFF9DE9D9),
    ),
    _ServiceCardData(
      title: 'Bolaning yashash joyini belgilash',
      caption: 'Bola yashash joyini rasmiy belgilash',
      artwork: 'assets/service_artwork/child_residence.png',
      colors: [Color(0xFF386D8D), Color(0xFF294A6A)],
      glow: Color(0xFFA9DFFF),
    ),
    _ServiceCardData(
      title: 'Bola bilan ko\'rishish tartibini belgilash',
      caption: 'Ko\'rishish tartibini huquqiy belgilash',
      artwork: 'assets/service_artwork/visitation.png',
      colors: [Color(0xFF76538A), Color(0xFF4D3A68)],
      glow: Color(0xFFD9B8FF),
    ),
    _ServiceCardData(
      title: 'Nikohdan ajrashish',
      caption: 'Ajrashish arizasini tayyorlash',
      artwork: 'assets/service_artwork/divorce.png',
      colors: [Color(0xFF8A6541), Color(0xFF583F34)],
      glow: Color(0xFFFFD09B),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildBrandHeader()),
        ),
        // ── Mini profile card ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildMiniProfileCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSectionHeading()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 122),
          sliver: visibleServices.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = visibleServices[index];
                      return _LiquidServiceCard(
                        data: service,
                        onTap: () {
                          if (service.title == "Bolaga aliment undirish") {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AlimonyClaimPage(), 
                              ),
                            );
                            return;
                          }

                          
                          if (service.title == "Bolaning yashash joyini belgilash") {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChildLivingPlacePage(), 
                              ),
                            );
                            return;
                          }

                          if (service.title == "Nikohdan ajrashish") {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DivorceClaimPage(), 
                              ),
                            );
                            return;
                          }

                          _showServiceMessage(service);
                        },
                      );
                    },
                    childCount: visibleServices.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 145,
                  ),
                ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mini profile card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMiniProfileCard() {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        return _MiniProfileCard(profile: profile);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rest of the page (unchanged logic)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7599F7).withValues(alpha: 0.18),
                blurRadius: 16,
              ),
            ],
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'YAN360',
              style: TextStyle(
                color: Color(0xFFF4F7FF),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.55,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'YURIDIK XIZMATLAR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.47),
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                height: 1,
              ),
            ),
          ],
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Bildirishnomalar',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.075),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8FB4FF),
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

  Widget _buildSectionHeading() {
    return Row(
      children: [
        const Text(
          'Kerakli xizmatni tanlang',
          style: TextStyle(
            color: Color(0xFFF6F8FF),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
            height: 1.1,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF8EACF8).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF9FB7F7).withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            '08 XIZMAT',
            style: TextStyle(
              color: const Color(0xFFC7D5FF).withValues(alpha: 0.88),
              fontSize: 7.4,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.75,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return SizedBox(
      height: 46,
      child: CupertinoTextField(
        controller: _searchController,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Color(0xFFF2F5FA),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        placeholder: 'Xizmatni izlang',
        placeholderStyle: const TextStyle(
          color: Color(0xFF8793A3),
          fontSize: 12,
        ),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 3, right: 9),
          child: Icon(
            CupertinoIcons.search,
            color: Color(0xFF9AA9BC),
            size: 17,
          ),
        ),
        suffix: _searchController.text.isEmpty
            ? null
            : GestureDetector(
                onTap: _searchController.clear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 2),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Color(0xFF8793A3),
                    size: 16,
                  ),
                ),
              ),
        decoration: BoxDecoration(
          color: const Color(0xFF273546).withValues(alpha: 0.91),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        cursorColor: const Color(0xFFADC4FF),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 31),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF6D8FD7).withValues(alpha: 0.13),
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
            "Qidiruv so'zini o'zgartirib ko'ring.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.49),
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
        content: Text('${service.title} — tez orada'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          98 + MediaQuery.of(context).padding.bottom,
        ),
        backgroundColor: const Color(0xFF2A3D58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mini Profile Card
// ═══════════════════════════════════════════════════════════════════════════

class _MiniProfileCard extends StatelessWidget {
  final UserProfileData profile;

  const _MiniProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C3356).withValues(alpha: 0.92),
                const Color(0xFF111E35).withValues(alpha: 0.97),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.13),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F44).withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle top-left glow
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 110,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4A7CF8).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Subtle bottom-right glow
              Positioned(
                bottom: -25,
                right: -20,
                child: Container(
                  width: 90,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6DD5C0).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Top shine line
              Positioned(
                top: 0,
                left: 30,
                right: 30,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content: [left stats] — [avatar] — [right stats]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Left stat ──────────────────────────────────────────
                    Expanded(
                      child: _MiniStatColumn(
                        value: profile.activeApplications.toString(),
                        label: 'Arizalar',
                        accent: const Color(0xFF83AAFF),
                        icon: CupertinoIcons.doc_text_fill,
                      ),
                    ),
                    // ── Center: avatar ─────────────────────────────────────
                    _MiniAvatarBubble(profile: profile),
                    // ── Right stat ─────────────────────────────────────────
                    Expanded(
                      child: _MiniStatColumn(
                        value: profile.completionPercent,
                        label: 'Profil',
                        accent: const Color(0xFF74DDB0),
                        icon: CupertinoIcons.checkmark_seal_fill,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big circular avatar in the centre of the mini card.
class _MiniAvatarBubble extends StatelessWidget {
  final UserProfileData profile;

  const _MiniAvatarBubble({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A6ADE), Color(0xFF1A3D8A)],
          ),
          border: Border.all(
            color: const Color(0xFF6A9EFF).withValues(alpha: 0.55),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3060D0).withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: buildAvatarContent(profile),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    if (profile.avatarFile == null) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) =>
            FullScreenPhotoPage(file: profile.avatarFile!),
      ),
    );
  }
}

/// Left or right statistic column inside the mini card.
class _MiniStatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final IconData icon;
  final bool alignRight;

  const _MiniStatColumn({
    required this.value,
    required this.label,
    required this.accent,
    required this.icon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxis =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxis,
      children: [
        Icon(icon, color: accent, size: 13),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.52),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Service card (unchanged)
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceCardData {
  final String title;
  final String caption;
  final String artwork;
  final List<Color> colors;
  final Color glow;

  const _ServiceCardData({
    required this.title,
    required this.caption,
    required this.artwork,
    required this.colors,
    required this.glow,
  });
}

class _LiquidServiceCard extends StatefulWidget {
  final _ServiceCardData data;
  final VoidCallback onTap;

  const _LiquidServiceCard({required this.data, required this.onTap});

  @override
  State<_LiquidServiceCard> createState() => _LiquidServiceCardState();
}

class _LiquidServiceCardState extends State<_LiquidServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label: data.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: const Duration(milliseconds: 130),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: data.colors.last.withValues(alpha: 0.34),
                  blurRadius: 17,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(11, 8, 10, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        data.colors.first.withValues(alpha: 0.95),
                        Color.lerp(data.colors.first, data.colors.last, 0.48)!
                            .withValues(alpha: 0.96),
                        data.colors.last.withValues(alpha: 0.99),
                      ],
                      stops: const [0, 0.52, 1],
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                      width: 1.1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -55,
                        left: -49,
                        child: Container(
                          width: 125,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                data.glow.withValues(alpha: 0.30),
                                data.glow.withValues(alpha: 0.07),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.52, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -37,
                        bottom: -53,
                        child: Container(
                          width: 112,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.14),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.34),
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
                              Image.asset(
                                data.artwork,
                                width: 91,
                                height: 69,
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                cacheWidth: 300,
                              ),
                              const Spacer(),
                              Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.arrow_up_right,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFAFBFF),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w800,
                              height: 1.06,
                              letterSpacing: -0.08,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 7.2,
                              height: 1.05,
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
      ),
    );
  }
}
