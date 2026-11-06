import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../services/alimony_claim_document_service.dart';
import '../services/family_claim_document_service.dart';
import '../shared/profile_widgets.dart';
import '../shared/user_profile.dart';
import 'services/advokat_yollash_page.dart';
import 'services/alimony_claim_page.dart';
import 'services/family_claim_page.dart';
import 'services/lawyer_draft_request_page.dart';

class BoshSahifaPage extends StatefulWidget {
  const BoshSahifaPage({super.key});

  @override
  State<BoshSahifaPage> createState() => _BoshSahifaPageState();
}

class _BoshSahifaPageState extends State<BoshSahifaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Barchasi';

  static const List<String> _categories = <String>[
    'Barchasi',
    'Advokat va maslahat',
    'Aliment va ta’minot',
    'Oila va bolalar',
  ];

  static const List<_ServiceCardData> _services = <_ServiceCardData>[
    _ServiceCardData(
      title: 'Advokatga ariza yozdirish',
      caption: 'Yuridik ariza va hujjatlarni tayyorlash',
      category: 'Advokat va maslahat',
      artworkCandidates: <String>[
        'assets/service_artwork/arizalogo.png',
        'assets/service_artwork/arizalogo',
        'assets/service_artwork/arizalogo.jpg',
        'assets/service_artwork/arizalogo.webp',
        'assets/service_artwork/court_filing.png',
      ],
      fallbackIcon: CupertinoIcons.doc_text_fill,
    ),
    _ServiceCardData(
      title: 'Konsultatsiya',
      caption: 'Malakali yuridik maslahat olish',
      category: 'Advokat va maslahat',
      artworkCandidates: <String>[
        'assets/service_artwork/consult.png',
        'assets/service_artwork/consult',
        'assets/service_artwork/consult.jpg',
        'assets/service_artwork/consult.webp',
        'assets/service_artwork/consultation.png',
      ],
      fallbackIcon: CupertinoIcons.chat_bubble_2_fill,
    ),
    _ServiceCardData(
      title: 'Advokat yollash',
      caption: 'Sizga mos advokatni tanlash',
      category: 'Advokat va maslahat',
      artworkCandidates: <String>[
        'assets/service_artwork/advocatebooking.png',
        'assets/service_artwork/advocatebooking',
        'assets/service_artwork/advocatebooking.jpg',
        'assets/service_artwork/advocatebooking.webp',
        'assets/service_artwork/lawyer.png',
      ],
      fallbackIcon: CupertinoIcons.briefcase_fill,
    ),
    _ServiceCardData(
      title: 'Bolaga aliment undirish',
      caption: 'Farzandingiz uchun aliment talab qilish',
      category: 'Aliment va ta’minot',
      artworkCandidates: <String>[
        'assets/service_artwork/alimony.png',
        'assets/service_artwork/alimony',
        'assets/service_artwork/alimony.jpg',
        'assets/service_artwork/alimony.webp',
        'assets/service_artwork/child_support.png',
      ],
      fallbackIcon: CupertinoIcons.money_dollar_circle_fill,
    ),
    _ServiceCardData(
      title: "Ona ta'minoti uchun aliment undirish",
      caption: "Ona ta'minoti uchun huquqiy yordam",
      category: 'Aliment va ta’minot',
      artworkCandidates: <String>[
        'assets/service_artwork/onataminoti.png',
        'assets/service_artwork/onataminoti',
        'assets/service_artwork/onataminoti.jpg',
        'assets/service_artwork/onataminoti.webp',
        'assets/service_artwork/mother_support.png',
      ],
      fallbackIcon: CupertinoIcons.heart_circle_fill,
    ),
    _ServiceCardData(
      title: 'Bolaning yashash joyini belgilash',
      caption: 'Bola yashash joyini rasmiy belgilash',
      category: 'Oila va bolalar',
      artworkCandidates: <String>[
        'assets/service_artwork/yashashjoyi.png',
        'assets/service_artwork/yashashjoyi',
        'assets/service_artwork/yashashjoyi.jpg',
        'assets/service_artwork/yashashjoyi.webp',
        'assets/service_artwork/child_residence.png',
      ],
      fallbackIcon: CupertinoIcons.house_fill,
    ),
    _ServiceCardData(
      title: "Bola bilan ko'rishish tartibini belgilash",
      caption: "Ko'rishish tartibini huquqiy belgilash",
      category: 'Oila va bolalar',
      artworkCandidates: <String>[
        'assets/service_artwork/korishish.png',
        'assets/service_artwork/korishish',
        'assets/service_artwork/korishish.jpg',
        'assets/service_artwork/korishish.webp',
        'assets/service_artwork/visitation.png',
      ],
      fallbackIcon: CupertinoIcons.person_2_fill,
    ),
    _ServiceCardData(
      title: 'Nikohdan ajrashish',
      caption: 'Ajrashish arizasini tayyorlash',
      category: 'Oila va bolalar',
      artworkCandidates: <String>[
        'assets/service_artwork/ajrim.png',
        'assets/service_artwork/ajrim',
        'assets/service_artwork/ajrim.jpg',
        'assets/service_artwork/ajrim.webp',
        'assets/service_artwork/divorce.png',
      ],
      fallbackIcon: CupertinoIcons.doc_person_fill,
    ),
  ];

  static const List<String> _swallowCandidates = <String>[
    'assets/service_artwork/yanswallow.png',
    'assets/service_artwork/yanswallow',
    'assets/yanswallow.png',
    'assets/yanswallow',
    'assets/service_artwork/yanswallow.webp',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  List<_ServiceCardData> get _visibleServices {
    final query = _searchController.text.trim().toLowerCase();
    return _services.where((service) {
      final matchesCategory =
          _selectedCategory == 'Barchasi' ||
          service.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return service.title.toLowerCase().contains(query) ||
          service.caption.toLowerCase().contains(query);
    }).toList();
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

  void _openService(_ServiceCardData service) {
    if (service.title == 'Bolaga aliment undirish') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
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
        MaterialPageRoute<void>(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.childResidence,
          ),
        ),
      );
      return;
    }

    if (service.title == "Ona ta'minoti uchun aliment undirish") {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.motherSupport,
          ),
        ),
      );
      return;
    }

    if (service.title == "Bola bilan ko'rishish tartibini belgilash") {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.childVisitation,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Nikohdan ajrashish') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const FamilyClaimPage(
            type: FamilyClaimType.divorce,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Advokatga ariza yozdirish') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LawyerDraftRequestPage(
            onSubmit: _handleLawyerDraftSubmit,
          ),
        ),
      );
      return;
    }

    if (service.title == 'Konsultatsiya') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
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
        MaterialPageRoute<void>(
          builder: (_) => AdvokatYollashPage(
            initialRepresentation: true,
            onSubmit: _handleLawyerOrConsultSubmit,
          ),
        ),
      );
      return;
    }
  }

  void _showCategoryFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          decoration: BoxDecoration(
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: YanColors.primaryNavy.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YanColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xizmatlar toifasini tanlang',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ..._categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? YanColors.primaryBlue
                              : YanColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              selected
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.square_grid_2x2,
                              size: 18,
                              color: selected
                                  ? YanColors.white
                                  : YanColors.primaryNavy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: selected
                                      ? YanColors.white
                                      : YanColors.primaryNavy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet() {
    final entries = ActivityHistoryRepository.instance.entries.value;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YanColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bildirishnomalar va yangiliklar',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...entries.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassWindow(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: YanColors.lightBlue,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              item.icon,
                              color: YanColors.primaryBlue,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: YanColors.primaryNavy,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: YanColors.mutedText,
                                    fontSize: 11.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatsDetailModal({
    required String title,
    required String subtitle,
    required List<GeneratedDocument> docs,
    required List<ActivityEntry> entries,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YanColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: YanColors.mutedText,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      if (docs.isNotEmpty)
                        ...docs.map(
                          (doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: LiquidGlassWindow(
                              padding: const EdgeInsets.all(13),
                              onTap: () => OpenFilex.open(doc.path),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: YanColors.lightBlue,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.doc_checkmark_fill,
                                      color: YanColors.primaryBlue,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          doc.title,
                                          style: const TextStyle(
                                            color: YanColors.primaryNavy,
                                            fontSize: 13.8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Rasmiy DOCX hujjat • Ochish uchun bosing',
                                          style: const TextStyle(
                                            color: YanColors.mutedText,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.arrow_up_right_square,
                                    color: YanColors.primaryBlue,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ...entries.take(5).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: LiquidGlassWindow(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: YanColors.lightBlue,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    entry.icon,
                                    color: YanColors.primaryBlue,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        entry.title,
                                        style: const TextStyle(
                                          color: YanColors.primaryNavy,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${entry.statusLabel} • ${entry.dateFormatted}',
                                        style: const TextStyle(
                                          color: YanColors.mutedText,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleServices = _visibleServices;

    return CustomScrollView(
      key: const ValueKey<String>('home'),
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildBrandHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildMiniProfileCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeading(visibleServices.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 118),
          sliver: visibleServices.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = visibleServices[index];
                      return _CleanServiceCard(
                        data: service,
                        onTap: () => _openService(service),
                      );
                    },
                    childCount: visibleServices.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 174,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return SizedBox(
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Subtle light-blue ribbon wave along the swallow flight line
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SwallowRibbonPainter(),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Standalone unboxed firm shield logo at FULL native quality
              SizedBox(
                width: 58,
                height: 62,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) => const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 48,
                    color: YanColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1.2,
                height: 40,
                color: YanColors.border,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RichText(
                      text: const TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'YAN',
                            style: TextStyle(
                              color: YanColors.primaryNavy,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              height: 1.05,
                            ),
                          ),
                          TextSpan(
                            text: '360',
                            style: TextStyle(
                              color: YanColors.primaryBlue,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Yuridik xizmatlar platformasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 84),
              // Selective Liquid Glass Notification Bell Button
              GestureDetector(
                onTap: _showNotificationsSheet,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                    border: Border.all(color: YanColors.border, width: 1.2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: YanColors.primaryNavy.withValues(alpha: 0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.bell,
                        color: YanColors.primaryNavy,
                        size: 20,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 7.5,
                          height: 7.5,
                          decoration: const BoxDecoration(
                            color: YanColors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Soaring swallow at FULL native resolution (no cacheWidth downscaling)
          Positioned(
            right: 48,
            top: -4,
            width: 112,
            height: 82,
            child: IgnorePointer(
              child: _ResilientAssetImage(
                candidates: _swallowCandidates,
                fit: BoxFit.contain,
                fallback: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProfileCard() {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        return ValueListenableBuilder<List<GeneratedDocument>>(
          valueListenable: GeneratedDocumentRepository.instance.documents,
          builder: (context, docs, _) {
            return ValueListenableBuilder<List<ActivityEntry>>(
              valueListenable: ActivityHistoryRepository.instance.entries,
              builder: (context, history, _) {
                final docxCount = docs.isNotEmpty
                    ? docs.length
                    : profile.savedDocuments;
                final totalArizalar = docxCount + profile.activeApplications;
                final lawyerCount =
                    24 +
                    history
                        .where(
                          (e) =>
                              e.category == ActivityCategory.lawyer ||
                              e.category == ActivityCategory.consultation,
                        )
                        .length;
                final historyCount = 64 + history.length;

                return _MiniProfileCard(
                  profile: profile,
                  totalArizalarCount: totalArizalar,
                  docxCount: docxCount,
                  lawyerCount: lawyerCount,
                  historyCount: historyCount,
                  onArizalarTap: () => _showStatsDetailModal(
                    title: 'Arizalar va hujjatlar ($totalArizalar ta)',
                    subtitle:
                        'Yaratilgan rasmiy DOCX da’vo arizalari va yuristga yuborilgan murojaatlar',
                    docs: docs,
                    entries: history,
                  ),
                  onProfileTap: () => _showStatsDetailModal(
                    title: '${profile.displayName} — Huquqiy profil',
                    subtitle:
                        'ID: ${profile.clientId} • ${profile.fullAddress} • Tayyorlik: ${profile.completionPercent}',
                    docs: docs,
                    entries: history,
                  ),
                  onReadinessTap: () => _showStatsDetailModal(
                    title: 'Profil tayyorligi: ${profile.completionPercent}',
                    subtitle: profile.missingProfileItems.isEmpty
                        ? 'Barcha shaxsiy va yuridik rekvizitlar to‘liq kiritilgan (Mukammal).'
                        : 'To‘ldirilmagan maydonlar: ${profile.missingProfileItems.join(", ")}',
                    docs: docs,
                    entries: history,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeading(int count) {
    final formattedCount = count.toString().padLeft(2, '0');
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Kerakli xizmatni tanlang',
            style: TextStyle(
              color: YanColors.primaryNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showCategoryFilterSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: YanColors.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: YanColors.primaryNavy.withValues(alpha: 0.045),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  CupertinoIcons.square_grid_2x2_fill,
                  size: 14,
                  color: YanColors.cyanAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  '$formattedCount XIZMAT',
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YanColors.border, width: 1.15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: YanColors.primaryNavy.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            CupertinoIcons.search,
            size: 19,
            color: YanColors.primaryNavy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Xizmatni izlang...',
              placeholderStyle: const TextStyle(
                color: YanColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              style: const TextStyle(
                color: YanColors.primaryNavy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
              padding: EdgeInsets.zero,
              cursorColor: YanColors.primaryBlue,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _searchController.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 17,
                  color: YanColors.subtleText,
                ),
              ),
            ),
          GestureDetector(
            onTap: _showCategoryFilterSheet,
            child: const Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 19,
              color: YanColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LiquidGlassWindow(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Icon(
            CupertinoIcons.search_circle,
            size: 42,
            color: YanColors.primaryBlue,
          ),
          const SizedBox(height: 10),
          const Text(
            'Mos xizmat topilmadi',
            style: TextStyle(
              color: YanColors.primaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Qidiruv so‘zini o‘zgartiring yoki barcha toifalarni ko‘ring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YanColors.mutedText,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          LiquidActionButton(
            label: 'Barcha xizmatlarni ko‘rsatish',
            icon: CupertinoIcons.refresh,
            compact: true,
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = 'Barchasi';
              });
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Selective Liquid Glass Profile & Metrics Banner (Matches Reference 1-to-1)
// ═══════════════════════════════════════════════════════════════════════════

class _MiniProfileCard extends StatelessWidget {
  const _MiniProfileCard({
    required this.profile,
    required this.totalArizalarCount,
    required this.docxCount,
    required this.lawyerCount,
    required this.historyCount,
    required this.onArizalarTap,
    required this.onProfileTap,
    required this.onReadinessTap,
  });

  final UserProfileData profile;
  final int totalArizalarCount;
  final int docxCount;
  final int lawyerCount;
  final int historyCount;
  final VoidCallback onArizalarTap;
  final VoidCallback onProfileTap;
  final VoidCallback onReadinessTap;

  Color _readinessColor(double value) {
    final pct = value * 100;
    if (pct < 50) return YanColors.destructiveRed;
    if (pct < 80) return const Color(0xFFF59E0B);
    return YanColors.successGreen; // #10C995 for 80%+
  }

  String _readinessLabel(double value) {
    final pct = value * 100;
    if (pct < 50) return 'Past';
    if (pct < 80) return 'O‘rtacha';
    return 'Mukammal';
  }

  @override
  Widget build(BuildContext context) {
    final completion = profile.profileCompletion;
    final ringColor = _readinessColor(completion);
    final statusText = _readinessLabel(completion);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: YanColors.primaryNavy.withValues(alpha: 0.065),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              // 1. Left: Arizalar va hujjatlar
              Expanded(
                flex: 11,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onArizalarTap,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 44,
                        decoration: BoxDecoration(
                          color: YanColors.lightBlue,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: YanColors.border),
                        ),
                        child: const Icon(
                          CupertinoIcons.doc_text_fill,
                          color: YanColors.cyanAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  '$totalArizalarCount',
                                  style: const TextStyle(
                                    color: YanColors.primaryNavy,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 13,
                                  color: YanColors.primaryNavy,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Arizalar va\nhujjatlar',
                              style: TextStyle(
                                color: YanColors.primaryNavy,
                                fontSize: 10.6,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: YanColors.divider,
              ),
              // 2. Center: User Profile Avatar (NO) + Verified Checkmark + Name
              Expanded(
                flex: 9,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onProfileTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: YanColors.primaryNavy,
                              border: Border.all(
                                color: YanColors.cyanAccent,
                                width: 2.2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: YanColors.cyanAccent.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: buildAvatarContent(
                                profile,
                                initialsSize: 17,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: YanColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              profile.firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: YanColors.primaryNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 11,
                            color: YanColors.primaryNavy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: YanColors.divider,
              ),
              // 3. Right: Dynamic Circular Profil Tayyorligi Ring + Mukammal Pill
              Expanded(
                flex: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onReadinessTap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 46,
                                height: 46,
                                child: CircularProgressIndicator(
                                  value: completion.clamp(0.08, 1.0),
                                  strokeWidth: 4.5,
                                  backgroundColor: ringColor.withValues(
                                    alpha: 0.18,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ringColor,
                                  ),
                                ),
                              ),
                              Text(
                                profile.completionPercent,
                                style: const TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Profil\ntayyorligi',
                                style: TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 10.6,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: ringColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ringColor.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: ringColor == YanColors.successGreen
                                        ? const Color(0xFF098562)
                                        : ringColor,
                                    fontSize: 9.6,
                                    fontWeight: FontWeight.w800,
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom Row: 3 Clickable Quick-Stat Pills (DOCX, Yurist, Tarix)
          Row(
            children: <Widget>[
              Expanded(
                child: _HeaderStatPill(
                  icon: CupertinoIcons.doc_text_fill,
                  iconColor: YanColors.cyanAccent,
                  label: 'DOCX: $docxCount ta',
                  onTap: onArizalarTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderStatPill(
                  icon: CupertinoIcons.videocam_fill,
                  iconColor: YanColors.cyanAccent,
                  label: 'Yurist: $lawyerCount ta',
                  onTap: onProfileTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderStatPill(
                  icon: CupertinoIcons.checkmark_circle_fill,
                  iconColor: YanColors.successGreen,
                  label: 'Tarix: $historyCount ta',
                  onTap: onReadinessTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  const _HeaderStatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 8),
        decoration: BoxDecoration(
          color: YanColors.lightBlue.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: YanColors.primaryNavy.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 13.5, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Clean Light Service Card (Matches Reference 1-to-1 + Full Native Logo Quality)
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceCardData {
  const _ServiceCardData({
    required this.title,
    required this.caption,
    required this.category,
    required this.artworkCandidates,
    required this.fallbackIcon,
  });

  final String title;
  final String caption;
  final String category;
  final List<String> artworkCandidates;
  final IconData fallbackIcon;
}

class _CleanServiceCard extends StatefulWidget {
  const _CleanServiceCard({
    required this.data,
    required this.onTap,
  });

  final _ServiceCardData data;
  final VoidCallback onTap;

  @override
  State<_CleanServiceCard> createState() => _CleanServiceCardState();
}

class _CleanServiceCardState extends State<_CleanServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 12, 12),
            decoration: BoxDecoration(
              color: YanColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: YanColors.border,
                width: 1.15,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: YanColors.primaryNavy.withValues(alpha: 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                // Subtle soft light-blue atmospheric corner wave (#EAF5FF)
                Positioned(
                  right: -25,
                  bottom: -25,
                  child: IgnorePointer(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            YanColors.lightBlue.withValues(alpha: 0.85),
                            YanColors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Top-Right Simple Navigation Arrow Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: YanColors.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_right,
                      size: 14,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                ),
                // Main Card Content: High-Res Illustration + Bold Navy Title + Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14, top: 2),
                          child: _ResilientAssetImage(
                            candidates: widget.data.artworkCandidates,
                            fit: BoxFit.contain,
                            fallback: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: YanColors.lightBlue,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                widget.data.fallbackIcon,
                                size: 32,
                                color: YanColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YanColors.primaryNavy,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3.5),
                    Text(
                      widget.data.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w500,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// High-Resolution Asset Loader (NEVER downscales logos; FilterQuality.high)
// ═══════════════════════════════════════════════════════════════════════════

class _ResilientAssetImage extends StatefulWidget {
  const _ResilientAssetImage({
    required this.candidates,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final List<String> candidates;
  final Widget fallback;
  final BoxFit fit;

  @override
  State<_ResilientAssetImage> createState() => _ResilientAssetImageState();
}

class _ResilientAssetImageState extends State<_ResilientAssetImage> {
  static final Map<String, String?> _resolvedCache = <String, String?>{};
  String? _resolvedPath;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _resolveAsset();
  }

  @override
  void didUpdateWidget(covariant _ResilientAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates.firstOrNull != widget.candidates.firstOrNull) {
      _resolveAsset();
    }
  }

  Future<void> _resolveAsset() async {
    final cacheKey = widget.candidates.join('|');
    if (_resolvedCache.containsKey(cacheKey)) {
      _resolvedPath = _resolvedCache[cacheKey];
      _checked = true;
      return;
    }

    for (final candidate in widget.candidates) {
      try {
        await rootBundle.load(candidate);
        _resolvedCache[cacheKey] = candidate;
        if (mounted) {
          setState(() {
            _resolvedPath = candidate;
            _checked = true;
          });
        }
        return;
      } catch (_) {
        // Try next candidate extension
      }
    }

    _resolvedCache[cacheKey] = null;
    if (mounted) {
      setState(() {
        _resolvedPath = null;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _resolvedPath ?? widget.candidates.firstOrNull;
    if (_checked && _resolvedPath == null) {
      return widget.fallback;
    }
    if (path == null) return widget.fallback;

    // Renders at 100% full native resolution with FilterQuality.high
    return Image.asset(
      path,
      fit: widget.fit,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (_, __, ___) => widget.fallback,
    );
  }
}

class _SwallowRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.88)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.94,
        size.width * 0.56,
        size.height * 0.46,
        size.width * 0.88,
        size.height * 0.62,
      );

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: <Color>[
          YanColors.lightBlue.withValues(alpha: 0.0),
          YanColors.cyanAccent.withValues(alpha: 0.22),
          YanColors.primaryBlue.withValues(alpha: 0.25),
          YanColors.lightBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}