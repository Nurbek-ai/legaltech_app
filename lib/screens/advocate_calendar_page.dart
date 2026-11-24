import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/consultation_service.dart';
import '../shared/user_profile.dart';

/// Advocate Calendar Control Center ("Advokat Kalendari" — Apple-Clean White & Sky-Blue Design):
/// - Manage upcoming 7 days (today + 6 days) across all 24 hours & 3x 19-min slots
/// - Block (remove) full busy days, full hours, or exact 19-min slots in real time
/// - Restore (cancel removal) of any blocked day, hour, or slot with one tap
/// - View all client-booked consultations for each day
class AdvocateCalendarPage extends StatefulWidget {
  const AdvocateCalendarPage({
    super.key,
    required this.profile,
  });

  final UserProfileData profile;

  @override
  State<AdvocateCalendarPage> createState() => _AdvocateCalendarPageState();
}

class _AdvocateCalendarPageState extends State<AdvocateCalendarPage> {
  // Apple-Clean Bright Sky-Blue & Pure White Palette
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

  late final List<DateTime> _sevenDays;
  int _selectedDayIndex = 0;
  int _selectedHour = DateTime.now().hour;
  bool _isBusyUpdating = false;

  String get _advocateId {
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return authId.trim().isNotEmpty
        ? authId.trim()
        : widget.profile.clientId.trim();
  }

  String get _selectedDateKey =>
      ConsultationSlotMath.dateKeyOf(_sevenDays[_selectedDayIndex]);

  @override
  void initState() {
    super.initState();
    _sevenDays = ConsultationSlotMath.upcomingSevenDays();
    ConsultationRepository.instance.ensureInitialized();
    ConsultationRepository.instance.refreshAll();
  }

