import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../services/consultation_service.dart';
import '../../shared/user_profile.dart';

/// Complete 3-Step Client Online Consultation Booking Flow
/// Step 0: Advocate Selection (with real-time search & selection state)
/// Step 1: 7-Day Calendar -> 24-Hour Availability Grid -> 3x 19-Min Slots (1-min break)
/// Step 2: Review & Confirmation -> Atomic Supabase Booking -> Opens Chat
class ConsultationBookingPage extends StatefulWidget {
  const ConsultationBookingPage({
    super.key,
    this.preselectedAdvocate,
  });

  final LawyerDirectoryProfile? preselectedAdvocate;

  @override
  State<ConsultationBookingPage> createState() =>
      _ConsultationBookingPageState();
}

class _ConsultationBookingPageState extends State<ConsultationBookingPage> {
  // Unified YAN360 Legal-Tech Palette
  static const Color _bgSurface = Color(0xFFF5F8FC);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _lightBlue = Color(0xFFEAF3FC);
  static const Color _primaryBlue = Color(0xFF1677D2);
  static const Color _darkNavy = Color(0xFF102B50);
  static const Color _mutedSlate = Color(0xFF64748B);
  static const Color _borderSubtle = Color(0xFFDCE6F2);
  static const Color _availableGreen = Color(0xFF10B981);
  static const Color _availableSoft = Color(0xFFE8F8F0);
  static const Color _availableText = Color(0xFF0F766E);
  static const Color _unavailableBg = Color(0xFFE8EDF4);
  static const Color _rose = Color(0xFFE11D48);
  static const Color _roseSoft = Color(0xFFFFF1F2);

  int _step = 0; // 0: Advocate picker, 1: Date & Time, 2: Review & Confirm
  bool _isLoadingAdvocates = true;
  bool _isBooking = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LawyerDirectoryProfile> _advocates = <LawyerDirectoryProfile>[];
  LawyerDirectoryProfile? _selectedAdvocate;

  late final List<DateTime> _sevenDays;
  int _selectedDayIndex = 0;
  int? _selectedHour;
  int? _selectedSlotIndex;
  Timer? _clockRefreshTimer;

