import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HujjatlarPage extends StatefulWidget {
  const _DocumentsPage({super.key});

  @override
  State<HujjatlarPage> createState() => _HujjatlarPageState();
}

class _HujjatlarPageState extends State<HujjatlarPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Barchasi';
  bool _sortAscending = false;

  static const _filters = [
    'Barchasi',
    'Shartnomalar',
    'Arizalar',
    'Shablonlar',
  ];

  static const _documents = <_DocumentData>[
    _DocumentData(
      title: 'Ijara shartnomasi',
      type: 'Shartnoma',
      category: 'Shartnomalar',
      date: 'Bugun, 14:32',
      status: 'Imzolangan',
      statusColor: Color(0xFF6ED9B2),
      icon: CupertinoIcons.doc_checkmark,
      iconColor: Color(0xFF8EE6BC),
      iconBackground: Color(0xFF245546),
    ),
    _DocumentData(
      title: 'Mehnat shartnomasi',
      type: 'Shartnoma',
      category: 'Shartnomalar',
      date: 'Kecha, 09:18',
      status: 'Ko‘rib chiqilmoqda',
      statusColor: Color(0xFFFFC36E),
      icon: CupertinoIcons.doc_text,
      iconColor: Color(0xFFFFD18B),
      iconBackground: Color(0xFF5C482C),
    ),
    _DocumentData(
      title: 'Sudga murojaat arizasi',
      type: 'Ariza',
      category: 'Arizalar',
      date: '18-sentabr, 2026',
      status: 'Qoralama',
      statusColor: Color(0xFFAFC2E2),
      icon: CupertinoIcons.doc_plaintext,
      iconColor: Color(0xFFB9CCFF),
      iconBackground: Color(0xFF35496D),
    ),
    _DocumentData(
      title: 'Ishonchnoma',
      type: 'Shablon',
      category: 'Shablonlar',
      date: '12-sentabr, 2026',
      status: 'Tayyor',
      statusColor: Color(0xFFCAAEFF),
      icon: CupertinoIcons.doc,
      iconColor: Color(0xFFD7C0FF),
      iconBackground: Color(0xFF51416E),
    ),
    _DocumentData(
      title: 'Shaxsiy ma’lumotlarni himoya qilish',
      type: 'Ariza',
      category: 'Arizalar',
      date: '02-sentabr, 2026',
      status: 'Arxivlangan',
      statusColor: Color(0xFF9CA8B8),
      icon: CupertinoIcons.archivebox,
      iconColor: Color(0xFFB9C3D2),
      iconBackground: Color(0xFF3C4654),
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

  List<_DocumentData> get _visibleDocuments {
    final query = _searchController.text.trim().toLowerCase();
    final result = _documents.where((document) {
      final matchesFilter = _selectedFilter == 'Barchasi' ||
          document.category == _selectedFilter;
      final matchesQuery = query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.type.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    if (_sortAscending) {
      result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visibleDocuments = _visibleDocuments;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 21, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildStats()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildFilters()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text(
                  'So‘nggi hujjatlar',
                  style: TextStyle(
                    color: Color(0xFFF1F5FC),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _sortAscending = !_sortAscending),
                  child: Row(
                    children: [
                      Icon(
                        _sortAscending
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        color: const Color(0xFF94AEE1),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _sortAscending ? 'A–Z' : 'Eng yangi',
                        style: const TextStyle(
                          color: Color(0xFF94AEE1),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (visibleDocuments.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 122),
            sliver: SliverToBoxAdapter(child: _buildEmptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 122),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleDocuments.length - 1 ? 0 : 10,
                  ),
                  child: _DocumentListItem(
                    document: visibleDocuments[index],
                    onTap: () => _showDocumentDetails(visibleDocuments[index]),
                  ),
                ),
                childCount: visibleDocuments.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hujjatlar',
                style: TextStyle(
                  color: Color(0xFFF5F7FC),
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Barcha hujjatlaringiz bir joyda',
                style: TextStyle(
                  color: Color(0xFF8F9CAE),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showCreateDocumentOptions,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF729BFF), Color(0xFF4069D9)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF527EEA).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return CupertinoTextField(
      controller: _searchController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: Color(0xFFF2F5FA),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      placeholder: 'Hujjatlarni izlash',
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
        color: const Color(0xFF273546).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.105),
        ),
      ),
      cursorColor: const Color(0xFFADC4FF),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _DocumentStat(
            value: '12',
            label: 'Jami',
            color: const Color(0xFF8EB0FF),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _DocumentStat(
            value: '03',
            label: 'Jarayonda',
            color: const Color(0xFFFFC36E),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _DocumentStat(
            value: '08',
            label: 'Yakunlangan',
            color: const Color(0xFF6ED9B2),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DocumentFilterChip(
                  label: filter,
                  selected: _selectedFilter == filter,
                  onTap: () => setState(() => _selectedFilter = filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 29, 22, 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
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
              CupertinoIcons.doc_text_search,
              color: Color(0xFF9DBBFF),
              size: 25,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Hujjat topilmadi',
            style: TextStyle(
              color: Color(0xFFF0F4FB),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Qidiruv so‘zini yoki filtrni o‘zgartirib ko‘ring.',
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

  void _showCreateDocumentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18283A),
      barrierColor: Colors.black.withValues(alpha: 0.62),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yangi hujjat',
                  style: TextStyle(
                    color: Color(0xFFF4F7FD),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Boshlash usulini tanlang.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                _DocumentCreateOption(
                  icon: CupertinoIcons.pencil,
                  title: 'Shablondan yaratish',
                  subtitle: 'Tayyor huquqiy shablonlardan foydalaning',
                  color: const Color(0xFF9DBBFF),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Shablondan hujjat yaratish');
                  },
                ),
                const SizedBox(height: 10),
                _DocumentCreateOption(
                  icon: CupertinoIcons.doc,
                  title: 'Bo‘sh hujjat',
                  subtitle: 'Hujjatni noldan tayyorlang',
                  color: const Color(0xFF85DFB7),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Bo‘sh hujjat yaratish');
                  },
                ),
                const SizedBox(height: 10),
                _DocumentCreateOption(
                  icon: CupertinoIcons.paperplane,
                  title: 'Hujjat yuklash',
                  subtitle: 'PDF yoki Word faylini qo‘shing',
                  color: const Color(0xFFFFC87B),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Hujjat yuklash');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDocumentDetails(_DocumentData document) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18283A),
      barrierColor: Colors.black.withValues(alpha: 0.62),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: document.iconBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        document.icon,
                        color: document.iconColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: const TextStyle(
                              color: Color(0xFFF4F7FD),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${document.type}  •  ${document.date}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DocumentDetailAction(
                        icon: CupertinoIcons.eye,
                        label: 'Ko‘rish',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showComingSoon('Hujjatni ko‘rish');
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _DocumentDetailAction(
                        icon: CupertinoIcons.share,
                        label: 'Ulashish',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showComingSoon('Hujjatni ulashish');
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _DocumentDetailAction(
                        icon: CupertinoIcons.ellipsis,
                        label: 'Boshqa',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showComingSoon('Qo‘shimcha amallar');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — tez orada'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          98 + MediaQuery.paddingOf(context).bottom,
        ),
        backgroundColor: const Color(0xFF2A3D58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _DocumentData {
  final String title;
  final String type;
  final String category;
  final String date;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _DocumentData({
    required this.title,
    required this.type,
    required this.category,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}

class _DocumentStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _DocumentStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.052),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocumentFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF557CD3).withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF88A9FF).withValues(alpha: 0.58)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFFDCE6FF)
                : Colors.white.withValues(alpha: 0.59),
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DocumentListItem extends StatelessWidget {
  final _DocumentData document;
  final VoidCallback onTap;

  const _DocumentListItem({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.085),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: document.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: document.iconColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  document.icon,
                  color: document.iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF2F5FA),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${document.type}  •  ${document.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: document.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          document.status,
                          style: TextStyle(
                            color: document.statusColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.38),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DocumentCreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.085),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF2F5FB),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentDetailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DocumentDetailAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF9DBBFF),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

