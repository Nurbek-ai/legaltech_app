import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../services/consultation_service.dart';
import '../../shared/user_profile.dart';

/// Complete 3-Step Client Konsultatsiya Flow (Apple-Clean White & Sky-Blue Design):
/// Step 0: Select a verified Advocate from Supabase
/// Step 1: Advocate Profile + Biography + 7-Day Calendar -> 24-Hour Grid -> 3x 19-Min Slots (1-min break)
/// Step 2: Bright Airy Review & Edit Screen -> Atomic Supabase Booking -> Opens Chat with Live Notification Card
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
  // Apple-Clean Bright Sky-Blue & Pure White Palette (matching YAN360 Home & HydraCare)
  static const Color _bgTop = Color(0xFFE7F3FF);
  static const Color _bgMid = Color(0xFFF6FAFF);
  static const Color _bgBottom = Color(0xFFFFFFFF);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _softIce = Color(0xFFF0F7FF);
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _skyBlue = Color(0xFF3B9EFF);
  static const Color _inkNavy = Color(0xFF0B1F3A);
  static const Color _mutedSlate = Color(0xFF64748B);
  static const Color _borderBlue = Color(0xFFDCEBFF);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldSoft = Color(0xFFECFDF5);
  static const Color _rose = Color(0xFFE11D48);
  static const Color _roseSoft = Color(0xFFFFF1F2);
  static const Color _gold = Color(0xFFF59E0B);

  int _step = 0; // 0: Advocate picker, 1: Profile & Calendar, 2: Review & Confirm
  bool _isLoadingAdvocates = true;
  bool _isBooking = false;
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
    _loadAdvocatesFromSupabase();
    _clockRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdvocatesFromSupabase() async {
    if (mounted) setState(() => _isLoadingAdvocates = true);
    try {
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
        final spec = (map['specialization']?.toString() ?? '').trim();
        final region = (map['region']?.toString() ?? '').trim();
        final license = (map['license_number']?.toString() ?? '').trim();
        final bio = (map['bio']?.toString() ?? '').trim();

        parsed.add(
          LawyerDirectoryProfile(
            id: id,
            fullName: fullName,
            title: 'BOSH ADVOKAT • YAN LEGAL FIRM',
            region: region.isEmpty ? 'Toshkent shahri' : region,
            specialization: spec.isEmpty ? 'Barcha yuridik sohalar' : spec,
            experienceYears: (map['experience_years'] as num?)?.toInt() ?? 5,
            rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
            feedbackCount: (map['feedback_count'] as num?)?.toInt() ?? 1,
            wonCasesCount: (map['won_cases'] as num?)?.toInt() ?? 24,
            consultationPriceUzs:
                (map['consultation_price'] as num?)?.toInt() ?? 99000,
            contractMonthlyNote: 'Rasmiy YAN360 advokati',
            licenseNumber: license.isEmpty ? 'Tasdiqlangan' : license,
            phone: map['phone']?.toString() ?? '+998',
            assistantName: '-',
            assistantRole: '',
            assistantPhone: '',
            bio: bio.isNotEmpty
                ? bio
                : '“YAN Legal Firm” rasmiy litsenziyaga ega advokati. Mijozlarning huquqiy masalalarini 19 daqiqalik onlayn video konsultatsiya orqali aniq va qonuniy hal etishga ixtisoslashgan.',
            feedbacks: const <LawyerFeedbackItem>[],
            isVerifiedPartner: true,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _advocates = parsed;
          if (_selectedAdvocate != null &&
              !_advocates.any((a) => a.id == _selectedAdvocate!.id)) {
            _advocates.insert(0, _selectedAdvocate!);
          }
        });
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
    setState(() {
      _selectedAdvocate = advocate;
      _selectedDayIndex = 0;
      _selectedHour = null;
      _selectedSlotIndex = null;
      _step = 1;
    });
    ConsultationRepository.instance.refreshAll();
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

  BoxDecoration _appleCardDecoration({double radius = 24}) => BoxDecoration(
    color: _cardWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _borderBlue, width: 1),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: _brandBlue.withValues(alpha: 0.06),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: <double>[0.0, 0.34, 1.0],
            colors: <Color>[_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopHeader(),
              _buildStepProgressBar(),
              Expanded(
                child: ValueListenableBuilder<List<AdvocateBlockedSlot>>(
                  valueListenable: ConsultationRepository.instance.blockedSlots,
                  builder: (context, _, __) {
                    return ValueListenableBuilder<List<ConsultationBooking>>(
                      valueListenable:
                          ConsultationRepository.instance.consultations,
                      builder: (context, _, __) {
                        if (_step == 0) return _buildStep0AdvocatePicker();
                        if (_step == 1) return _buildStep1CalendarPicker();
                        return _buildStep2ReviewScreen();
                      },
                    );
                  },
                ),
              ),
              if (_step == 1 || _step == 2) _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final subtitle = _step == 0
        ? '1-qadam • Advokatni tanlang'
        : _step == 1
        ? '2-qadam • Kun va 19 daqiqalik vaqtni tanlang'
        : '3-qadam • Rejangizni tasdiqlang';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: _borderBlue),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _brandBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _inkNavy,
                size: 18,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _inkNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    color: _brandBlue,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: _borderBlue),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _brandBlue.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _brandBlue,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: List<Widget>.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4.5,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: active
                    ? const LinearGradient(
                        colors: <Color>[_brandBlue, _skyBlue],
                      )
                    : null,
                color: active ? null : _borderBlue,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep0AdvocatePicker() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _advocates.where((a) {
      if (query.isEmpty) return true;
      return a.fullName.toLowerCase().contains(query) ||
          a.specialization.toLowerCase().contains(query) ||
          a.region.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderBlue),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _brandBlue.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: _inkNavy, fontSize: 14.2),
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(
                  CupertinoIcons.search,
                  color: _brandBlue,
                  size: 19,
                ),
                hintText: 'Advokat ismi, soha yoki viloyat bo‘yicha qidirish...',
                hintStyle: TextStyle(
                  color: _mutedSlate,
                  fontSize: 13.5,
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
                    color: _brandBlue,
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
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: _softIce,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_2_fill,
                            size: 34,
                            color: _brandBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Rasmiy advokatlar topilmadi',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: _inkNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Yangi advokatlar ro‘yxatdan o‘tgach shu yerda avtomatik ko‘rinadi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: _mutedSlate,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadAdvocatesFromSupabase,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: _brandBlue,
                          ),
                          label: const Text(
                            'Qayta yuklash',
                            style: TextStyle(
                              color: _brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final adv = filtered[index];
                    return GestureDetector(
                      onTap: () => _selectAdvocate(adv),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: _appleCardDecoration(radius: 24),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[_brandBlue, _skyBlue],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.24),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                adv.initials,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          adv.fullName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15.8,
                                            fontWeight: FontWeight.w900,
                                            color: _inkNavy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: _brandBlue,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${adv.specialization} • ${adv.region}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.4,
                                      color: _mutedSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: _gold,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              adv.rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _softIce,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: const Text(
                                          '19 daq video',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: _brandBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: _softIce,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: _brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdvocateProfileCard(
    LawyerDirectoryProfile adv, {
    bool showChangeButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _appleCardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[_brandBlue, _skyBlue],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _brandBlue.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  adv.initials,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      adv.fullName,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: _inkNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: _softIce,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        adv.title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: _brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: _emerald,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            adv.specialization,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w600,
                              color: _mutedSlate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showChangeButton)
                GestureDetector(
                  onTap: () => setState(() => _step = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _softIce,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderBlue),
                    ),
                    child: const Text(
                      'Almashtirish',
                      style: TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w800,
                        color: _brandBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _borderBlue),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: _brandBlue,
              ),
              SizedBox(width: 6),
              Text(
                'Yurist biografiyasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _inkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            adv.bio,
            style: const TextStyle(
              fontSize: 12.8,
              height: 1.48,
              color: _mutedSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1CalendarPicker() {
    final adv = _selectedAdvocate!;
    final repo = ConsultationRepository.instance;
    final dateKey = _selectedDateKey;
    final dayBlocked = repo.isDayBlocked(adv.id, dateKey);
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        _buildAdvocateProfileCard(
          adv,
          showChangeButton: widget.preselectedAdvocate == null,
        ),
        const SizedBox(height: 18),
        const Text(
          'Sizga qulay kun va vaqtni tanlang',
          style: TextStyle(
            fontSize: 20.5,
            fontWeight: FontWeight.w900,
            color: _inkNavy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Har bir soat 3 ta 19 daqiqalik qismga bo‘lingan (advokat uchun 1 daqiqa tanaffus bilan).',
          style: TextStyle(
            fontSize: 12.6,
            color: _mutedSlate,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Luminous Apple-Clean Calendar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _appleCardDecoration(radius: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. 7-Day Selector (Today + Upcoming 6 Days)
              Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _softIce,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: _brandBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sana tanlang',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _inkNavy,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _softIce,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${ConsultationSlotMath.monthName(_sevenDays[_selectedDayIndex]).toUpperCase()} ${_sevenDays[_selectedDayIndex].year}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
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
                        duration: const Duration(milliseconds: 180),
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[_brandBlue, _skyBlue],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : isBlocked
                              ? _roseSoft
                              : _softIce,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? _brandBlue
                                : isBlocked
                                ? _rose.withValues(alpha: 0.35)
                                : _borderBlue,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
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
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : isBlocked
                                    ? _rose
                                    : _mutedSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? Colors.white
                                    : isBlocked
                                    ? _rose.withValues(alpha: 0.55)
                                    : _inkNavy,
                                decoration: isBlocked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: isSelected ? 16 : 6,
                              height: 3,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : isBlocked
                                    ? _rose
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 2. 24-Hour Grid (00:00 - 23:00)
              Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _softIce,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      size: 16,
                      color: _brandBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Soatni tanlang (24 soat)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _inkNavy,
                    ),
                  ),
                  const Spacer(),
                  const Text(
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _rose.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.event_busy_rounded, color: _rose, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Advokat ushbu kunni band deb yopgan. Iltimos, yuqoridan boshqa kunni tanlang.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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
                    childAspectRatio: 1.72,
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
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: <Color>[_brandBlue, _skyBlue],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : isDisabled
                              ? const Color(0xFFF8FAFC)
                              : _softIce,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _brandBlue
                                : isDisabled
                                ? const Color(0xFFE2E8F0)
                                : _borderBlue,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.25),
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
                              ConsultationSlotMath.formatHour(hour),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : isDisabled
                                    ? const Color(0xFF94A3B8)
                                    : _inkNavy,
                              ),
                            ),
                            Text(
                              isHourBlocked
                                  ? 'Yopiq'
                                  : availCount == 0
                                  ? 'Bo‘sh emas'
                                  : '$availCount/3 bo‘sh',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : isDisabled
                                    ? const Color(0xFFCBD5E1)
                                    : _brandBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 3. 3-Part 19-Minute Sub-Slot Selector below selected hour
              if (!dayBlocked && _selectedHour != null) ...<Widget>[
                const SizedBox(height: 18),
                const Divider(height: 1, color: _borderBlue),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.timelapse_rounded,
                      size: 18,
                      color: _brandBlue,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${ConsultationSlotMath.formatHour(_selectedHour!)} soatidagi 3 ta qism:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _inkNavy,
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
                        ? 'Yopilgan'
                        : isPast
                        ? 'O‘tgan'
                        : 'Bo‘sh • 19 daq';

                    return Expanded(
                      child: GestureDetector(
                        onTap: disabled
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedSlotIndex = slotIdx);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: EdgeInsets.only(right: slotIdx < 2 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: <Color>[_brandBlue, _skyBlue],
                                  )
                                : null,
                            color: selected
                                ? null
                                : (isBooked || isBlocked)
                                ? _roseSoft
                                : isPast
                                ? const Color(0xFFF8FAFC)
                                : _emeraldSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? _brandBlue
                                  : (isBooked || isBlocked)
                                  ? _rose.withValues(alpha: 0.35)
                                  : isPast
                                  ? const Color(0xFFE2E8F0)
                                  : _emerald.withValues(alpha: 0.4),
                              width: selected ? 1.6 : 1,
                            ),
                            boxShadow: selected
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: _brandBlue.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                rangeLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? Colors.white
                                      : disabled
                                      ? const Color(0xFF94A3B8)
                                      : _inkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.92)
                                      : (isBooked || isBlocked)
                                      ? _rose
                                      : isPast
                                      ? const Color(0xFFCBD5E1)
                                      : _emerald,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2ReviewScreen() {
    final adv = _selectedAdvocate!;
    final date = _sevenDays[_selectedDayIndex];
    final range = ConsultationSlotMath.formatSlotRange(
      _selectedHour!,
      _selectedSlotIndex!,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        _buildAdvocateProfileCard(
          adv,
          showChangeButton: widget.preselectedAdvocate == null,
        ),
        const SizedBox(height: 18),
        const Text(
          'Rejangizni tasdiqlang',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _inkNavy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tanlangan advokat, sana va 19 daqiqalik vaqt oralig‘ini yana bir bor tekshiring.',
          style: TextStyle(fontSize: 13, color: _mutedSlate),
        ),
        const SizedBox(height: 14),

        // Review Summary Card (Clean Apple White + Edit Pills)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _appleCardDecoration(radius: 26),
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
              const Divider(height: 22, color: _borderBlue),
              _buildReviewRow(
                icon: Icons.calendar_today_rounded,
                label: 'Sana',
                value: ConsultationSlotMath.formatFriendlyDate(date),
                onEdit: () => setState(() => _step = 1),
              ),
              const Divider(height: 22, color: _borderBlue),
              _buildReviewRow(
                icon: Icons.access_time_filled_rounded,
                label: 'Toshkent vaqti',
                value: range,
                valueColor: _brandBlue,
                onEdit: () => setState(() => _step = 1),
              ),
              const Divider(height: 22, color: _borderBlue),
              _buildReviewRow(
                icon: Icons.timelapse_rounded,
                label: 'Davomiyligi',
                value: '19 daqiqa (+1 daq tanaffus)',
              ),
              const Divider(height: 22, color: _borderBlue),
              _buildReviewRow(
                icon: Icons.videocam_rounded,
                label: 'Format',
                value: 'E2EE Jonli Video Konsultatsiya',
                valueColor: _emerald,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Soft Ice-Blue Auto-Stop Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _softIce,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderBlue),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                color: _brandBlue,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Diqqat: “Video qo‘ng‘iroqni boshlash” tugmasi faqat belgilangan $range oralig‘ida faol bo‘ladi. Vaqt tugashi (00:00) bilan video qo‘ng‘iroq har ikki tomon uchun avtomatik yakunlanadi va baholash oynasi ochiladi.',
                  style: const TextStyle(
                    fontSize: 12.2,
                    height: 1.45,
                    color: _inkNavy,
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
            color: _softIce,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: _brandBlue),
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
                  fontWeight: FontWeight.w600,
                  color: _mutedSlate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? _inkNavy,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _softIce,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderBlue),
              ),
              child: const Text(
                'Tahrirlash',
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  color: _brandBlue,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final canContinue =
        _step == 1 && _selectedHour != null && _selectedSlotIndex != null;
    final isReview = _step == 2;
    final enabled = isReview || canContinue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _cardWhite,
        border: const Border(top: BorderSide(color: _borderBlue)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _brandBlue.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (isReview) ...<Widget>[
            GestureDetector(
              onTap: _isBooking ? null : () => setState(() => _step = 1),
              child: Container(
                width: 52,
                height: 54,
                decoration: BoxDecoration(
                  color: _softIce,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderBlue),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _inkNavy,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: GestureDetector(
              onTap: isReview
                  ? (_isBooking ? null : _confirmAndBook)
                  : (canContinue
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _step = 2);
                          }
                        : null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: enabled
                      ? const LinearGradient(
                          colors: <Color>[_brandBlue, _skyBlue],
                        )
                      : null,
                  color: enabled ? null : const Color(0xFFE2E8F0),
                  boxShadow: enabled
                      ? <BoxShadow>[
                          BoxShadow(
                            color: _brandBlue.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: _isBooking
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            isReview
                                ? 'UCHRASHUVNI TASDIQLASH'
                                : 'DAVOM ETISH',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: enabled
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: enabled
                                ? Colors.white
                                : const Color(0xFF94A3B8),
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