  @override
  void initState() {
    super.initState();
    _sevenDays = ConsultationSlotMath.upcomingSevenDays();
    if (widget.preselectedAdvocate != null) {
      _selectedAdvocate = widget.preselectedAdvocate;
      _step = 1;
    }
    ConsultationRepository.instance.ensureInitialized();
    _loadAdvocates();
    _clockRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvocates() async {
    void applyList(List<LawyerDirectoryProfile> list) {
      if (!mounted) return;
      setState(() {
        _advocates = List<LawyerDirectoryProfile>.from(list);
        if (_selectedAdvocate != null) {
          final updated = _advocates.where(
            (a) => a.id == _selectedAdvocate!.id,
          );
          if (updated.isNotEmpty) {
            _selectedAdvocate = updated.first;
          } else {
            _advocates.insert(0, _selectedAdvocate!);
          }
        }
        _isLoadingAdvocates = false;
      });
    }

    final cached = YanRoleDataCatalog.registeredLawyers.value;
    if (cached.isNotEmpty) {
      applyList(cached);
    } else if (mounted) {
      setState(() => _isLoadingAdvocates = true);
    }

    try {
      final hook = YanRoleDataCatalog.refreshRegisteredLawyers;
      if (hook != null) {
        final fresh = await hook();
        if (fresh.isNotEmpty) {
          applyList(fresh);
          return;
        }
      }

      if (cached.isEmpty) {
        final rows = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('role', 'advocate');

        final parsed = <LawyerDirectoryProfile>[];
        for (final item in rows) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id']?.toString() ?? '';
          final fullName = (map['full_name']?.toString() ?? '').trim();
          if (id.isEmpty || fullName.isEmpty) continue;
          parsed.add(LawyerDirectoryProfile.fromSupabaseMap(map));
        }
        applyList(parsed);
      }
    } catch (e) {
      debugPrint('Loading advocates for consultation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAdvocates = false);
    }
  }

  String get _selectedDateKey =>
      ConsultationSlotMath.dateKeyOf(_sevenDays[_selectedDayIndex]);

  void _selectAdvocate(LawyerDirectoryProfile advocate) {
    HapticFeedback.selectionClick();
    final changed = _selectedAdvocate?.id != advocate.id;
    setState(() {
      _selectedAdvocate = advocate;
      if (changed) {
        _selectedDayIndex = 0;
        _selectedHour = null;
        _selectedSlotIndex = null;
      }
    });
  }

  void _proceedFromStep0() {
    if (_selectedAdvocate == null) return;
    HapticFeedback.selectionClick();
    ConsultationRepository.instance.refreshAll();
    setState(() => _step = 1);
  }

  Future<void> _proceedFromStep1() async {
    final adv = _selectedAdvocate;
    final hour = _selectedHour;
    final slot = _selectedSlotIndex;
    if (adv == null || hour == null || slot == null) return;

    HapticFeedback.selectionClick();
    await ConsultationRepository.instance.refreshAll();
    if (!mounted) return;

    final repo = ConsultationRepository.instance;
    final now = DateTime.now();
    final dateKey = _selectedDateKey;
    final stillUnavailable =
        repo.isDayBlocked(adv.id, dateKey) ||
        repo.isHourBlocked(adv.id, dateKey, hour) ||
        repo.isSlotPast(dateKey, hour, slot, now) ||
        repo.isSlotBlocked(adv.id, dateKey, hour, slot) ||
        repo.findBookingForSlot(adv.id, dateKey, hour, slot) != null;

    if (stillUnavailable) {
      setState(() => _selectedSlotIndex = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ushbu vaqt oralig‘i band bo‘lib qoldi. Iltimos, boshqa bo‘sh vaqtni tanlang.',
            ),
            backgroundColor: _rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _step = 2);
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    if (_step == 2) {
      setState(() => _step = 1);
    } else if (_step == 1 && widget.preselectedAdvocate == null) {
      setState(() => _step = 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmAndBook() async {
    final advocate = _selectedAdvocate;
    final hour = _selectedHour;
    final slot = _selectedSlotIndex;
    if (advocate == null || hour == null || slot == null || _isBooking) return;

    HapticFeedback.mediumImpact();
    setState(() => _isBooking = true);

    final result = await ConsultationRepository.instance.bookConsultation(
      clientProfile: userProfile.value,
      advocate: advocate,
      dateKey: _selectedDateKey,
      hourValue: hour,
      slotIndex: slot,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (!result.success || result.booking == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Vaqtni band qilishda xatolik yuz berdi.',
            ),
            backgroundColor: _rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      setState(() {
        _selectedSlotIndex = null;
        _step = 1;
      });
      return;
    }

    final booking = result.booking!;
    await ActivityHistoryRepository.instance.record(
      title: 'Video konsultatsiya band qilindi (${advocate.fullName})',
      description:
          '${booking.friendlyDateLabel} • ${booking.timeRangeLabel} (19 daqiqa)',
      category: ActivityCategory.consultation,
      statusLabel: 'Band qilindi',
      referenceCode: booking.id,
      metadata: <String, String>{
        'Advokat': advocate.fullName,
        'Sana': booking.friendlyDateLabel,
        'Vaqt': booking.timeRangeLabel,
        'Davomiyligi': '19 daqiqa (1 daqiqa tanaffus)',
        'Kod': booking.id,
      },
    );

    if (!mounted) return;
    await AdvocateClientChatPage.sendConsultationBookingAndOpenChat(
      context: context,
      advocate: advocate,
      clientProfile: userProfile.value,
      booking: booking,
    );
  }

  BoxDecoration _surfaceCardDecoration({
    double radius = 20,
    bool highlighted = false,
  }) => BoxDecoration(
    color: highlighted ? const Color(0xFFF3F8FF) : _cardWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: highlighted ? _primaryBlue : _borderSubtle,
      width: highlighted ? 1.5 : 1.0,
    ),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x0A102B50),
        blurRadius: 16,
        offset: Offset(0, 5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSurface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ConsultationHeader(
              step: _step,
              onBack: _handleBack,
            ),
            Expanded(
              child: ValueListenableBuilder<List<AdvocateBlockedSlot>>(
                valueListenable: ConsultationRepository.instance.blockedSlots,
                builder: (context, _, __) {
                  return ValueListenableBuilder<List<ConsultationBooking>>(
                    valueListenable:
                        ConsultationRepository.instance.consultations,
                    builder: (context, _, __) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _step == 0
                            ? _buildStep0AdvocatePicker()
                            : _step == 1
                            ? _buildStep1CalendarPicker()
                            : _buildStep2ReviewScreen(),
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 1: ADVOCATE SELECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStep0AdvocatePicker() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _advocates.where((a) {
      if (query.isEmpty) return true;
      return a.fullName.toLowerCase().contains(query) ||
          a.specialization.toLowerCase().contains(query) ||
          a.region.toLowerCase().contains(query);
    }).toList();

    return Column(
      key: const ValueKey<String>('step-0'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              cursorColor: _primaryBlue,
              style: const TextStyle(
                color: _darkNavy,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: _cardWhite,
                hintText: 'Advokat ismi, soha yoki viloyat bo‘yicha qidiring...',
                hintStyle: const TextStyle(
                  color: _mutedSlate,
                  fontSize: 13.4,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _primaryBlue,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _mutedSlate,
                        ),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _borderSubtle, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingAdvocates
              ? const Center(
                  child: CupertinoActivityIndicator(
                    radius: 14,
                    color: _primaryBlue,
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: _lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_search_rounded,
                            size: 30,
                            color: _primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Advokat topilmadi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Qidiruv so‘zini o‘zgartiring yoki ro‘yxatni yangilang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _mutedSlate),
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: _loadAdvocates,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: _primaryBlue,
                          ),
                          label: const Text(
                            'Qayta yuklash',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                  children: <Widget>[
                    ...filtered.map((adv) {
                      final isSelected = _selectedAdvocate?.id == adv.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LawyerSelectionCard(
                          advocate: adv,
                          selected: isSelected,
                          onTap: () => _selectAdvocate(adv),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _lightBlue.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _borderSubtle),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            size: 19,
                            color: _primaryBlue,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Advokat tanlashda yordam kerakmi?',
                                  style: TextStyle(
                                    color: _darkNavy,
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Mutaxassislik, viloyat yoki reyting bo‘yicha qidirib, o‘zingizga mos advokatni tanlang.',
                                  style: TextStyle(
                                    color: _mutedSlate,
                                    fontSize: 12.2,
                                    height: 1.4,
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
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 2: DATE & TIME SELECTION (7-DAY CALENDAR + 24-HOUR GRID + 3x 19-MIN)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStep1CalendarPicker() {
    final adv = _selectedAdvocate!;
    final repo = ConsultationRepository.instance;
    final dateKey = _selectedDateKey;
    final dayBlocked = repo.isDayBlocked(adv.id, dateKey);
    final now = DateTime.now();
    final selectedDate = _sevenDays[_selectedDayIndex];

    return ListView(
      key: const ValueKey<String>('step-1'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: <Widget>[
        _SelectedLawyerSummary(
          advocate: adv,
          onChangeTap: widget.preselectedAdvocate == null
              ? () => setState(() => _step = 0)
              : null,
        ),
        const SizedBox(height: 14),

        // Calendar & Time Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceCardDecoration(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Date Selector Header
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _primaryBlue,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Sanani tanlang',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _darkNavy,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${ConsultationSlotMath.monthName(selectedDate)} ${selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal 7-Day Calendar
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sevenDays.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final d = _sevenDays[idx];
                    final dKey = ConsultationSlotMath.dateKeyOf(d);
                    final isBlocked = repo.isDayBlocked(adv.id, dKey);
                    final isSelected = idx == _selectedDayIndex;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDayIndex = idx;
                          _selectedHour = null;
                          _selectedSlotIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 58,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue
                              : isBlocked
                              ? _unavailableBg
                              : _bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue
                                : isBlocked
                                ? const Color(0xFFD5DCE6)
                                : _borderSubtle,
                            width: isSelected ? 1.4 : 1,
                          ),
                          boxShadow: isSelected
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: _primaryBlue.withValues(alpha: 0.24),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              idx == 0
                                  ? 'BUGUN'
                                  : ConsultationSlotMath.shortWeekday(d),
                              style: TextStyle(
                                fontSize: 9.8,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : isBlocked
                                    ? const Color(0xFF94A3B8)
                                    : _mutedSlate,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : isBlocked
                                    ? const Color(0xFF94A3B8)
                                    : _darkNavy,
                                decoration: isBlocked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              )
                            else
                              const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 2. 24-Hour Grid Header
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 16,
                    color: _primaryBlue,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Soatni tanlang (24 soat)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _darkNavy,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Toshkent vaqti',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _mutedSlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (dayBlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _roseSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _rose.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.event_busy_rounded, color: _rose, size: 19),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Advokat ushbu kunni band deb belgilagan. Iltimos, boshqa kunni tanlang.',
                          style: TextStyle(
                            fontSize: 12.4,
                            fontWeight: FontWeight.w600,
                            color: _rose,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 24,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.68,
                  ),
                  itemBuilder: (context, hour) {
                    final availCount = repo.countAvailableSlotsForHour(
                      adv.id,
                      dateKey,
                      hour,
                      now,
                    );
                    final isHourBlocked = repo.isHourBlocked(
                      adv.id,
                      dateKey,
                      hour,
                    );
                    final isDisabled = availCount == 0 || isHourBlocked;
                    final isSelected = _selectedHour == hour;

                    return GestureDetector(
                      onTap: isDisabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedHour = hour;
                                _selectedSlotIndex = null;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue
                              : isDisabled
                              ? _unavailableBg
                              : _availableSoft,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue
                                : isDisabled
                                ? const Color(0xFFDDE3EC)
                                : _availableGreen.withValues(alpha: 0.35),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              ConsultationSlotMath.formatHour(hour),
                              style: TextStyle(
                                fontSize: 13.2,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : isDisabled
                                    ? const Color(0xFF94A3B8)
                                    : _darkNavy,
                              ),
                            ),
                            Text(
                              isHourBlocked
                                  ? 'Band'
                                  : availCount == 0
                                  ? 'Band'
                                  : '$availCount/3 bo‘sh',
                              style: TextStyle(
                                fontSize: 9.6,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : isDisabled
                                    ? const Color(0xFF94A3B8)
                                    : _availableText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 3. Detailed 19-Minute Sub-Slots (00-19, 20-39, 40-59)
              if (!dayBlocked && _selectedHour != null) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(height: 1, color: _borderSubtle),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.timelapse_rounded,
                      size: 17,
                      color: _primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ConsultationSlotMath.formatHour(_selectedHour!)} soatidagi 19 daqiqalik vaqtlar:',
                      style: const TextStyle(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w800,
                        color: _darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List<Widget>.generate(3, (slotIdx) {
                    final rangeLabel = ConsultationSlotMath.formatSlotRange(
                      _selectedHour!,
                      slotIdx,
                    );
                    final isPast = repo.isSlotPast(
                      dateKey,
                      _selectedHour!,
                      slotIdx,
                      now,
                    );
                    final isBlocked = repo.isSlotBlocked(
                      adv.id,
                      dateKey,
                      _selectedHour!,
                      slotIdx,
                    );
                    final isBooked =
                        repo.findBookingForSlot(
                          adv.id,
                          dateKey,
                          _selectedHour!,
                          slotIdx,
                        ) !=
                        null;
                    final disabled = isPast || isBlocked || isBooked;
                    final selected = _selectedSlotIndex == slotIdx;

                    final statusLabel = isBooked
                        ? 'Band'
                        : isBlocked
                        ? 'Yopiq'
                        : isPast
                        ? 'O‘tgan'
                        : 'Bo‘sh';

                    return Expanded(
                      child: GestureDetector(
                        onTap: disabled
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedSlotIndex = slotIdx);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: slotIdx < 2 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? _primaryBlue
                                : disabled
                                ? _unavailableBg
                                : _availableSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? _primaryBlue
                                  : disabled
                                  ? const Color(0xFFDDE3EC)
                                  : _availableGreen.withValues(alpha: 0.4),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                rangeLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : disabled
                                      ? const Color(0xFF94A3B8)
                                      : _darkNavy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                statusLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.2,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : disabled
                                      ? const Color(0xFF94A3B8)
                                      : _availableText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],

              // Selected Time Summary Strip
              if (_selectedHour != null && _selectedSlotIndex != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 19,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${ConsultationSlotMath.formatFriendlyDate(selectedDate)} • ${ConsultationSlotMath.formatSlotRange(_selectedHour!, _selectedSlotIndex!)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '19 daqiqa (+1 daq tanaffus) • Toshkent vaqti',
                              style: TextStyle(
                                fontSize: 11.4,
                                fontWeight: FontWeight.w500,
                                color: _mutedSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 19-Minute Rule Explanation + Legend
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderSubtle),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: _primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Har bir konsultatsiya 19 daqiqa davom etadi. Keyingi uchrashuvgacha 1 daqiqalik tanaffus ajratiladi.',
                        style: TextStyle(
                          fontSize: 11.8,
                          height: 1.4,
                          color: _darkNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _SlotLegendDot(color: _primaryBlue, label: 'Tanlangan'),
                  _SlotLegendDot(
                    color: _availableSoft,
                    borderColor: _availableGreen,
                    label: 'Bo‘sh',
                  ),
                  _SlotLegendDot(
                    color: _unavailableBg,
                    borderColor: Color(0xFFCBD5E1),
                    label: 'Band / o‘tgan',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 3: BOOKING CONFIRMATION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStep2ReviewScreen() {
    final adv = _selectedAdvocate!;
    final date = _sevenDays[_selectedDayIndex];
    final range = ConsultationSlotMath.formatSlotRange(
      _selectedHour!,
      _selectedSlotIndex!,
    );

    return ListView(
      key: const ValueKey<String>('step-2'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: <Widget>[
        _SelectedLawyerSummary(
          advocate: adv,
          onChangeTap: widget.preselectedAdvocate == null
              ? () => setState(() => _step = 0)
              : null,
        ),
        const SizedBox(height: 18),
        const Text(
          'Rejangizni tasdiqlang',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: _darkNavy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tanlangan advokat, sana va 19 daqiqalik vaqt oralig‘ini yana bir bor tekshiring.',
          style: TextStyle(fontSize: 13, color: _mutedSlate, height: 1.4),
        ),
        const SizedBox(height: 14),

        // Appointment Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceCardDecoration(radius: 22),
          child: Column(
            children: <Widget>[
              _buildReviewRow(
                icon: Icons.person_outline_rounded,
                label: 'Advokat',
                value: adv.fullName,
                onEdit: widget.preselectedAdvocate == null
                    ? () => setState(() => _step = 0)
                    : null,
              ),
              const Divider(height: 20, color: _borderSubtle),
              _buildReviewRow(
                icon: Icons.calendar_today_rounded,
                label: 'Sana',
                value: ConsultationSlotMath.formatFriendlyDate(date),
                onEdit: () => setState(() => _step = 1),
              ),
              const Divider(height: 20, color: _borderSubtle),
              _buildReviewRow(
                icon: Icons.access_time_filled_rounded,
                label: 'Toshkent vaqti',
                value: range,
                valueColor: _primaryBlue,
                onEdit: () => setState(() => _step = 1),
              ),
              const Divider(height: 20, color: _borderSubtle),
              _buildReviewRow(
                icon: Icons.timelapse_rounded,
                label: 'Davomiyligi',
                value: '19 daqiqa (+1 daq tanaffus)',
              ),
              const Divider(height: 20, color: _borderSubtle),
              _buildReviewRow(
                icon: Icons.videocam_rounded,
                label: 'Format',
                value: 'Jonli Video Konsultatsiya',
                valueColor: _availableGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Consultation Information Panel
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderSubtle),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                color: _primaryBlue,
                size: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Video konsultatsiya belgilangan vaqt oralig‘ida faollashadi. Vaqt tugagach, videoaloqa avtomatik yakunlanadi.',
                  style: TextStyle(
                    fontSize: 12.4,
                    height: 1.45,
                    color: _darkNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onEdit,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: _primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedSlate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? _darkNavy,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tahrirlash',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlue,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FIXED BOTTOM ACTION BAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildBottomActionBar() {
    final canStep0 = _step == 0 && _selectedAdvocate != null;
    final canStep1 =
        _step == 1 && _selectedHour != null && _selectedSlotIndex != null;
    final isReview = _step == 2;
    final enabled = isReview || canStep0 || canStep1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: _cardWhite,
        border: Border(top: BorderSide(color: _borderSubtle)),
      ),
      child: Row(
        children: <Widget>[
          if (isReview) ...<Widget>[
            GestureDetector(
              onTap: _isBooking ? null : () => setState(() => _step = 1),
              child: Container(
                width: 50,
                height: 52,
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _darkNavy,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: !enabled || _isBooking
                    ? null
                    : () {
                        if (_step == 0) {
                          _proceedFromStep0();
                        } else if (_step == 1) {
                          _proceedFromStep1();
                        } else {
                          _confirmAndBook();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _unavailableBg,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            isReview ? 'Uchrashuvni tasdiqlash' : 'Davom etish',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isReview
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE BOOKING COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _ConsultationHeader extends StatelessWidget {
  const _ConsultationHeader({
    required this.step,
    required this.onBack,
  });

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final subtitle = step == 0
        ? '1-qadam · Advokatni tanlang'
        : step == 1
        ? '2-qadam · Kun va 19 daqiqalik vaqtni tanlang'
        : '3-qadam · Rejangizni tasdiqlang';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDCE6F2)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF102B50),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Onlayn Konsultatsiya',
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102B50),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1677D2),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCE6F2)),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF1677D2),
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(3, (i) {
              final active = i <= step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active
                        ? const Color(0xFF1677D2)
                        : const Color(0xFFDCE6F2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BookingAvatar extends StatelessWidget {
  const _BookingAvatar({
    required this.advocate,
    this.size = 54,
  });

  final LawyerDirectoryProfile advocate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b64 = advocate.avatarBase64.trim();
    final url = advocate.avatarUrl.trim();
    Widget inner = _initials();
    if (b64.isNotEmpty) {
      try {
        final clean = b64.contains(',') ? b64.split(',').last.trim() : b64;
        inner = Image.memory(
          base64Decode(clean),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initials(),
        );
      } catch (_) {
        inner = _initials();
      }
    } else if (url.isNotEmpty) {
      inner = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1677D2),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        advocate.initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LawyerSelectionCard extends StatelessWidget {
  const _LawyerSelectionCard({
    required this.advocate,
    required this.selected,
    required this.onTap,
  });

  final LawyerDirectoryProfile advocate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = advocate.specialization.trim();
    final region = advocate.region.trim();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1677D2)
                : const Color(0xFFDCE6F2),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x09102B50),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _BookingAvatar(advocate: advocate, size: 54),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          advocate.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102B50),
                          ),
                        ),
                      ),
                      if (advocate.isVerifiedPartner) ...<Widget>[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF1677D2),
                        ),
                      ],
                    ],
                  ),
                  if (spec.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            spec,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (region.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            region,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7FC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              advocate.feedbackCount > 0
                                  ? '${advocate.rating.toStringAsFixed(1)} (${advocate.feedbackCount} izoh)'
                                  : 'Yangi',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF102B50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.videocam_rounded,
                              size: 12,
                              color: Color(0xFF1677D2),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '19 daq video',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1677D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Mavjud',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1677D2)
                    : const Color(0xFFEAF3FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected
                    ? Icons.check_rounded
                    : Icons.chevron_right_rounded,
                size: 17,
                color: selected ? Colors.white : const Color(0xFF1677D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLawyerSummary extends StatelessWidget {
  const _SelectedLawyerSummary({
    required this.advocate,
    this.onChangeTap,
  });

  final LawyerDirectoryProfile advocate;
  final VoidCallback? onChangeTap;

  @override
  Widget build(BuildContext context) {
    final spec = advocate.specialization.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _BookingAvatar(advocate: advocate, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        advocate.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102B50),
                        ),
                      ),
                    ),
                    if (advocate.isVerifiedPartner) ...<Widget>[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Color(0xFF1677D2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    advocate.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1677D2),
                    ),
                  ),
                ),
                if (spec.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spec,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onChangeTap != null) ...<Widget>[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onChangeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Almashtirish',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1677D2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotLegendDot extends StatelessWidget {
  const _SlotLegendDot({
    required this.color,
    required this.label,
    this.borderColor,
  });

  final Color color;
  final String label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}