  Future<void> _toggleDayBlock(bool currentlyBlocked) async {
    if (_isBusyUpdating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isBusyUpdating = true);
    try {
      final err = currentlyBlocked
          ? await ConsultationRepository.instance.unblockTime(
              advocateId: _advocateId,
              blockType: 'day',
              dateKey: _selectedDateKey,
            )
          : await ConsultationRepository.instance.blockTime(
              advocateId: _advocateId,
              blockType: 'day',
              dateKey: _selectedDateKey,
            );
      if (err != null) {
        _showToast(err, isError: true);
      } else {
        _showToast(
          currentlyBlocked
              ? 'Kun qayta ochildi. Mijozlar endi ushbu kunni band qila oladi.'
              : 'Kun yopildi va saqlandi.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusyUpdating = false);
    }
  }

  Future<void> _toggleHourBlock(int hour, bool currentlyBlocked) async {
    if (_isBusyUpdating) return;
    HapticFeedback.selectionClick();
    setState(() => _isBusyUpdating = true);
    try {
      final err = currentlyBlocked
          ? await ConsultationRepository.instance.unblockTime(
              advocateId: _advocateId,
              blockType: 'hour',
              dateKey: _selectedDateKey,
              hourValue: hour,
            )
          : await ConsultationRepository.instance.blockTime(
              advocateId: _advocateId,
              blockType: 'hour',
              dateKey: _selectedDateKey,
              hourValue: hour,
            );
      if (err != null) {
        _showToast(err, isError: true);
      } else {
        _showToast(
          currentlyBlocked
              ? '${ConsultationSlotMath.formatHour(hour)} soati qayta ochildi.'
              : '${ConsultationSlotMath.formatHour(hour)} soati yopildi va saqlandi.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusyUpdating = false);
    }
  }

  Future<void> _toggleSlotBlock(
    int hour,
    int slotIdx,
    bool currentlyBlocked,
  ) async {
    if (_isBusyUpdating) return;
    HapticFeedback.selectionClick();
    setState(() => _isBusyUpdating = true);
    try {
      final range = ConsultationSlotMath.formatSlotRange(hour, slotIdx);
      final err = currentlyBlocked
          ? await ConsultationRepository.instance.unblockTime(
              advocateId: _advocateId,
              blockType: 'slot',
              dateKey: _selectedDateKey,
              hourValue: hour,
              slotIndex: slotIdx,
            )
          : await ConsultationRepository.instance.blockTime(
              advocateId: _advocateId,
              blockType: 'slot',
              dateKey: _selectedDateKey,
              hourValue: hour,
              slotIndex: slotIdx,
            );
      if (err != null) {
        _showToast(err, isError: true);
      } else {
        _showToast(
          currentlyBlocked
              ? '$range vaqti qayta ochildi.'
              : '$range vaqti yopildi va saqlandi.',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusyUpdating = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _rose : _inkNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
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
          child: ValueListenableBuilder<List<AdvocateBlockedSlot>>(
            valueListenable: ConsultationRepository.instance.blockedSlots,
            builder: (context, _, __) {
              return ValueListenableBuilder<List<ConsultationBooking>>(
                valueListenable: ConsultationRepository.instance.consultations,
                builder: (context, _, __) {
                  final repo = ConsultationRepository.instance;
                  final advId = _advocateId;
                  final dateKey = _selectedDateKey;
                  final isDayBlocked = repo.isDayBlocked(advId, dateKey);
                  final isExplicitHourBlocked = repo.blockedSlots.value.any(
                    (b) =>
                        YanRoleDataCatalog.isSameParticipant(
                          b.advocateId,
                          advId,
                        ) &&
                        b.blockType == 'hour' &&
                        b.dateKey == dateKey &&
                        b.hourValue == _selectedHour,
                  );

                  final myBookings = repo.bookingsForAdvocate(advId);
                  final dayBookings = myBookings
                      .where((b) => b.dateKey == dateKey && b.isActiveStatus)
                      .toList();
                  final myBlockedRules = repo.blockedSlotsForAdvocate(advId);

                  return Column(
                    children: <Widget>[
                      _buildTopBar(
                        myBookings.where((b) => b.isActiveStatus).length,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                          children: <Widget>[
                            _buildDayStrip(repo, advId, myBookings),
                            const SizedBox(height: 14),

                            // Full-Day Block / Restore Control Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDayBlocked ? _roseSoft : _cardWhite,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDayBlocked
                                      ? _rose.withValues(alpha: 0.35)
                                      : _borderBlue,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDayBlocked
                                          ? _rose.withValues(alpha: 0.14)
                                          : _emeraldSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isDayBlocked
                                          ? Icons.event_busy_rounded
                                          : Icons.event_available_rounded,
                                      color: isDayBlocked ? _rose : _emerald,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          ConsultationSlotMath
                                              .formatFriendlyDate(
                                                _sevenDays[_selectedDayIndex],
                                              ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: _inkNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isDayBlocked
                                              ? 'Bu kun to‘liq yopilgan (band)'
                                              : 'Kun ochiq • ${dayBookings.length} ta band konsultatsiya',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDayBlocked
                                                ? _rose
                                                : _mutedSlate,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleDayBlock(isDayBlocked),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDayBlocked ? _emerald : _rose,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color:
                                                (isDayBlocked
                                                        ? _emerald
                                                        : _rose)
                                                    .withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        isDayBlocked
                                            ? 'Kunni ochish'
                                            : 'Kunni yopish',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 24-Hour Grid + Selected Hour 3-Slot Controls
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: _appleCardDecoration(radius: 26),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: _softIce,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.schedule_rounded,
                                          color: _brandBlue,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Soat va 19 daqiqalik vaqtlarni boshqarish',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _inkNavy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: 24,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 1.72,
                                        ),
                                    itemBuilder: (context, hour) {
                                      final hBlocked = repo.isHourBlocked(
                                        advId,
                                        dateKey,
                                        hour,
                                      );
                                      final hasBookings = dayBookings.any(
                                        (b) => b.hourValue == hour,
                                      );
                                      final selected = _selectedHour == hour;

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _selectedHour = hour);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: selected
                                                ? const LinearGradient(
                                                    colors: <Color>[
                                                      _brandBlue,
                                                      _skyBlue,
                                                    ],
                                                  )
                                                : null,
                                            color: selected
                                                ? null
                                                : hBlocked
                                                ? _roseSoft
                                                : hasBookings
                                                ? _emeraldSoft
                                                : _softIce,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? _brandBlue
                                                  : hBlocked
                                                  ? _rose.withValues(
                                                      alpha: 0.35,
                                                    )
                                                  : hasBookings
                                                  ? _emerald.withValues(
                                                      alpha: 0.5,
                                                    )
                                                  : _borderBlue,
                                              width: selected ? 1.5 : 1,
                                            ),
                                            boxShadow: selected
                                                ? <BoxShadow>[
                                                    BoxShadow(
                                                      color: _brandBlue
                                                          .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                ConsultationSlotMath.formatHour(
                                                  hour,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13.2,
                                                  fontWeight: FontWeight.w800,
                                                  color: selected
                                                      ? Colors.white
                                                      : hBlocked
                                                      ? _rose
                                                      : _inkNavy,
                                                ),
                                              ),
                                              Text(
                                                hBlocked
                                                    ? 'Yopiq'
                                                    : hasBookings
                                                    ? 'Mijoz bor'
                                                    : 'Ochiq',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: selected
                                                      ? Colors.white.withValues(
                                                          alpha: 0.9,
                                                        )
                                                      : hBlocked
                                                      ? _rose
                                                      : hasBookings
                                                      ? _emerald
                                                      : _mutedSlate,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, color: _borderBlue),
                                  const SizedBox(height: 14),

                                  // Selected Hour Action Header
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${ConsultationSlotMath.formatHour(_selectedHour)} soati (3 ta qism)',
                                          style: const TextStyle(
                                            fontSize: 14.2,
                                            fontWeight: FontWeight.w900,
                                            color: _inkNavy,
                                          ),
                                        ),
                                      ),
                                      if (!isDayBlocked)
                                        GestureDetector(
                                          onTap: () => _toggleHourBlock(
                                            _selectedHour,
                                            isExplicitHourBlocked,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isExplicitHourBlocked
                                                  ? _emeraldSoft
                                                  : _roseSoft,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isExplicitHourBlocked
                                                    ? _emerald.withValues(
                                                        alpha: 0.45,
                                                      )
                                                    : _rose.withValues(
                                                        alpha: 0.4,
                                                      ),
                                              ),
                                            ),
                                            child: Text(
                                              isExplicitHourBlocked
                                                  ? 'Soatni qayta ochish'
                                                  : 'Butun soatni yopish',
                                              style: TextStyle(
                                                fontSize: 11.2,
                                                fontWeight: FontWeight.w800,
                                                color: isExplicitHourBlocked
                                                    ? _emerald
                                                    : _rose,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // 3 Individual 19-Minute Slot Tiles
                                  Row(
                                    children: List<Widget>.generate(3, (slotIdx) {
                                      final range =
                                          ConsultationSlotMath.formatSlotRange(
                                            _selectedHour,
                                            slotIdx,
                                          );
                                      final booked = repo.findBookingForSlot(
                                        advId,
                                        dateKey,
                                        _selectedHour,
                                        slotIdx,
                                      );
                                      final explicitSlotBlocked = repo
                                          .blockedSlots
                                          .value
                                          .any(
                                            (b) =>
                                                YanRoleDataCatalog
                                                    .isSameParticipant(
                                                      b.advocateId,
                                                      advId,
                                                    ) &&
                                                b.blockType == 'slot' &&
                                                b.dateKey == dateKey &&
                                                b.hourValue == _selectedHour &&
                                                b.slotIndex == slotIdx,
                                          );
                                      final effectivelyBlocked =
                                          isDayBlocked ||
                                          isExplicitHourBlocked ||
                                          explicitSlotBlocked;

                                      return Expanded(
                                        child: GestureDetector(
                                          onTap:
                                              (booked != null ||
                                                  isDayBlocked ||
                                                  isExplicitHourBlocked)
                                              ? null
                                              : () => _toggleSlotBlock(
                                                  _selectedHour,
                                                  slotIdx,
                                                  explicitSlotBlocked,
                                                ),
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              right: slotIdx < 2 ? 8 : 0,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: booked != null
                                                  ? _softIce
                                                  : effectivelyBlocked
                                                  ? _roseSoft
                                                  : _emeraldSoft,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: booked != null
                                                    ? _brandBlue
                                                    : effectivelyBlocked
                                                    ? _rose.withValues(
                                                        alpha: 0.4,
                                                      )
                                                    : _emerald.withValues(
                                                        alpha: 0.45,
                                                      ),
                                              ),
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  range,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                    color: booked != null
                                                        ? _brandBlue
                                                        : effectivelyBlocked
                                                        ? _rose
                                                        : _inkNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  booked != null
                                                      ? booked.clientName
                                                      : effectivelyBlocked
                                                      ? (explicitSlotBlocked
                                                            ? 'Yopiq (Ochish)'
                                                            : 'Yopilgan')
                                                      : 'Ochiq (Yopish)',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: booked != null
                                                        ? _brandBlue
                                                        : effectivelyBlocked
                                                        ? _rose
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
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Blocked Times List with One-Tap Cancel/Restore
                            if (myBlockedRules.isNotEmpty) ...<Widget>[
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'YOPILGAN VAQTLAR (BEKOR QILISH / QAYTA OCHISH)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: _brandBlue,
                                  ),
                                ),
                              ),
                              ...myBlockedRules.map((rule) {
                                final dLabel =
                                    ConsultationSlotMath.formatFriendlyDate(
                                      ConsultationSlotMath.parseDateKey(
                                        rule.dateKey,
                                      ),
                                    );
                                final scopeLabel = rule.blockType == 'day'
                                    ? 'Butun kun yopilgan'
                                    : rule.blockType == 'hour'
                                    ? '${ConsultationSlotMath.formatHour(rule.hourValue ?? 0)} soati yopilgan'
                                    : '${ConsultationSlotMath.formatSlotRange(rule.hourValue ?? 0, rule.slotIndex ?? 0)} yopilgan';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _cardWhite,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _rose.withValues(alpha: 0.25),
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: _brandBlue.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: _roseSoft,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.block_rounded,
                                          size: 18,
                                          color: _rose,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              dLabel,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: _inkNavy,
                                              ),
                                            ),
                                            Text(
                                              scopeLabel,
                                              style: const TextStyle(
                                                fontSize: 11.8,
                                                color: _mutedSlate,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          HapticFeedback.selectionClick();
                                          await repo.unblockByEntry(rule);
                                          _showToast('Vaqt qayta ochildi.');
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _emeraldSoft,
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            border: Border.all(
                                              color: _emerald.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Qayta ochish',
                                            style: TextStyle(
                                              fontSize: 11.2,
                                              fontWeight: FontWeight.w800,
                                              color: _emerald,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(int activeBookingsCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
                  'Advokat Kalendari',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _inkNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Band kun va soatlarni boshqarish • $activeBookingsCount ta faol uchrashuv',
                  style: const TextStyle(
                    fontSize: 11.8,
                    color: _brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ConsultationRepository.instance.refreshAll(),
            child: Container(
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
              child: _isBusyUpdating
                  ? const CupertinoActivityIndicator(color: _brandBlue)
                  : const Icon(
                      CupertinoIcons.refresh,
                      color: _brandBlue,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip(
    ConsultationRepository repo,
    String advId,
    List<ConsultationBooking> myBookings,
  ) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sevenDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final d = _sevenDays[idx];
          final dKey = ConsultationSlotMath.dateKeyOf(d);
          final blocked = repo.isDayBlocked(advId, dKey);
          final bookedCount = myBookings
              .where((b) => b.dateKey == dKey && b.isActiveStatus)
              .length;
          final selected = idx == _selectedDayIndex;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDayIndex = idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 62,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[_brandBlue, _skyBlue],
                      )
                    : null,
                color: selected
                    ? null
                    : blocked
                    ? _roseSoft
                    : _cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _brandBlue
                      : blocked
                      ? _rose.withValues(alpha: 0.38)
                      : _borderBlue,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _brandBlue.withValues(alpha: selected ? 0.28 : 0.05),
                    blurRadius: selected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    idx == 0 ? 'BUGUN' : ConsultationSlotMath.shortWeekday(d),
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : blocked
                          ? _rose
                          : _mutedSlate,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? Colors.white
                          : blocked
                          ? _rose
                          : _inkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blocked
                        ? 'Yopiq'
                        : bookedCount > 0
                        ? '$bookedCount uchr.'
                        : 'Ochiq',
                    style: TextStyle(
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : blocked
                          ? _rose
                          : bookedCount > 0
                          ? _emerald
                          : _mutedSlate,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}