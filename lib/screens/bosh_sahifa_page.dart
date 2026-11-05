import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/alimony_claim_document_service.dart';
import '../services/family_claim_document_service.dart';
import '../shared/profile_widgets.dart';
import '../shared/user_profile.dart';
import 'hujjatlar_page.dart';
import 'profil_page.dart';
import 'services/advokat_yollash_page.dart';
import 'services/alimony_claim_page.dart';
import 'services/family_claim_page.dart';
import 'services/lawyer_draft_request_page.dart';
import 'tarix_page.dart';

/// Frosted Pearl-Blue & Royal Cobalt Liquid Glass tokens (GPU-optimized).
class _HomeLiquidTheme {
  static const Color frostPearlLight = Color(0xFF7FA4E8);
  static const Color frostPearlBlue = Color(0xFF537BC4);
  static const Color frostMidCobalt = Color(0xFF2B5096);
  static const Color frostDeepCobalt = Color(0xFF19356E);

  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color luminousAzure = Color(0xFF2B88FF);
  static const Color iceBlue = Color(0xFFA6D8FF);
  static const Color crispWhite = Color(0xFFFFFFFF);
  static const Color softIceText = Color(0xFFD6E6FF);

  // Dynamic readiness status colors (<50% Red, 50-80% Yellow, 80%+ Green)
  static const Color statusRed = Color(0xFFFF453A);
  static const Color statusRedLight = Color(0xFFFF8A80);
  static const Color statusYellow = Color(0xFFFFD60A);
  static const Color statusYellowLight = Color(0xFFFFE57F);
  static const Color statusGreen = Color(0xFF00E676);
  static const Color statusGreenLight = Color(0xFF80FFBD);

  static Color readinessPrimaryColor(int percent) {
    if (percent < 50) return statusRed;
    if (percent < 80) return statusYellow;
    return statusGreen;
  }

  static Color readinessLightColor(int percent) {
    if (percent < 50) return statusRedLight;
    if (percent < 80) return statusYellowLight;
    return statusGreenLight;
  }

  static String readinessStatusText(int percent) {
    if (percent < 50) return 'To‘ldiring';
    if (percent < 80) return 'Yaxshi';
    return 'Mukammal';
  }
}

class BoshSahifaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const BoshSahifaPage({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<BoshSahifaPage> createState() => _BoshSahifaPageState();
}

class _BoshSahifaPageState extends State<BoshSahifaPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  late final AnimationController _entranceController;

  /// All 8 legal services mapped to the custom 3D artwork in `assets/service_artwork/`.
  static const _services = <_ServiceCardData>[
    _ServiceCardData(
      title: 'Advokatga ariza yozdirish',
      caption: 'Yuridik ariza va hujjatlarni tayyorlash',
      artworkCandidates: [
        'assets/service_artwork/arizalogo.png',
        'assets/service_artwork/arizalogo.jpg',
        'assets/service_artwork/arizalogo.jpeg',
        'assets/service_artwork/arizalogo',
        'assets/service_artwork/court_filing.png',
      ],
      fallbackIcon: CupertinoIcons.doc_text_fill,
    ),
    _ServiceCardData(
      title: 'Konsultatsiya',
      caption: 'Malakali yuridik maslahat olish',
      artworkCandidates: [
        'assets/service_artwork/consult.png',
        'assets/service_artwork/consult.jpg',
        'assets/service_artwork/consult.jpeg',
        'assets/service_artwork/consult',
        'assets/service_artwork/consultation.png',
      ],
      fallbackIcon: CupertinoIcons.chat_bubble_2_fill,
    ),
    _ServiceCardData(
      title: 'Advokat yollash',
      caption: 'Sizga mos advokatni tanlash',
      artworkCandidates: [
        'assets/service_artwork/advocatebooking.png',
        'assets/service_artwork/advocatebooking.jpg',
        'assets/service_artwork/advocatebooking.jpeg',
        'assets/service_artwork/advocatebooking',
        'assets/service_artwork/lawyer.png',
      ],
      fallbackIcon: CupertinoIcons.briefcase_fill,
    ),
    _ServiceCardData(
      title: 'Bolaga aliment undirish',
      caption: 'Farzandingiz uchun aliment talab qilish',
      artworkCandidates: [
        'assets/service_artwork/alimony.png',
        'assets/service_artwork/alimony.jpg',
        'assets/service_artwork/alimony.jpeg',
        'assets/service_artwork/alimony',
        'assets/service_artwork/child_support.png',
      ],
      fallbackIcon: CupertinoIcons.money_dollar_circle_fill,
    ),
    _ServiceCardData(
      title: "Ona ta'minoti uchun aliment undirish",
      caption: "Ona ta'minoti uchun huquqiy yordam",
      artworkCandidates: [
        'assets/service_artwork/onataminoti.png',
        'assets/service_artwork/onataminoti.jpg',
        'assets/service_artwork/onataminoti.jpeg',
        'assets/service_artwork/onataminoti',
        'assets/service_artwork/mother_support.png',
      ],
      fallbackIcon: CupertinoIcons.heart_circle_fill,
    ),
    _ServiceCardData(
      title: 'Bolaning yashash joyini belgilash',
      caption: 'Bola yashash joyini rasmiy belgilash',
      artworkCandidates: [
        'assets/service_artwork/yashashjoyi.png',
        'assets/service_artwork/yashashjoyi.jpg',
        'assets/service_artwork/yashashjoyi.jpeg',
        'assets/service_artwork/yashashjoyi',
        'assets/service_artwork/child_residence.png',
      ],
      fallbackIcon: CupertinoIcons.house_fill,
    ),
    _ServiceCardData(
      title: "Bola bilan ko'rishish tartibini belgilash",
      caption: 'Uchrashuv tartibini rasmiylashtirish',
      artworkCandidates: [
        'assets/service_artwork/korishish.png',
        'assets/service_artwork/korishish.jpg',
        'assets/service_artwork/korishish.jpeg',
        'assets/service_artwork/korishish',
        'assets/service_artwork/visitation.png',
      ],
      fallbackIcon: CupertinoIcons.calendar_badge_plus,
    ),
    _ServiceCardData(
      title: 'Nikohdan ajrashish',
      caption: 'Ajrashish va zarur hujjatlarni tayyorlash',
      artworkCandidates: [
        'assets/service_artwork/ajrim.png',
        'assets/service_artwork/ajrim.jpg',
        'assets/service_artwork/ajrim.jpeg',
        'assets/service_artwork/ajrim',
        'assets/service_artwork/divorce.png',
      ],
      fallbackIcon: CupertinoIcons.person_2_fill,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Runs once on page entrance instead of .repeat() so idle GPU usage is 0%
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _searchController.addListener(_handleSearchChanged);
    _searchFocusNode.addListener(_handleFocusChanged);
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
  }

  void _navigateOrPushTab(int tabIndex) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
      return;
    }
    final Widget destination = switch (tabIndex) {
      1 => const TarixPage(),
      2 => const HujjatlarPage(),
      3 => const ProfilPage(),
      _ => const BoshSahifaPage(),
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF0E2654),
          appBar: AppBar(
            backgroundColor: const Color(0xFF102C60),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: destination,
        ),
      ),
    );
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

  Future<void> _handleLawyerOrConsultSubmit(
    Map<String, dynamic> payload,
  ) async {
    final type = payload['type']?.toString() ?? '';
    if (type == 'book_consultation') {
      final date = payload['date']?.toString() ?? '';
      final time = payload['time']?.toString() ?? '';
      await ActivityHistoryRepository.instance.record(
        title: 'Jonli videokonsultatsiya band qilindi',
        description:
            'Bosh advokat Shohruh Jo‘rayev • Sana: $date, soat $time (20 daqiqa)',
        category: ActivityCategory.consultation,
        statusLabel: 'Band qilindi',
        metadata: <String, String>{
          'Xizmat': '20 daqiqalik jonli videokonsultatsiya',
          'Advokat': 'Shohruh Jo‘rayev (YAN Legal Firm)',
          'Sana': date,
          'Vaqt': '$time (Asia/Tashkent)',
          'Narxi': '99 000 so‘m',
        },
      );
    } else {
      final desc = payload['case_description']?.toString() ?? '';
      await ActivityHistoryRepository.instance.record(
        title: 'Sud himoyasi uchun advokat yollash so‘rovi',
        description: desc,
        category: ActivityCategory.lawyer,
        statusLabel: 'Ko‘rib chiqilmoqda',
        metadata: <String, String>{
          'Xizmat': 'Sud himoyasi va vakillik',
          'Advokat': 'Shohruh Jo‘rayev (YAN Legal Firm)',
          'Mijoz': userProfile.value.displayName,
          'Telefon': userProfile.value.phone,
          'Ish mazmuni': desc,
        },
      );
    }
    userProfile.value = userProfile.value.copyWith(
      activeApplications: userProfile.value.activeApplications + 1,
    );
  }

  Future<void> _handleLawyerDraftSubmit(Map<String, dynamic> payload) async {
    final categoryTitle =
        payload['category_title']?.toString() ?? 'Yuridik masala';
    final problem = payload['problem']?.toString() ?? '';
    final price = payload['base_price']?.toString() ?? '';
    final files = (payload['files'] as List<dynamic>? ?? const []).length;

    await ActivityHistoryRepository.instance.record(
      title: 'Advokatga ariza yozdirish: $categoryTitle',
      description: problem,
      category: ActivityCategory.lawyer,
      statusLabel: 'Yuristga yuborildi',
      metadata: <String, String>{
        'Yo‘nalish': categoryTitle,
        'Boshlang‘ich narx': '$price so‘m',
        'Ilova qilingan fayllar': '$files ta hujjat/rasm',
        'Mijoz': userProfile.value.displayName,
        'Muammo bayoni': problem,
      },
    );
    userProfile.value = userProfile.value.copyWith(
      activeApplications: userProfile.value.activeApplications + 1,
    );
  }

  void _handleServiceTap(_ServiceCardData service) {
    if (service.title == 'Bolaga aliment undirish') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AlimonyClaimPage(
            onSubmit: (payload) async {
              await AlimonyClaimDocumentService().create(payload);
            },
          ),
        ),
      );
      return;
    }

    if (service.title == 'Bolaning yashash joyini belgilash') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.childResidence,
          ),
        ),
      );
      return;
    }

    if (service.title == "Ona ta'minoti uchun aliment undirish") {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.motherSupport,
          ),
        ),
      );
      return;
    }

    if (service.title == "Bola bilan ko'rishish tartibini belgilash") {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.childVisitation,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Nikohdan ajrashish') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.divorce,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Advokatga ariza yozdirish') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LawyerDraftRequestPage(
            onSubmit: _handleLawyerDraftSubmit,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Konsultatsiya') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdvokatYollashPage(
            initialRepresentation: false,
            onSubmit: _handleLawyerOrConsultSubmit,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Advokat yollash') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdvokatYollashPage(
            initialRepresentation: true,
            onSubmit: _handleLawyerOrConsultSubmit,
          ),
        ),
      );
      return;
    }

    _showServiceMessage(service);
  }

  @override
  Widget build(BuildContext context) {
    final visibleServices = _visibleServices;

    return CustomScrollView(
      key: const ValueKey('home'),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 600,
      slivers: [
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: _buildHeroHeaderWithSwallow(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildSectionHeading()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 128),
          sliver: visibleServices.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = visibleServices[index];
                      return RepaintBoundary(
                        child: _LiquidServiceCard(
                          data: service,
                          onTap: () => _handleServiceTap(service),
                        ),
                      );
                    },
                    childCount: visibleServices.length,
                    addRepaintBoundaries: false,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 178,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderWithSwallow() {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        return ValueListenableBuilder<List<GeneratedDocument>>(
          valueListenable: GeneratedDocumentRepository.instance.documents,
          builder: (context, docs, _) {
            return ValueListenableBuilder<List<ActivityEntry>>(
              valueListenable: ActivityHistoryRepository.instance.entries,
              builder: (context, activities, _) {
                final savedDocsCount = docs.length;
                final totalArizalar =
                    savedDocsCount + profile.activeApplications;
                final consultAndLawyerCount = activities
                    .where(
                      (e) =>
                          e.category == ActivityCategory.consultation ||
                          e.category == ActivityCategory.lawyer,
                    )
                    .length;

                return SizedBox(
                  height: 266,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Static GPU-cached flight trajectory & sparkles
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 156,
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _SwallowFlightSparklePainter(),
                            ),
                          ),
                        ),
                      ),

                      // 2. Top Brand Row
                      Positioned(
                        top: 4,
                        left: 16,
                        right: 18,
                        child: _buildTopBrandRow(activities.length),
                      ),

                      // 3. Interactive Frosted Pearl-Blue Command Banner
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 0,
                        child: RepaintBoundary(
                          child: _InteractiveLiquidMetricsBanner(
                            profile: profile,
                            totalArizalarCount: totalArizalar,
                            savedDocsCount: savedDocsCount,
                            consultAndLawyerCount: consultAndLawyerCount,
                            totalActivitiesCount: activities.length,
                            onTapDocuments: () => _showDocumentsQuickSheet(
                              context,
                              docs: docs,
                              activeApplications: profile.activeApplications,
                            ),
                            onTapProfileAvatar: () => _showProfileQuickSheet(
                              context,
                              profile: profile,
                            ),
                            onTapReadinessRing: () => _showReadinessQuickSheet(
                              context,
                              profile: profile,
                            ),
                            onNavigateToTab: _navigateOrPushTab,
                          ),
                        ),
                      ),

                      // 4. Soaring Swallow (smooth 1-time entrance, then 0% GPU idle)
                      Positioned(
                        top: -8,
                        right: 24,
                        width: 192,
                        height: 136,
                        child: IgnorePointer(
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _entranceController,
                              curve: Curves.easeOut,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 146,
                                  height: 106,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _HomeLiquidTheme.electricCyan
                                            .withValues(alpha: 0.34),
                                        _HomeLiquidTheme.luminousAzure
                                            .withValues(alpha: 0.12),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const _ResilientAssetImage(
                                  candidates: [
                                    'assets/service_artwork/yanswallow.png',
                                    'assets/service_artwork/yanswallow',
                                    'assets/yanswallow.png',
                                    'assets/yanswallow',
                                    'assets/service_artwork/yanswallow.jpg',
                                    'assets/yanswallow.jpg',
                                  ],
                                  fit: BoxFit.contain,
                                  cacheWidth: 450,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBrandRow(int totalActivitiesCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Standalone larger firm logo (80x80) with downsampled cacheWidth
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _HomeLiquidTheme.electricCyan.withValues(
                        alpha: 0.34,
                      ),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
                cacheWidth: 220,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: _HomeLiquidTheme.electricCyan,
                  size: 46,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'YAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: '360',
                      style: TextStyle(
                        color: _HomeLiquidTheme.electricCyan,
                        fontSize: 23.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: _HomeLiquidTheme.electricCyan.withValues(
                              alpha: 0.70,
                            ),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Yuridik xizmatlar platformasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _HomeLiquidTheme.softIceText.withValues(alpha: 0.94),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
        // Frosted Pearl-Blue Notification Bell (no offscreen BackdropFilter needed)
        Semantics(
          button: true,
          label: 'Bildirishnomalar va faoliyat tarixi',
          child: GestureDetector(
            onTap: () => _navigateOrPushTab(1),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _HomeLiquidTheme.frostPearlLight.withValues(alpha: 0.58),
                    _HomeLiquidTheme.frostPearlBlue.withValues(alpha: 0.62),
                    _HomeLiquidTheme.frostDeepCobalt.withValues(alpha: 0.85),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.74),
                  width: 1.2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.bell,
                    size: 19,
                    color: _HomeLiquidTheme.crispWhite,
                  ),
                  if (totalActivitiesCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8.5,
                        height: 8.5,
                        decoration: const BoxDecoration(
                          color: _HomeLiquidTheme.electricCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDocumentsQuickSheet(
    BuildContext context, {
    required List<GeneratedDocument> docs,
    required int activeApplications,
  }) {
    final total = docs.length + activeApplications;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _LiquidModalSheet(
          title: 'Arizalar va hujjatlar ($total)',
          subtitle: 'Yaratilgan rasmiy DOCX arizalar va faol murojaatlar',
          accentColor: _HomeLiquidTheme.electricCyan,
          icon: CupertinoIcons.doc_text_fill,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SheetStatBox(
                    value: docs.length.toString(),
                    label: 'Tayyor DOCX hujjatlar',
                    color: _HomeLiquidTheme.electricCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetStatBox(
                    value: activeApplications.toString(),
                    label: 'Faol murojaatlar',
                    color: _HomeLiquidTheme.statusGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (docs.isNotEmpty) ...[
              Text(
                'So‘nggi yaratilgan hujjatlar:',
                style: TextStyle(
                  color: _HomeLiquidTheme.softIceText.withValues(alpha: 0.90),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...docs.take(3).map(
                (d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.doc_checkmark_fill,
                        color: _HomeLiquidTheme.electricCyan,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          d.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: _SheetActionButton(
                    label: 'Hujjatlar bo‘limi',
                    icon: CupertinoIcons.folder_fill,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _navigateOrPushTab(2);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetActionButton(
                    label: 'Faoliyat tarixi',
                    icon: CupertinoIcons.time_solid,
                    secondary: true,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _navigateOrPushTab(1);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showProfileQuickSheet(
    BuildContext context, {
    required UserProfileData profile,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _LiquidModalSheet(
          title: profile.displayName,
          subtitle: 'Mijoz ID: ${profile.clientId} • ${profile.role}',
          accentColor: _HomeLiquidTheme.electricCyan,
          icon: CupertinoIcons.person_crop_circle_fill,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (profile.avatarFile != null) {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          opaque: false,
                          pageBuilder: (_, _, _) =>
                              FullScreenPhotoPage(file: profile.avatarFile!),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2860B8), Color(0xFF14326B)],
                      ),
                      border: Border.all(
                        color: _HomeLiquidTheme.electricCyan,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: buildAvatarContent(profile, initialsSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.phone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _HomeLiquidTheme.softIceText.withValues(
                            alpha: 0.90,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SheetActionButton(
              label: 'Shaxsiy profilni boshqarish',
              icon: CupertinoIcons.person_fill,
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateOrPushTab(3);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReadinessQuickSheet(
    BuildContext context, {
    required UserProfileData profile,
  }) {
    final percent = (profile.profileCompletion * 100).round().clamp(0, 100);
    final ringColor = _HomeLiquidTheme.readinessPrimaryColor(percent);
    final statusLabel = _HomeLiquidTheme.readinessStatusText(percent);
    final missing = profile.missingProfileItems;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _LiquidModalSheet(
          title: 'Profil tayyorligi: $percent% ($statusLabel)',
          subtitle:
              '50% dan past — qizil, 50–80% — sariq, 80% va undan yuqori — yashil',
          accentColor: ringColor,
          icon: CupertinoIcons.chart_pie_fill,
          children: [
            if (missing.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _HomeLiquidTheme.statusGreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _HomeLiquidTheme.statusGreen.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: _HomeLiquidTheme.statusGreen,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Barcha yuridik ma’lumotlar to‘liq kiritilgan!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'To‘ldirilishi kerak bo‘lgan ma’lumotlar:',
                style: TextStyle(
                  color: _HomeLiquidTheme.softIceText.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...missing.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        color: ringColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _SheetActionButton(
              label: 'Profilni to‘ldirishga o‘tish',
              icon: CupertinoIcons.arrow_right_circle_fill,
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateOrPushTab(3);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeading() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Kerakli xizmatni tanlang',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _HomeLiquidTheme.crispWhite,
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _HomeLiquidTheme.frostPearlLight.withValues(alpha: 0.58),
                _HomeLiquidTheme.frostPearlBlue.withValues(alpha: 0.62),
                _HomeLiquidTheme.frostDeepCobalt.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1.15,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                CupertinoIcons.square_grid_2x2_fill,
                size: 13.5,
                color: _HomeLiquidTheme.electricCyan,
              ),
              SizedBox(width: 6),
              Text(
                '08 XIZMAT',
                style: TextStyle(
                  color: _HomeLiquidTheme.crispWhite,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hardware-accelerated Frosted Pearl-Blue Search Capsule (zero BackdropFilter lag).
  Widget _buildSearch() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _HomeLiquidTheme.frostPearlLight.withValues(
              alpha: _searchFocused ? 0.65 : 0.50,
            ),
            _HomeLiquidTheme.frostPearlBlue.withValues(
              alpha: _searchFocused ? 0.72 : 0.58,
            ),
            _HomeLiquidTheme.frostDeepCobalt.withValues(
              alpha: _searchFocused ? 0.90 : 0.82,
            ),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _searchFocused
              ? Colors.white.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.66),
          width: _searchFocused ? 1.4 : 1.15,
        ),
      ),
      child: CupertinoTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: _HomeLiquidTheme.crispWhite,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        placeholder: 'Xizmatni izlang...',
        placeholderStyle: TextStyle(
          color: _HomeLiquidTheme.softIceText.withValues(alpha: 0.82),
          fontSize: 13.2,
        ),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 16, right: 4),
          child: Icon(
            CupertinoIcons.search,
            color: Colors.white,
            size: 18,
          ),
        ),
        suffix: _searchController.text.isEmpty
            ? null
            : GestureDetector(
                onTap: _searchController.clear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 14),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 16,
                  ),
                ),
              ),
        decoration: const BoxDecoration(color: Colors.transparent),
        cursorColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 31),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _HomeLiquidTheme.frostPearlLight.withValues(alpha: 0.52),
            _HomeLiquidTheme.frostMidCobalt.withValues(alpha: 0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Xizmat topilmadi',
            style: TextStyle(
              color: _HomeLiquidTheme.crispWhite,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Qidiruv so'zini o'zgartirib ko'ring.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HomeLiquidTheme.softIceText.withValues(alpha: 0.85),
              fontSize: 12.2,
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
        backgroundColor: const Color(0xFF1E3E7A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Static, GPU-friendly flight trajectory & sparkles painter (zero MaskFilter.blur per frame).
class _SwallowFlightSparklePainter extends CustomPainter {
  const _SwallowFlightSparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mainPath = Path()
      ..moveTo(0, h * 0.64)
      ..cubicTo(
        w * 0.24,
        h * 0.76,
        w * 0.44,
        h * 0.34,
        w * 0.72,
        h * 0.46,
      )
      ..quadraticBezierTo(
        w * 0.88,
        h * 0.52,
        w,
        h * 0.34,
      );

    final secondaryPath = Path()
      ..moveTo(0, h * 0.76)
      ..cubicTo(
        w * 0.28,
        h * 0.56,
        w * 0.54,
        h * 0.72,
        w * 0.82,
        h * 0.52,
      )
      ..quadraticBezierTo(
        w * 0.92,
        h * 0.45,
        w,
        h * 0.52,
      );

    final shaderRect = Rect.fromLTWH(0, 0, w, h);

    // Soft wide stroke instead of expensive MaskFilter.blur
    final softRibbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.02),
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.22),
          _HomeLiquidTheme.iceBlue.withValues(alpha: 0.32),
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.38, 0.74, 1.0],
      ).createShader(shaderRect);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.70),
          Colors.white.withValues(alpha: 0.92),
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.32, 0.70, 1.0],
      ).createShader(shaderRect);

    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _HomeLiquidTheme.iceBlue.withValues(alpha: 0.42),
          _HomeLiquidTheme.electricCyan.withValues(alpha: 0.50),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.78, 1.0],
      ).createShader(shaderRect);

    canvas.drawPath(mainPath, softRibbonPaint);
    canvas.drawPath(secondaryPath, secondaryPaint);
    canvas.drawPath(mainPath, corePaint);

    const sparkles = <_SparkleSpec>[
      _SparkleSpec(0.22, 0.65, 3.2, true),
      _SparkleSpec(0.31, 0.56, 2.0, false),
      _SparkleSpec(0.42, 0.48, 3.8, true),
      _SparkleSpec(0.49, 0.58, 2.0, false),
      _SparkleSpec(0.55, 0.44, 4.4, true),
      _SparkleSpec(0.61, 0.52, 2.3, false),
      _SparkleSpec(0.66, 0.36, 5.0, true),
      _SparkleSpec(0.71, 0.22, 3.6, true),
      _SparkleSpec(0.76, 0.48, 2.2, false),
      _SparkleSpec(0.83, 0.28, 4.2, true),
      _SparkleSpec(0.88, 0.44, 2.8, true),
    ];

    final haloPaint = Paint()
      ..color = _HomeLiquidTheme.electricCyan.withValues(alpha: 0.26);
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);

    for (final s in sparkles) {
      final center = Offset(w * s.dx, h * s.dy);
      canvas.drawCircle(center, s.radius * 1.4, haloPaint);
      if (s.isStar) {
        _drawFourPointStar(canvas, center, s.radius * 1.4);
      } else {
        canvas.drawCircle(center, s.radius * 0.55, dotPaint);
      }
    }
  }

  void _drawFourPointStar(Canvas canvas, Offset c, double r) {
    final starPath = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant _SwallowFlightSparklePainter oldDelegate) =>
      false;
}

class _SparkleSpec {
  final double dx;
  final double dy;
  final double radius;
  final bool isStar;

  const _SparkleSpec(
    this.dx,
    this.dy,
    this.radius,
    this.isStar,
  );
}

/// Frosted Pearl-Blue & Silver-Rim Command Banner (GPU-optimized optical glass).
class _InteractiveLiquidMetricsBanner extends StatelessWidget {
  final UserProfileData profile;
  final int totalArizalarCount;
  final int savedDocsCount;
  final int consultAndLawyerCount;
  final int totalActivitiesCount;
  final VoidCallback onTapDocuments;
  final VoidCallback onTapProfileAvatar;
  final VoidCallback onTapReadinessRing;
  final ValueChanged<int> onNavigateToTab;

  const _InteractiveLiquidMetricsBanner({
    required this.profile,
    required this.totalArizalarCount,
    required this.savedDocsCount,
    required this.consultAndLawyerCount,
    required this.totalActivitiesCount,
    required this.onTapDocuments,
    required this.onTapProfileAvatar,
    required this.onTapReadinessRing,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final completionRatio = profile.profileCompletion.clamp(0.0, 1.0);
    final completionPercentInt = (completionRatio * 100).round().clamp(0, 100);
    final completionLabel = '$completionPercentInt%';
    final readinessColor = _HomeLiquidTheme.readinessPrimaryColor(
      completionPercentInt,
    );
    final readinessStatus = _HomeLiquidTheme.readinessStatusText(
      completionPercentInt,
    );

    final shortName = profile.displayName.trim().split(RegExp(r'\s+')).first;

    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _HomeLiquidTheme.frostPearlLight.withValues(alpha: 0.62),
            _HomeLiquidTheme.frostPearlBlue.withValues(alpha: 0.68),
            _HomeLiquidTheme.frostMidCobalt.withValues(alpha: 0.82),
            _HomeLiquidTheme.frostDeepCobalt.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.30, 0.70, 1.0],
        ),
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.74),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C94FF).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Soft top-left pearl frost sheen
            Positioned(
              top: -40,
              left: -30,
              child: Container(
                width: 180,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Top inner silver-white frost highlight
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.90),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom inner silver-ice highlight
            Positioned(
              bottom: 0,
              left: 30,
              right: 30,
              child: Container(
                height: 1.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              child: Column(
                children: [
                  // TOP TIER: 3 Primary Interactive Columns
                  Expanded(
                    child: Row(
                      children: [
                        // 1. Clickable Arizalar va hujjatlar
                        Expanded(
                          flex: 11,
                          child: _PressableStatRegion(
                            semanticLabel:
                                'Arizalar va hujjatlar: $totalArizalarCount ta. Ko‘rish uchun bosing',
                            onTap: onTapDocuments,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.34),
                                        _HomeLiquidTheme.frostMidCobalt
                                            .withValues(alpha: 0.62),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.doc_text_fill,
                                    color: _HomeLiquidTheme.electricCyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            totalArizalarCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 21.5,
                                              fontWeight: FontWeight.w900,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            CupertinoIcons.chevron_right,
                                            size: 11,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Arizalar va\nhujjatlar',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.94,
                                          ),
                                          fontSize: 10.2,
                                          fontWeight: FontWeight.w600,
                                          height: 1.14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        _buildVerticalDivider(),

                        // 2. Centerpiece User Profile Picture Avatar
                        Expanded(
                          flex: 9,
                          child: _PressableStatRegion(
                            semanticLabel:
                                'Foydalanuvchi profili: ${profile.displayName}. Ochish uchun bosing',
                            onTap: onTapProfileAvatar,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      padding: const EdgeInsets.all(2.3),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _HomeLiquidTheme.electricCyan,
                                            _HomeLiquidTheme.luminousAzure,
                                          ],
                                        ),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF16356C),
                                        ),
                                        child: ClipOval(
                                          child: buildAvatarContent(
                                            profile,
                                            initialsSize: 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -1,
                                      right: -1,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF15346B),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          color: _HomeLiquidTheme.electricCyan,
                                          size: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        shortName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.6,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 9.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        _buildVerticalDivider(),

                        // 3. Clickable Dynamic Color Circular Progress Ring
                        Expanded(
                          flex: 12,
                          child: _PressableStatRegion(
                            semanticLabel:
                                'Profil tayyorligi: $completionLabel ($readinessStatus). Batafsil ko‘rish uchun bosing',
                            onTap: onTapReadinessRing,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CustomPaint(
                                    painter: _DynamicProgressRingPainter(
                                      progress: completionRatio,
                                      percent: completionPercentInt,
                                    ),
                                    child: Center(
                                      child: Text(
                                        completionLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.2,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profil\ntayyorligi',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.94,
                                          ),
                                          fontSize: 10.2,
                                          fontWeight: FontWeight.w600,
                                          height: 1.14,
                                        ),
                                      ),
                                      const SizedBox(height: 3.5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: readinessColor.withValues(
                                            alpha: 0.24,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: readinessColor.withValues(
                                              alpha: 0.70,
                                            ),
                                            width: 0.9,
                                          ),
                                        ),
                                        child: Text(
                                          readinessStatus,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: readinessColor,
                                            fontSize: 8.6,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.36),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // BOTTOM TIER: 3 Frosted Pearl-Blue Dynamic Quick-Stat Pills
                  SizedBox(
                    height: 29,
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickDynamicStatPill(
                            icon: CupertinoIcons.doc_checkmark_fill,
                            label: 'DOCX: $savedDocsCount ta',
                            accentColor: _HomeLiquidTheme.electricCyan,
                            onTap: () => onNavigateToTab(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickDynamicStatPill(
                            icon: CupertinoIcons.videocam_fill,
                            label: 'Yurist: $consultAndLawyerCount ta',
                            accentColor: const Color(0xFF82C4FF),
                            onTap: () => onNavigateToTab(1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickDynamicStatPill(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            label: 'Tarix: $totalActivitiesCount ta',
                            accentColor: _HomeLiquidTheme.statusGreen,
                            onTap: () => onNavigateToTab(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.38),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DynamicProgressRingPainter extends CustomPainter {
  final double progress;
  final int percent;

  const _DynamicProgressRingPainter({
    required this.progress,
    required this.percent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 7) / 2;

    final primaryColor = _HomeLiquidTheme.readinessPrimaryColor(percent);
    final lightColor = _HomeLiquidTheme.readinessLightColor(percent);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.06, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft outer halo stroke (avoids expensive MaskFilter.blur)
    final haloPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, haloPaint);

    final arcPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lightColor,
          primaryColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _DynamicProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.percent != percent;
  }
}

class _PressableStatRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _PressableStatRegion({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<_PressableStatRegion> createState() => _PressableStatRegionState();
}

class _PressableStatRegionState extends State<_PressableStatRegion> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}

class _QuickDynamicStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickDynamicStatPill({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableStatRegion(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.28),
              _HomeLiquidTheme.frostMidCobalt.withValues(alpha: 0.62),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12.5, color: accentColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCardData {
  final String title;
  final String caption;
  final List<String> artworkCandidates;
  final IconData fallbackIcon;

  const _ServiceCardData({
    required this.title,
    required this.caption,
    required this.artworkCandidates,
    required this.fallbackIcon,
  });
}

/// Hardware-accelerated Frosted Pearl-Blue & Silver-Rim Service Card.
/// Achieves the exact frosted glass look of Image 1 with zero offscreen BackdropFilter lag.
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
    final radius = BorderRadius.circular(24);

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
          scale: _pressed ? 0.972 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _HomeLiquidTheme.frostPearlLight.withValues(alpha: 0.68),
                  _HomeLiquidTheme.frostPearlBlue.withValues(alpha: 0.72),
                  _HomeLiquidTheme.frostMidCobalt.withValues(alpha: 0.84),
                  _HomeLiquidTheme.frostDeepCobalt.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.28, 0.68, 1.0],
              ),
              borderRadius: radius,
              border: Border.all(
                color: _pressed
                    ? Colors.white.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.74),
                width: _pressed ? 1.45 : 1.25,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 12, 11),
                child: Stack(
                  children: [
                    // Soft pearl-white & ice-blue radial glow behind the 3D icon
                    Positioned(
                      top: -28,
                      left: -20,
                      child: Container(
                        width: 155,
                        height: 135,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.34),
                              _HomeLiquidTheme.iceBlue.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom-right soft frost bloom
                    Positioned(
                      right: -24,
                      bottom: -30,
                      child: Container(
                        width: 128,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.22),
                              _HomeLiquidTheme.electricCyan.withValues(
                                alpha: 0.14,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top inner silver-white glass bevel highlight
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 1.4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.88),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top-right circular frosted glass arrow button
                    Positioned(
                      top: 2,
                      right: 0,
                      child: Container(
                        width: 29,
                        height: 29,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.36),
                              _HomeLiquidTheme.frostMidCobalt.withValues(
                                alpha: 0.65,
                              ),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.74),
                            width: 1.1,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_right,
                          size: 13.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prominent 3D service logo stage with downsampled cacheWidth
                        SizedBox(
                          width: 116,
                          height: 92,
                          child: Transform.scale(
                            scale: 1.18,
                            alignment: Alignment.centerLeft,
                            child: _ResilientAssetImage(
                              candidates: data.artworkCandidates,
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.contain,
                              cacheWidth: 280,
                              fallbackIcon: data.fallbackIcon,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.15,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _HomeLiquidTheme.softIceText.withValues(
                              alpha: 0.94,
                            ),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
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

class _LiquidModalSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final List<Widget> children;

  const _LiquidModalSheet({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B5299),
            Color(0xFF102552),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _HomeLiquidTheme.softIceText.withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _SheetStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SheetStatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;

  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          gradient: secondary
              ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    _HomeLiquidTheme.frostMidCobalt.withValues(alpha: 0.48),
                  ],
                )
              : const LinearGradient(
                  colors: [
                    _HomeLiquidTheme.electricCyan,
                    _HomeLiquidTheme.luminousAzure,
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: secondary ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caches the working asset candidate path in memory so scrolling never re-probes failed paths,
/// and decodes images at `cacheWidth` to save ~90% of GPU texture memory.
class _ResilientAssetImage extends StatelessWidget {
  static final Map<String, int> _resolvedIndexCache = <String, int>{};

  final List<String> candidates;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final int? cacheWidth;
  final IconData? fallbackIcon;

  const _ResilientAssetImage({
    required this.candidates,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.cacheWidth,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cacheKey = candidates.first;
    final startIdx = _resolvedIndexCache[cacheKey] ?? 0;
    return _buildCandidate(cacheKey, startIdx);
  }

  Widget _buildCandidate(String cacheKey, int index) {
    if (index >= candidates.length) {
      if (fallbackIcon == null) return const SizedBox.shrink();
      return Align(
        alignment: alignment,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          child: Icon(
            fallbackIcon,
            color: _HomeLiquidTheme.electricCyan,
            size: 28,
          ),
        ),
      );
    }

    return Image.asset(
      candidates[index],
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) {
          _resolvedIndexCache[cacheKey] = index;
        }
        return child;
      },
      errorBuilder: (_, _, _) {
        final next = index + 1;
        _resolvedIndexCache[cacheKey] = next;
        return _buildCandidate(cacheKey, next);
      },
    );
  }
}