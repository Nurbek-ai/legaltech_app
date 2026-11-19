import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/user_profile.dart';

/// Represents one of the 3 nineteen-minute consultation slots inside an hour:
/// - slotIndex 0 -> HH:00 - HH:19 (1 min break at :19-:20)
/// - slotIndex 1 -> HH:20 - HH:39 (1 min break at :39-:40)
/// - slotIndex 2 -> HH:40 - HH:59 (1 min break at :59-:00)
class ConsultationSlotMath {
  ConsultationSlotMath._();

  static const List<String> _uzWeekdaysShort = <String>[
    'DU',
    'SE',
    'CH',
    'PA',
    'JU',
    'SH',
    'YA',
  ];

  static const List<String> _uzWeekdaysFull = <String>[
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ];

  static const List<String> _uzMonths = <String>[
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  /// Returns Today + upcoming 6 days (7 days total).
  static List<DateTime> upcomingSevenDays([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<DateTime>.generate(
      7,
      (i) => today.add(Duration(days: i)),
      growable: false,
    );
  }

  static String dateKeyOf(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? DateTime.now().month;
      final d = int.tryParse(parts[2]) ?? DateTime.now().day;
      return DateTime(y, m, d);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static int startMinuteForSlot(int slotIndex) {
    switch (slotIndex) {
      case 0:
        return 0;
      case 1:
        return 20;
      default:
        return 40;
    }
  }

  static int endMinuteForSlot(int slotIndex) => startMinuteForSlot(slotIndex) + 19;

  static DateTime slotStartDateTime(String dateKey, int hour, int slotIndex) {
    final d = parseDateKey(dateKey);
    return DateTime(d.year, d.month, d.day, hour, startMinuteForSlot(slotIndex));
  }

  static DateTime slotEndDateTime(String dateKey, int hour, int slotIndex) {
    return slotStartDateTime(dateKey, hour, slotIndex).add(
      const Duration(minutes: 19),
    );
  }

  static String formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  static String formatSlotRange(int hour, int slotIndex) {
    final hh = hour.toString().padLeft(2, '0');
    final sm = startMinuteForSlot(slotIndex).toString().padLeft(2, '0');
    final em = endMinuteForSlot(slotIndex).toString().padLeft(2, '0');
    return '$hh:$sm – $hh:$em';
  }

  static String shortWeekday(DateTime date) =>
      _uzWeekdaysShort[(date.weekday - 1).clamp(0, 6)];

  static String fullWeekday(DateTime date) =>
      _uzWeekdaysFull[(date.weekday - 1).clamp(0, 6)];

  static String monthName(DateTime date) =>
      _uzMonths[(date.month - 1).clamp(0, 11)];

  static String formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    final base = '${date.day} ${monthName(date)} (${shortWeekday(date)})';
    if (diff == 0) return 'Bugun, $base';
    if (diff == 1) return 'Ertaga, $base';
    return base;
  }

  static String formatCountdown(Duration d) {
    if (d.isNegative) return '00:00';
    final totalSecs = d.inSeconds;
    final hours = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class AdvocateBlockedSlot {
  final String id;
  final String advocateId;
  final String blockType; // 'day' | 'hour' | 'slot'
  final String dateKey;
  final int? hourValue;
  final int? slotIndex;
  final DateTime createdAt;

  const AdvocateBlockedSlot({
    required this.id,
    required this.advocateId,
    required this.blockType,
    required this.dateKey,
    this.hourValue,
    this.slotIndex,
    required this.createdAt,
  });

  String get uniqueKey =>
      '${advocateId.trim()}|$blockType|$dateKey|${hourValue ?? -1}|${slotIndex ?? -1}';

  bool blocksSlot(String dKey, int hour, int slotIdx) {
    if (dateKey != dKey) return false;
    if (blockType == 'day') return true;
    if (blockType == 'hour') return hourValue == hour;
    return blockType == 'slot' && hourValue == hour && slotIndex == slotIdx;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'advocate_id': advocateId,
    'block_type': blockType,
    'date_key': dateKey,
    'hour_value': hourValue,
    'slot_index': slotIndex,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory AdvocateBlockedSlot.fromJson(Map<String, dynamic> map) {
    return AdvocateBlockedSlot(
      id: map['id']?.toString() ?? '',
      advocateId: map['advocate_id']?.toString() ?? '',
      blockType: map['block_type']?.toString() ?? 'slot',
      dateKey: map['date_key']?.toString() ?? '',
      hourValue: (map['hour_value'] as num?)?.toInt(),
      slotIndex: (map['slot_index'] as num?)?.toInt(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class ConsultationBooking {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientRegion;
  final String advocateId;
  final String advocateName;
  final String advocateTitle;
  final String advocateSpecialization;
  final String dateKey;
  final int hourValue;
  final int slotIndex;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String status; // 'booked' | 'in_progress' | 'completed' | 'cancelled'
  final int? ratingStars;
  final String ratingComment;
  final DateTime? ratedAt;
  final DateTime createdAt;

  const ConsultationBooking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientRegion,
    required this.advocateId,
    required this.advocateName,
    required this.advocateTitle,
    required this.advocateSpecialization,
    required this.dateKey,
    required this.hourValue,
    required this.slotIndex,
    required this.slotStart,
    required this.slotEnd,
    this.status = 'booked',
    this.ratingStars,
    this.ratingComment = '',
    this.ratedAt,
    required this.createdAt,
  });

  String get timeRangeLabel =>
      ConsultationSlotMath.formatSlotRange(hourValue, slotIndex);

  String get friendlyDateLabel =>
      ConsultationSlotMath.formatFriendlyDate(
        ConsultationSlotMath.parseDateKey(dateKey),
      );

  bool get isActiveStatus => status == 'booked' || status == 'in_progress';

  bool isWithinLiveWindow([DateTime? now]) {
    final t = now ?? DateTime.now();
    return isActiveStatus && !t.isBefore(slotStart) && t.isBefore(slotEnd);
  }

  bool isUpcoming([DateTime? now]) {
    final t = now ?? DateTime.now();
    return isActiveStatus && t.isBefore(slotStart);
  }

  bool isExpired([DateTime? now]) {
    final t = now ?? DateTime.now();
    return status == 'completed' || !t.isBefore(slotEnd);
  }

  Duration remainingUntilStart([DateTime? now]) =>
      slotStart.difference(now ?? DateTime.now());

  Duration remainingUntilEnd([DateTime? now]) =>
      slotEnd.difference(now ?? DateTime.now());

  /// Compact metadata payload embedded inside chat messages (`CONSULTATION_V1|...`)
  String encodeChatMeta() {
    final map = <String, dynamic>{
      'id': id,
      'advocate_id': advocateId,
      'advocate_name': advocateName,
      'client_id': clientId,
      'client_name': clientName,
      'date_key': dateKey,
      'hour': hourValue,
      'slot': slotIndex,
      'start_iso': slotStart.toUtc().toIso8601String(),
      'end_iso': slotEnd.toUtc().toIso8601String(),
      'status': status,
      'stars': ratingStars ?? 0,
    };
    return 'CONSULTATION_V1|${base64Url.encode(utf8.encode(jsonEncode(map)))}';
  }

  static Map<String, dynamic>? tryDecodeChatMeta(String? rawMeta) {
    if (rawMeta == null || !rawMeta.startsWith('CONSULTATION_V1|')) {
      return null;
    }
    try {
      final b64 = rawMeta.substring('CONSULTATION_V1|'.length).trim();
      final decoded = jsonDecode(utf8.decode(base64Url.decode(b64)));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  ConsultationBooking copyWith({
    String? status,
    int? ratingStars,
    String? ratingComment,
    DateTime? ratedAt,
  }) {
    return ConsultationBooking(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientRegion: clientRegion,
      advocateId: advocateId,
      advocateName: advocateName,
      advocateTitle: advocateTitle,
      advocateSpecialization: advocateSpecialization,
      dateKey: dateKey,
      hourValue: hourValue,
      slotIndex: slotIndex,
      slotStart: slotStart,
      slotEnd: slotEnd,
      status: status ?? this.status,
      ratingStars: ratingStars ?? this.ratingStars,
      ratingComment: ratingComment ?? this.ratingComment,
      ratedAt: ratedAt ?? this.ratedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'client_id': clientId,
    'client_name': clientName,
    'client_phone': clientPhone,
    'client_region': clientRegion,
    'advocate_id': advocateId,
    'advocate_name': advocateName,
    'advocate_title': advocateTitle,
    'advocate_specialization': advocateSpecialization,
    'date_key': dateKey,
    'hour_value': hourValue,
    'slot_index': slotIndex,
    'slot_start': slotStart.toUtc().toIso8601String(),
    'slot_end': slotEnd.toUtc().toIso8601String(),
    'status': status,
    'rating_stars': ratingStars,
    'rating_comment': ratingComment,
    'rated_at': ratedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory ConsultationBooking.fromJson(Map<String, dynamic> map) {
    final dateKey = map['date_key']?.toString() ?? '';
    final hour = (map['hour_value'] as num?)?.toInt() ?? 9;
    final slot = (map['slot_index'] as num?)?.toInt() ?? 0;
    final parsedStart =
        DateTime.tryParse(map['slot_start']?.toString() ?? '')?.toLocal() ??
        ConsultationSlotMath.slotStartDateTime(dateKey, hour, slot);
    final parsedEnd =
        DateTime.tryParse(map['slot_end']?.toString() ?? '')?.toLocal() ??
        parsedStart.add(const Duration(minutes: 19));

    return ConsultationBooking(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? 'Mijoz',
      clientPhone: map['client_phone']?.toString() ?? '',
      clientRegion: map['client_region']?.toString() ?? '',
      advocateId: map['advocate_id']?.toString() ?? '',
      advocateName: map['advocate_name']?.toString() ?? 'Advokat',
      advocateTitle: map['advocate_title']?.toString() ?? '',
      advocateSpecialization:
          map['advocate_specialization']?.toString() ?? '',
      dateKey: dateKey,
      hourValue: hour,
      slotIndex: slot,
      slotStart: parsedStart,
      slotEnd: parsedEnd,
      status: map['status']?.toString() ?? 'booked',
      ratingStars: (map['rating_stars'] as num?)?.toInt(),
      ratingComment: map['rating_comment']?.toString() ?? '',
      ratedAt: DateTime.tryParse(map['rated_at']?.toString() ?? '')?.toLocal(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class ConsultationBookingResult {
  final bool success;
  final ConsultationBooking? booking;
  final String? errorMessage;

  const ConsultationBookingResult({
    required this.success,
    this.booking,
    this.errorMessage,
  });
}

/// Real-time Consultation & Advocate Calendar Repository backed by Supabase
/// (`public.consultations` + `public.advocate_blocked_slots`) with local disk cache fallback.
class ConsultationRepository {
  ConsultationRepository._();
  static final ConsultationRepository instance = ConsultationRepository._();

  final ValueNotifier<List<ConsultationBooking>> consultations =
      ValueNotifier<List<ConsultationBooking>>(<ConsultationBooking>[]);

  final ValueNotifier<List<AdvocateBlockedSlot>> blockedSlots =
      ValueNotifier<List<AdvocateBlockedSlot>>(<AdvocateBlockedSlot>[]);

  RealtimeChannel? _realtimeChannel;
  bool _initialized = false;

  File _cacheFile(String name) => File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_$name.json',
  );

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _loadLocalCache();
    await refreshAll();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    if (_realtimeChannel != null) return;
    try {
      final ch = Supabase.instance.client.channel('yan360_consultations_sync');
      ch
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'consultations',
            callback: (_) => refreshConsultations(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'advocate_blocked_slots',
            callback: (_) => refreshBlockedSlots(),
          )
          .subscribe();
      _realtimeChannel = ch;
    } catch (e) {
      debugPrint('Consultation realtime subscribe warning: $e');
    }
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      refreshConsultations(),
      refreshBlockedSlots(),
    ]);
  }

  Future<void> refreshConsultations() async {
    try {
      final rows = await Supabase.instance.client
          .from('consultations')
          .select()
          .order('slot_start', ascending: true);
      final parsed = <ConsultationBooking>[];
      for (final raw in rows) {
        if (raw is Map) {
          parsed.add(
            ConsultationBooking.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
      consultations.value = parsed;
      await _saveLocalCache();
    } catch (e) {
      debugPrint('refreshConsultations warning: $e');
    }
  }

  Future<void> refreshBlockedSlots() async {
    try {
      final rows = await Supabase.instance.client
          .from('advocate_blocked_slots')
          .select()
          .order('date_key', ascending: true);
      final parsed = <AdvocateBlockedSlot>[];
      for (final raw in rows) {
        if (raw is Map) {
          parsed.add(
            AdvocateBlockedSlot.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
      blockedSlots.value = parsed;
      await _saveLocalCache();
    } catch (e) {
      debugPrint('refreshBlockedSlots warning: $e');
    }
  }

  bool isDayBlocked(String advocateId, String dateKey) {
    return blockedSlots.value.any(
      (b) =>
          YanRoleDataCatalog.isSameParticipant(b.advocateId, advocateId) &&
          b.blockType == 'day' &&
          b.dateKey == dateKey,
    );
  }

  bool isHourBlocked(String advocateId, String dateKey, int hour) {
    return blockedSlots.value.any(
      (b) =>
          YanRoleDataCatalog.isSameParticipant(b.advocateId, advocateId) &&
          b.dateKey == dateKey &&
          (b.blockType == 'day' ||
              (b.blockType == 'hour' && b.hourValue == hour)),
    );
  }

  bool isSlotBlocked(
    String advocateId,
    String dateKey,
    int hour,
    int slotIndex,
  ) {
    return blockedSlots.value.any(
      (b) =>
          YanRoleDataCatalog.isSameParticipant(b.advocateId, advocateId) &&
          b.blocksSlot(dateKey, hour, slotIndex),
    );
  }

  ConsultationBooking? findBookingForSlot(
    String advocateId,
    String dateKey,
    int hour,
    int slotIndex,
  ) {
    for (final c in consultations.value) {
      if (YanRoleDataCatalog.isSameParticipant(c.advocateId, advocateId) &&
          c.dateKey == dateKey &&
          c.hourValue == hour &&
          c.slotIndex == slotIndex &&
          c.isActiveStatus) {
        return c;
      }
    }
    return null;
  }

  bool isSlotPast(String dateKey, int hour, int slotIndex, [DateTime? now]) {
    final t = now ?? DateTime.now();
    final end = ConsultationSlotMath.slotEndDateTime(dateKey, hour, slotIndex);
    return !t.isBefore(end);
  }

  bool isSlotBookable(
    String advocateId,
    String dateKey,
    int hour,
    int slotIndex, [
    DateTime? now,
  ]) {
    if (isSlotPast(dateKey, hour, slotIndex, now)) return false;
    if (isSlotBlocked(advocateId, dateKey, hour, slotIndex)) return false;
    if (findBookingForSlot(advocateId, dateKey, hour, slotIndex) != null) {
      return false;
    }
    return true;
  }

  int countAvailableSlotsForHour(
    String advocateId,
    String dateKey,
    int hour, [
    DateTime? now,
  ]) {
    var count = 0;
    for (var s = 0; s < 3; s++) {
      if (isSlotBookable(advocateId, dateKey, hour, s, now)) {
        count++;
      }
    }
    return count;
  }

  /// Advocate action: Block a full day, a specific hour, or an exact 19-min slot.
  Future<void> blockTime({
    required String advocateId,
    required String blockType, // 'day' | 'hour' | 'slot'
    required String dateKey,
    int? hourValue,
    int? slotIndex,
  }) async {
    final localId = 'BLK-${DateTime.now().microsecondsSinceEpoch}';
    final entry = AdvocateBlockedSlot(
      id: localId,
      advocateId: advocateId,
      blockType: blockType,
      dateKey: dateKey,
      hourValue: blockType == 'day' ? null : hourValue,
      slotIndex: blockType == 'slot' ? slotIndex : null,
      createdAt: DateTime.now(),
    );

    // Optimistic local update
    final current = List<AdvocateBlockedSlot>.from(blockedSlots.value);
    if (!current.any((e) => e.uniqueKey == entry.uniqueKey)) {
      current.add(entry);
      blockedSlots.value = current;
      await _saveLocalCache();
    }

    try {
      await Supabase.instance.client.from('advocate_blocked_slots').insert(
        <String, dynamic>{
          'advocate_id': advocateId,
          'block_type': blockType,
          'date_key': dateKey,
          'hour_value': blockType == 'day' ? null : hourValue,
          'slot_index': blockType == 'slot' ? slotIndex : null,
        },
      );
      await refreshBlockedSlots();
    } catch (e) {
      debugPrint('blockTime Supabase insert warning: $e');
    }
  }

  /// Advocate action: Cancel/remove a previously blocked day, hour, or slot.
  Future<void> unblockTime({
    required String advocateId,
    required String blockType,
    required String dateKey,
    int? hourValue,
    int? slotIndex,
  }) async {
    final current = List<AdvocateBlockedSlot>.from(blockedSlots.value);
    current.removeWhere(
      (b) =>
          YanRoleDataCatalog.isSameParticipant(b.advocateId, advocateId) &&
          b.blockType == blockType &&
          b.dateKey == dateKey &&
          (blockType == 'day' || b.hourValue == hourValue) &&
          (blockType != 'slot' || b.slotIndex == slotIndex),
    );
    blockedSlots.value = current;
    await _saveLocalCache();

    try {
      var query = Supabase.instance.client
          .from('advocate_blocked_slots')
          .delete()
          .eq('advocate_id', advocateId)
          .eq('block_type', blockType)
          .eq('date_key', dateKey);
      if (blockType != 'day' && hourValue != null) {
        query = query.eq('hour_value', hourValue);
      }
      if (blockType == 'slot' && slotIndex != null) {
        query = query.eq('slot_index', slotIndex);
      }
      await query;
      await refreshBlockedSlots();
    } catch (e) {
      debugPrint('unblockTime Supabase delete warning: $e');
    }
  }

  Future<void> unblockByEntry(AdvocateBlockedSlot entry) async {
    await unblockTime(
      advocateId: entry.advocateId,
      blockType: entry.blockType,
      dateKey: entry.dateKey,
      hourValue: entry.hourValue,
      slotIndex: entry.slotIndex,
    );
  }

  /// Atomic client booking with fresh server re-verification of blocked & booked slots.
  Future<ConsultationBookingResult> bookConsultation({
    required UserProfileData clientProfile,
    required LawyerDirectoryProfile advocate,
    required String dateKey,
    required int hourValue,
    required int slotIndex,
  }) async {
    await refreshAll();

    final now = DateTime.now();
    if (isSlotPast(dateKey, hourValue, slotIndex, now)) {
      return const ConsultationBookingResult(
        success: false,
        errorMessage: 'Tanlangan vaqt allaqachon o‘tib ketgan. Boshqa vaqt tanlang.',
      );
    }
    if (isSlotBlocked(advocate.id, dateKey, hourValue, slotIndex)) {
      return const ConsultationBookingResult(
        success: false,
        errorMessage:
            'Kechirasiz, advokat ushbu vaqtni hozirgina band deb yopdi. Iltimos, boshqa vaqt tanlang.',
      );
    }
    if (findBookingForSlot(advocate.id, dateKey, hourValue, slotIndex) != null) {
      return const ConsultationBookingResult(
        success: false,
        errorMessage:
            'Ushbu 19 daqiqalik vaqt boshqa mijoz tomonidan band qilindi. Boshqa vaqt tanlang.',
      );
    }

    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final clientId = authId.trim().isNotEmpty
        ? authId.trim()
        : clientProfile.clientId.trim();
    final bookingId = 'KNS-${DateTime.now().millisecondsSinceEpoch}';
    final start = ConsultationSlotMath.slotStartDateTime(
      dateKey,
      hourValue,
      slotIndex,
    );
    final end = ConsultationSlotMath.slotEndDateTime(
      dateKey,
      hourValue,
      slotIndex,
    );

    final booking = ConsultationBooking(
      id: bookingId,
      clientId: clientId,
      clientName: clientProfile.displayName,
      clientPhone: clientProfile.phone,
      clientRegion: clientProfile.region,
      advocateId: advocate.id,
      advocateName: advocate.fullName,
      advocateTitle: advocate.title,
      advocateSpecialization: advocate.specialization,
      dateKey: dateKey,
      hourValue: hourValue,
      slotIndex: slotIndex,
      slotStart: start,
      slotEnd: end,
      status: 'booked',
      createdAt: now,
    );

    try {
      await Supabase.instance.client
          .from('consultations')
          .insert(booking.toJson());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        return const ConsultationBookingResult(
          success: false,
          errorMessage:
              'Ushbu vaqt boshqa mijoz tomonidan band qilindi. Boshqa vaqt tanlang.',
        );
      }
      debugPrint('bookConsultation Supabase insert warning: $e');
    }

    final updated = List<ConsultationBooking>.from(consultations.value)
      ..add(booking)
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
    consultations.value = updated;
    await _saveLocalCache();

    return ConsultationBookingResult(success: true, booking: booking);
  }

  Future<void> markStatus(String consultationId, String newStatus) async {
    final updated = consultations.value
        .map((c) => c.id == consultationId ? c.copyWith(status: newStatus) : c)
        .toList();
    consultations.value = updated;
    await _saveLocalCache();

    try {
      await Supabase.instance.client
          .from('consultations')
          .update(<String, dynamic>{'status': newStatus})
          .eq('id', consultationId);
    } catch (e) {
      debugPrint('markStatus warning: $e');
    }
  }

  Future<void> submitConsultationRating({
    required String consultationId,
    required int stars,
    String comment = '',
  }) async {
    final now = DateTime.now();
    final updated = consultations.value
        .map(
          (c) => c.id == consultationId
              ? c.copyWith(
                  status: 'completed',
                  ratingStars: stars,
                  ratingComment: comment.trim(),
                  ratedAt: now,
                )
              : c,
        )
        .toList();
    consultations.value = updated;
    await _saveLocalCache();

    try {
      await Supabase.instance.client
          .from('consultations')
          .update(<String, dynamic>{
            'status': 'completed',
            'rating_stars': stars,
            'rating_comment': comment.trim(),
            'rated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', consultationId);
    } catch (e) {
      debugPrint('submitConsultationRating warning: $e');
    }
  }

  List<ConsultationBooking> bookingsForClient(String clientId) {
    return consultations.value
        .where((c) => YanRoleDataCatalog.isSameParticipant(c.clientId, clientId))
        .toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  }

  List<ConsultationBooking> bookingsForAdvocate(String advocateId) {
    return consultations.value
        .where(
          (c) => YanRoleDataCatalog.isSameParticipant(c.advocateId, advocateId),
        )
        .toList()
      ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  }

  List<AdvocateBlockedSlot> blockedSlotsForAdvocate(String advocateId) {
    return blockedSlots.value
        .where(
          (b) => YanRoleDataCatalog.isSameParticipant(b.advocateId, advocateId),
        )
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  Future<void> _saveLocalCache() async {
    try {
      await _cacheFile('consultations_v1').writeAsString(
        jsonEncode(consultations.value.map((e) => e.toJson()).toList()),
        flush: true,
      );
      await _cacheFile('blocked_slots_v1').writeAsString(
        jsonEncode(blockedSlots.value.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  Future<void> _loadLocalCache() async {
    try {
      final f1 = _cacheFile('consultations_v1');
      if (await f1.exists()) {
        final decoded = jsonDecode(await f1.readAsString());
        if (decoded is List) {
          consultations.value = decoded
              .whereType<Map>()
              .map((m) => ConsultationBooking.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
      final f2 = _cacheFile('blocked_slots_v1');
      if (await f2.exists()) {
        final decoded = jsonDecode(await f2.readAsString());
        if (decoded is List) {
          blockedSlots.value = decoded
              .whereType<Map>()
              .map((m) => AdvocateBlockedSlot.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (_) {}
  }
}