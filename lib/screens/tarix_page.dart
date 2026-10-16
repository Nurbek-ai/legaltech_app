import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../shared/user_profile.dart';

class TarixPage extends StatefulWidget {
  const TarixPage({super.key});

  @override
  State<TarixPage> createState() => _TarixPageState();
}

class _TarixPageState extends State<TarixPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Barchasi';
  bool _onlyWithFiles = false;

  static const _filters = <String>[
    'Barchasi',
    'Hujjatlar',
    'Konsultatsiya',
    'Advokat',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
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

  List<ActivityEntry> _filterEntries(List<ActivityEntry> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((item) {
      if (_onlyWithFiles && !item.hasFile) return false;
      final matchesFilter =
          _selectedFilter == 'Barchasi' ||
          item.category.label == _selectedFilter;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final inTitle = item.title.toLowerCase().contains(query);
      final inDesc = item.description.toLowerCase().contains(query);
      final inRef = (item.referenceCode ?? '').toLowerCase().contains(query);
      final inMeta = item.metadata.values.any(
        (val) => val.toLowerCase().contains(query),
      );
      return inTitle || inDesc || inRef || inMeta;
    }).toList(growable: false);
  }

  int _countForFilter(List<ActivityEntry> all, String filter) {
    if (filter == 'Barchasi') return all.length;
    return all.where((e) => e.category.label == filter).length;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityEntry>>(
      valueListenable: ActivityHistoryRepository.instance.entries,
      builder: (context, allEntries, _) {
        final visibleEntries = _filterEntries(allEntries);

        return CustomScrollView(
          key: const ValueKey<String>('tarix-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(allEntries),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildActivityPulseCard(allEntries),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildFilterBar(allEntries),
              ),
            ),
            if (visibleEntries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 122),
                sliver: SliverToBoxAdapter(
                  child: _buildEmptyState(allEntries.isEmpty),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 122),
                sliver: SliverToBoxAdapter(
                  child: _buildGroupedTimeline(visibleEntries),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(List<ActivityEntry> allEntries) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D87E8).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFF88AEFF).withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'FAOLIYAT JURNALI',
                      style: TextStyle(
                        color: Color(0xFF9FBFFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tarix va jarayonlar',
                style: TextStyle(
                  color: Color(0xFFF5F7FC),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => ActivityHistoryRepository.instance.reload(),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
            child: const Icon(
              CupertinoIcons.refresh,
              size: 16,
              color: Color(0xFFADC4FF),
            ),
          ),
        ),
        GestureDetector(
          onTap: allEntries.isEmpty ? null : _confirmClearHistory,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: allEntries.isEmpty
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF42232B).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: allEntries.isEmpty
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFFF8B8B).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash,
                  size: 14,
                  color: allEntries.isEmpty
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFFFA4A4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tozalash',
                  style: TextStyle(
                    color: allEntries.isEmpty
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFFFC2C2),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityPulseCard(List<ActivityEntry> allEntries) {
    final now = DateTime.now();
    final todayCount = allEntries
        .where((e) => e.groupLabel(now) == 'Bugun')
        .length;
    final docCount = allEntries
        .where((e) => e.category == ActivityCategory.documents)
        .length;
    final consultAndLawyerCount = allEntries
        .where(
          (e) =>
              e.category == ActivityCategory.consultation ||
              e.category == ActivityCategory.lawyer,
        )
        .length;
    final fileEntriesCount = allEntries.where((e) => e.hasFile).length;

    final total = allEntries.isEmpty ? 1 : allEntries.length;
    final docFlex = ((docCount / total) * 100).round().clamp(15, 100);
    final consultFlex = ((consultAndLawyerCount / total) * 100)
        .round()
        .clamp(15, 100);
    final otherFlex = (100 - docFlex - consultFlex).clamp(15, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF152942),
            Color(0xFF0E1D30),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7FA6F5).withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: Color(0xFF83E4B6),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Faoliyat ko‘rsatkichlari',
                  style: TextStyle(
                    color: Color(0xFFEAF1FC),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _onlyWithFiles = !_onlyWithFiles),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _onlyWithFiles
                        ? const Color(0xFF67E2B8).withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _onlyWithFiles
                          ? const Color(0xFF67E2B8).withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_checkmark_fill,
                        size: 11,
                        color: _onlyWithFiles
                            ? const Color(0xFF7CF0C7)
                            : Colors.white60,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'DOCX fayllar ($fileEntriesCount)',
                        style: TextStyle(
                          color: _onlyWithFiles
                              ? const Color(0xFFD6FFF0)
                              : Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: docFlex,
                    child: Container(color: const Color(0xFF67E2B8)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: consultFlex,
                    child: Container(color: const Color(0xFFFFC979)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: otherFlex,
                    child: Container(color: const Color(0xFF9DBBFF)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _PulseMetricItem(
                label: 'Jami yozuv',
                value: allEntries.length.toString(),
                dotColor: const Color(0xFF9DBBFF),
              ),
              _verticalDivider(),
              _PulseMetricItem(
                label: 'Bugun',
                value: todayCount.toString(),
                dotColor: const Color(0xFF7CF0C7),
              ),
              _verticalDivider(),
              _PulseMetricItem(
                label: 'Hujjatlar',
                value: docCount.toString(),
                dotColor: const Color(0xFF67E2B8),
              ),
              _verticalDivider(),
              _PulseMetricItem(
                label: 'Murojaatlar',
                value: consultAndLawyerCount.toString(),
                dotColor: const Color(0xFFFFC979),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildSearchBar() {
    return CupertinoTextField(
      controller: _searchController,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: Color(0xFFF2F5FA),
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      placeholder: 'Ariza, sud nomi, F.I.Sh. yoki #kod bo‘yicha izlash...',
      placeholderStyle: const TextStyle(
        color: Color(0xFF7F8E9F),
        fontSize: 13,
      ),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 15, right: 10),
        child: Icon(
          CupertinoIcons.search,
          color: Color(0xFF8A98AA),
          size: 17,
        ),
      ),
      suffix: _searchController.text.isEmpty
          ? null
          : GestureDetector(
              onTap: _searchController.clear,
              child: const Padding(
                padding: EdgeInsets.only(right: 13),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Color(0xFF738197),
                  size: 17,
                ),
              ),
            ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A293B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.095),
        ),
      ),
      cursorColor: const Color(0xFFADC4FF),
    );
  }

  Widget _buildFilterBar(List<ActivityEntry> allEntries) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final count = _countForFilter(allEntries, filter);
          final selected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF4C77D8).withValues(alpha: 0.30)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF88A9FF).withValues(alpha: 0.58)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFE5EEFF)
                            : Colors.white.withValues(alpha: 0.62),
                        fontSize: 11.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF88A9FF).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.50),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildGroupedTimeline(List<ActivityEntry> items) {
    final now = DateTime.now();
    final groups = <String, List<ActivityEntry>>{};
    for (final item in items) {
      groups.putIfAbsent(item.groupLabel(now), () => <ActivityEntry>[]).add(
        item,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((groupEntry) {
        final groupItems = groupEntry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      groupEntry.key.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${groupItems.length} ta amal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.36),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...List<Widget>.generate(groupItems.length, (index) {
                final item = groupItems[index];
                final isLast = index == groupItems.length - 1;
                return Dismissible(
                  key: ValueKey<String>(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A2331),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'O‘chirish',
                          style: TextStyle(
                            color: Color(0xFFFFB8C6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.trash_fill,
                          color: Color(0xFFFF9FB2),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _deleteEntryWithUndo(item),
                  child: _TimelineLedgerCard(
                    entry: item,
                    isLastInGroup: isLast,
                    onTap: () => _showEntryDossier(item),
                    onOpenFile: item.hasFile
                        ? () => _openDocumentFile(item.filePath!)
                        : null,
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildEmptyState(bool completelyEmpty) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
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
              CupertinoIcons.clock_fill,
              color: Color(0xFF9DBBFF),
              size: 25,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            completelyEmpty ? 'Tarix bo‘sh' : 'Faoliyat topilmadi',
            style: const TextStyle(
              color: Color(0xFFF0F4FB),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            completelyEmpty
                ? 'Yaratilgan da’vo arizalari, konsultatsiyalar va profil amallari avtomatik ravishda shu yerda aks etadi.'
                : 'Qidiruv so‘zini yoki kategoriya filtrini o‘zgartirib ko‘ring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (_onlyWithFiles || _selectedFilter != 'Barchasi') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _onlyWithFiles = false;
                  _selectedFilter = 'Barchasi';
                  _searchController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9DBBFF),
                side: BorderSide(
                  color: const Color(0xFF9DBBFF).withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 15),
              label: const Text('Filtrlarni tiklash'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteEntryWithUndo(ActivityEntry item) async {
    await ActivityHistoryRepository.instance.removeById(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            98 + MediaQuery.paddingOf(context).bottom,
          ),
          backgroundColor: const Color(0xFF1F3247),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text('Yozuv o‘chirildi: ${item.title}'),
          action: SnackBarAction(
            label: 'Qaytarish',
            textColor: const Color(0xFF83E4B6),
            onPressed: () {
              ActivityHistoryRepository.instance.restoreEntry(item);
            },
          ),
        ),
      );
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
              'Barcha faoliyat yozuvlari jurnaldan o‘chiriladi (Hujjatlar bo‘limidagi DOCX fayllaringiz saqlanib qoladi).',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ActivityHistoryRepository.instance.clearAll();
                if (!mounted) return;
                setState(() {
                  _selectedFilter = 'Barchasi';
                  _onlyWithFiles = false;
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

  Future<void> _openDocumentFile(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done || !mounted) return;
      _showToast(
        result.type == ResultType.noAppToOpen
            ? 'DOCX faylini ochadigan dastur topilmadi. Fayl Hujjatlar bo‘limida saqlangan.'
            : 'Faylni ochishda xatolik: ${result.message}',
      );
    } catch (_) {
      if (!mounted) return;
      _showToast('Hujjatni ochib bo‘lmadi.');
    }
  }

  void _showEntryDossier(ActivityEntry item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            24 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF122334),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: item.iconBackground,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: item.accentColor.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.accentColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: item.accentColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (item.referenceCode != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                item.referenceCode!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.44),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFFF4F7FD),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.dateFormatted} • Soat ${item.timeFormatted}',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (item.metadata.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      ...item.metadata.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 128,
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.46),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: Color(0xFFEAF1FC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (item.hasFile) ...[
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openDocumentFile(item.filePath!);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3E70E2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          CupertinoIcons.doc_text_viewfinder,
                          size: 17,
                        ),
                        label: const Text(
                          'DOCX faylni ochish',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: _DossierActionButton(
                      icon: CupertinoIcons.doc_on_clipboard,
                      label: 'Nusxalash',
                      onTap: () {
                        final buffer = StringBuffer()
                          ..writeln(
                            '${item.title} (${item.referenceCode ?? ''})',
                          )
                          ..writeln(
                            'Vaqt: ${item.dateFormatted}, ${item.timeFormatted}',
                          )
                          ..writeln(item.description);
                        for (final e in item.metadata.entries) {
                          buffer.writeln('${e.key}: ${e.value}');
                        }
                        Clipboard.setData(
                          ClipboardData(text: buffer.toString().trim()),
                        );
                        Navigator.pop(sheetContext);
                        _showToast('Ma’lumot nusxalandi ✓');
                      },
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DossierActionButton(
                      icon: CupertinoIcons.trash,
                      label: 'O‘chirish',
                      destructive: true,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _deleteEntryWithUndo(item);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            98 + MediaQuery.paddingOf(context).bottom,
          ),
          backgroundColor: const Color(0xFF23364C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}

class _PulseMetricItem extends StatelessWidget {
  const _PulseMetricItem({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5F8FF),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLedgerCard extends StatelessWidget {
  const _TimelineLedgerCard({
    required this.entry,
    required this.isLastInGroup,
    required this.onTap,
    this.onOpenFile,
  });

  final ActivityEntry entry;
  final bool isLastInGroup;
  final VoidCallback onTap;
  final VoidCallback? onOpenFile;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: entry.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.accentColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    entry.icon,
                    color: entry.accentColor,
                    size: 18,
                  ),
                ),
                if (!isLastInGroup)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            entry.accentColor.withValues(alpha: 0.30),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(17),
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.052),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.085),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: entry.accentColor.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.category.label,
                                style: TextStyle(
                                  color: entry.accentColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (entry.referenceCode != null) ...[
                              const SizedBox(width: 7),
                              Text(
                                entry.referenceCode!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              entry.timeFormatted,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF3F6FC),
                            fontSize: 13.8,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: entry.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              entry.statusLabel,
                              style: TextStyle(
                                color: entry.accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (onOpenFile != null)
                              GestureDetector(
                                onTap: onOpenFile,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3E70E2,
                                    ).withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF8AB0FF,
                                      ).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.doc_text_fill,
                                        size: 11,
                                        color: Color(0xFFB7D0FF),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'DOCX ochish',
                                        style: TextStyle(
                                          color: Color(0xFFDCE8FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
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
            ),
          ),
        ],
      ),
    );
  }
}

class _DossierActionButton extends StatelessWidget {
  const _DossierActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFFA4A4)
        : const Color(0xFF9DBBFF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
