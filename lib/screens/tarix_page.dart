import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TarixPage extends StatefulWidget {
  const _HistoryPage({super.key});

  @override
  State<TarixPage> createState() => _TarixPageState();
}

class _TarixPageState extends State<TarixPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Barchasi';
  late List<_HistoryData> _history;

  static const _filters = [
    'Barchasi',
    'Hujjatlar',
    'Amallar',
    'Konsultatsiya',
  ];

  static const _historySeed = <_HistoryData>[
    _HistoryData(
      group: 'Bugun',
      title: 'Ijara shartnomasi ko‘rib chiqildi',
      description: 'Shartnoma tafsilotlari ochildi',
      time: '14:32',
      category: 'Hujjatlar',
      label: 'Ko‘rildi',
      icon: CupertinoIcons.doc_checkmark,
      color: Color(0xFF83E4B6),
      iconBackground: Color(0xFF245546),
    ),
    _HistoryData(
      group: 'Bugun',
      title: 'Konsultatsiya so‘rovi yuborildi',
      description: 'Mehnat huquqi bo‘yicha maslahat',
      time: '12:08',
      category: 'Konsultatsiya',
      label: 'Yuborildi',
      icon: CupertinoIcons.person_2,
      color: Color(0xFFFFC979),
      iconBackground: Color(0xFF5C482C),
    ),
    _HistoryData(
      group: 'Bugun',
      title: 'Hujjat yuklandi',
      description: 'Mehnat shartnomasi.pdf',
      time: '09:41',
      category: 'Amallar',
      label: 'Yuklandi',
      icon: CupertinoIcons.paperplane,
      color: Color(0xFFAFC4FF),
      iconBackground: Color(0xFF334A75),
    ),
    _HistoryData(
      group: 'Kecha',
      title: 'Ishonchnoma shabloni ochildi',
      description: 'Hujjat shablonlari bo‘limidan',
      time: '18:25',
      category: 'Hujjatlar',
      label: 'Ko‘rildi',
      icon: CupertinoIcons.doc_plaintext,
      color: Color(0xFFD0B5FF),
      iconBackground: Color(0xFF4B3B6C),
    ),
    _HistoryData(
      group: 'Kecha',
      title: 'Profil ma’lumotlari yangilandi',
      description: 'Telefon raqami tasdiqlandi',
      time: '10:16',
      category: 'Amallar',
      label: 'Bajarildi',
      icon: CupertinoIcons.person,
      color: Color(0xFF8EE4D1),
      iconBackground: Color(0xFF24534F),
    ),
    _HistoryData(
      group: '18-sentabr, 2026',
      title: 'Sudga murojaat arizasi saqlandi',
      description: 'Qoralama sifatida saqlandi',
      time: '16:47',
      category: 'Hujjatlar',
      label: 'Qoralama',
      icon: CupertinoIcons.folder,
      color: Color(0xFFB9C9E7),
      iconBackground: Color(0xFF3C4D66),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _history = List<_HistoryData>.of(_historySeed);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<_HistoryData> get _visibleHistory {
    final query = _searchController.text.trim().toLowerCase();
    return _history.where((item) {
      final matchesFilter =
          _selectedFilter == 'Barchasi' || item.category == _selectedFilter;
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleHistory = _visibleHistory;

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
        if (visibleHistory.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 122),
            sliver: SliverToBoxAdapter(child: _buildEmptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 122),
            sliver: SliverToBoxAdapter(
              child: _buildGroupedTimeline(visibleHistory),
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
                'Tarix',
                style: TextStyle(
                  color: Color(0xFFF5F7FC),
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'So‘nggi faoliyatlaringiz xronologiyasi',
                style: TextStyle(
                  color: Color(0xFF8F9CAE),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _history.isEmpty ? null : _confirmClearHistory,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash,
                  size: 14,
                  color: _history.isEmpty
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFFFA4A4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tozalash',
                  style: TextStyle(
                    color: _history.isEmpty
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
      placeholder: 'Faoliyatni izlash',
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
          child: _HistoryStat(
            value: '${_history.where((item) => item.group == 'Bugun').length}',
            label: 'Bugun',
            color: const Color(0xFF9DBBFF),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _HistoryStat(
            value: '${_history.where((item) => item.group == 'Kecha').length}',
            label: 'Kecha',
            color: const Color(0xFFFFC979),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _HistoryStat(
            value: '${_history.length}',
            label: 'Jami faoliyat',
            color: const Color(0xFF83E4B6),
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
                child: _HistoryFilterChip(
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

  Widget _buildGroupedTimeline(List<_HistoryData> items) {
    final groups = <String, List<_HistoryData>>{};
    for (final item in items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              ...entry.value.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryTimelineItem(
                    data: item,
                    onTap: () => _showHistoryDetails(item),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 31),
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
              CupertinoIcons.time,
              color: Color(0xFF9DBBFF),
              size: 25,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Faoliyat topilmadi',
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

  void _confirmClearHistory() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Tarixni tozalash'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Barcha faoliyat yozuvlari o‘chiriladi. Bu amalni ortga qaytarib bo‘lmaydi.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _history.clear();
                  _selectedFilter = 'Barchasi';
                  _searchController.clear();
                });
              },
              child: const Text('Tozalash'),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDetails(_HistoryData item) {
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
                        color: item.iconBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFFF4F7FD),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.group}  •  ${item.time}',
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
                const SizedBox(height: 16),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.63),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HistoryDetailAction(
                        icon: CupertinoIcons.arrow_right,
                        label: 'Qayta ochish',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showComingSoon('Faoliyatni qayta ochish');
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _HistoryDetailAction(
                        icon: CupertinoIcons.trash,
                        label: 'O‘chirish',
                        destructive: true,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() => _history.remove(item));
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

class _HistoryData {
  final String group;
  final String title;
  final String description;
  final String time;
  final String category;
  final String label;
  final IconData icon;
  final Color color;
  final Color iconBackground;

  const _HistoryData({
    required this.group,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.iconBackground,
  });
}

class _HistoryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _HistoryStat({
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

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
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

class _HistoryTimelineItem extends StatelessWidget {
  final _HistoryData data;
  final VoidCallback onTap;

  const _HistoryTimelineItem({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.iconBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: data.color.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 21,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 1,
              height: 23,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.fromLTRB(13, 12, 11, 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.085),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF2F5FA),
                            fontSize: 13.2,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: data.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data.label,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.34),
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryDetailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _HistoryDetailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFFFA4A4) : const Color(0xFF9DBBFF);
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
            Icon(icon, size: 18, color: color),
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

