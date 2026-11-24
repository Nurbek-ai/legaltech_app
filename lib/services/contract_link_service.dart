import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/user_profile.dart';

class ContractInvitation {
  final String id;
  final String senderId;
  final String senderRole; // 'client' | 'advocate'
  final String senderName;
  final String clientId;
  final String clientName;
  final String advocateId;
  final String advocateName;
  final String caseSummary;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String rejectionReason;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ContractInvitation({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.clientId,
    required this.clientName,
    required this.advocateId,
    required this.advocateName,
    required this.caseSummary,
    this.status = 'pending',
    this.rejectionReason = '',
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String encodeChatMeta() {
    final map = <String, dynamic>{
      'id': id,
      'sender_id': senderId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'client_id': clientId,
      'client_name': clientName,
      'advocate_id': advocateId,
      'advocate_name': advocateName,
      'case_summary': caseSummary,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
    return 'CONTRACT_INVITE_V1|${base64Url.encode(utf8.encode(jsonEncode(map)))}';
  }

  static ContractInvitation? tryDecodeChatMeta(String? rawMeta) {
    if (rawMeta == null || !rawMeta.startsWith('CONTRACT_INVITE_V1|')) {
      return null;
    }
    try {
      final b64 = rawMeta.substring('CONTRACT_INVITE_V1|'.length).trim();
      final decoded = jsonDecode(utf8.decode(base64Url.decode(b64)));
      if (decoded is Map) {
        return ContractInvitation.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  ContractInvitation copyWith({
    String? status,
    String? rejectionReason,
    DateTime? respondedAt,
  }) {
    return ContractInvitation(
      id: id,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      clientId: clientId,
      clientName: clientName,
      advocateId: advocateId,
      advocateName: advocateName,
      caseSummary: caseSummary,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sender_id': senderId,
    'sender_role': senderRole,
    'sender_name': senderName,
    'client_id': clientId,
    'client_name': clientName,
    'advocate_id': advocateId,
    'advocate_name': advocateName,
    'case_summary': caseSummary,
    'status': status,
    'rejection_reason': rejectionReason,
    'created_at': createdAt.toUtc().toIso8601String(),
    'responded_at': respondedAt?.toUtc().toIso8601String(),
  };

  factory ContractInvitation.fromJson(Map<String, dynamic> map) {
    return ContractInvitation(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      senderRole: map['sender_role']?.toString() ?? 'client',
      senderName: map['sender_name']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? 'Mijoz',
      advocateId: map['advocate_id']?.toString() ?? '',
      advocateName: map['advocate_name']?.toString() ?? 'Advokat',
      caseSummary: map['case_summary']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      rejectionReason: map['rejection_reason']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      respondedAt:
          DateTime.tryParse(map['responded_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

class AdvocateClientLink {
  final String id;
  final String advocateId;
  final String clientId;
  final String advocateName;
  final String clientName;
  final String? invitationId;
  final String status; // 'active' | 'ended'
  final DateTime linkedAt;

  const AdvocateClientLink({
    required this.id,
    required this.advocateId,
    required this.clientId,
    required this.advocateName,
    required this.clientName,
    this.invitationId,
    this.status = 'active',
    required this.linkedAt,
  });

  bool get isActive => status == 'active';

  bool matchesPair(String userA, String userB) {
    if (!isActive) return false;
    final direct =
        YanRoleDataCatalog.isSameParticipant(advocateId, userA) &&
        YanRoleDataCatalog.isSameParticipant(clientId, userB);
    final reverse =
        YanRoleDataCatalog.isSameParticipant(advocateId, userB) &&
        YanRoleDataCatalog.isSameParticipant(clientId, userA);
    return direct || reverse;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'advocate_id': advocateId,
    'client_id': clientId,
    'advocate_name': advocateName,
    'client_name': clientName,
    'invitation_id': invitationId,
    'status': status,
    'linked_at': linkedAt.toUtc().toIso8601String(),
  };

  factory AdvocateClientLink.fromJson(Map<String, dynamic> map) {
    return AdvocateClientLink(
      id: map['id']?.toString() ?? '',
      advocateId: map['advocate_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      advocateName: map['advocate_name']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? '',
      invitationId: map['invitation_id']?.toString(),
      status: map['status']?.toString() ?? 'active',
      linkedAt:
          DateTime.tryParse(map['linked_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Real-time Advocate <-> Client Contract Invitation & ID Linking Repository
/// backed by Supabase (`advocate_client_invitations` + `advocate_client_links`).
class ContractLinkRepository {
  ContractLinkRepository._();
  static final ContractLinkRepository instance = ContractLinkRepository._();

  final ValueNotifier<List<ContractInvitation>> invitations =
      ValueNotifier<List<ContractInvitation>>(<ContractInvitation>[]);

  final ValueNotifier<List<AdvocateClientLink>> links =
      ValueNotifier<List<AdvocateClientLink>>(<AdvocateClientLink>[]);

  RealtimeChannel? _realtimeChannel;
  bool _initialized = false;

  File _cacheFile(String name) => File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_$name.json',
  );

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _loadCache();
    await refreshAll();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    if (_realtimeChannel != null) return;
    try {
      final ch = Supabase.instance.client.channel('yan360_contract_links_sync');
      ch
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'advocate_client_invitations',
            callback: (_) => refreshInvitations(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'advocate_client_links',
            callback: (_) => refreshLinks(),
          )
          .subscribe();
      _realtimeChannel = ch;
    } catch (e) {
      debugPrint('ContractLink realtime subscribe warning: $e');
    }
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      refreshInvitations(),
      refreshLinks(),
    ]);
  }

  Future<void> refreshInvitations() async {
    try {
      final rows = await Supabase.instance.client
          .from('advocate_client_invitations')
          .select()
          .order('created_at', ascending: false);
      final parsed = <ContractInvitation>[];
      for (final raw in rows) {
        if (raw is Map) {
          parsed.add(
            ContractInvitation.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
      invitations.value = parsed;
      await _saveCache();
    } catch (e) {
      debugPrint('refreshInvitations warning: $e');
    }
  }

  Future<void> refreshLinks() async {
    try {
      final rows = await Supabase.instance.client
          .from('advocate_client_links')
          .select()
          .eq('status', 'active')
          .order('linked_at', ascending: false);
      final parsed = <AdvocateClientLink>[];
      for (final raw in rows) {
        if (raw is Map) {
          parsed.add(
            AdvocateClientLink.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
      links.value = parsed;
      await _saveCache();
    } catch (e) {
      debugPrint('refreshLinks warning: $e');
    }
  }

  /// True ONLY if `userA` and `userB` have an active mutual Personal Advocate <-> Client link.
  bool isLinked(String userA, String userB) {
    if (userA.trim().isEmpty || userB.trim().isEmpty) return false;
    return links.value.any((l) => l.matchesPair(userA, userB));
  }

  AdvocateClientLink? findLink(String userA, String userB) {
    if (userA.trim().isEmpty || userB.trim().isEmpty) return null;
    for (final l in links.value) {
      if (l.matchesPair(userA, userB)) return l;
    }
    return null;
  }

  ContractInvitation? findInvitationById(String id) {
    for (final inv in invitations.value) {
      if (inv.id == id) return inv;
    }
    return null;
  }

  Future<ContractInvitation?> createInvitation({
    required String senderId,
    required String senderRole, // 'client' | 'advocate'
    required String senderName,
    required String clientId,
    required String clientName,
    required String advocateId,
    required String advocateName,
    required String caseSummary,
  }) async {
    final now = DateTime.now();
    final inv = ContractInvitation(
      id: 'SHRT-${now.millisecondsSinceEpoch}',
      senderId: senderId.trim(),
      senderRole: senderRole,
      senderName: senderName.trim(),
      clientId: clientId.trim(),
      clientName: clientName.trim(),
      advocateId: advocateId.trim(),
      advocateName: advocateName.trim(),
      caseSummary: caseSummary.trim(),
      status: 'pending',
      createdAt: now,
    );

    try {
      await Supabase.instance.client
          .from('advocate_client_invitations')
          .insert(inv.toJson());
    } catch (e) {
      debugPrint('createInvitation Supabase error: $e');
    }

    final updated = List<ContractInvitation>.from(invitations.value)
      ..insert(0, inv);
    invitations.value = updated;
    await _saveCache();
    return inv;
  }

  Future<String?> acceptInvitation(ContractInvitation inv) async {
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final myRole = userProfile.value.role == UserRole.advokat
        ? 'advocate'
        : 'client';
    if (!inv.isPending) {
      return 'Bu shartnoma taklifi allaqachon ko‘rib chiqilgan.';
    }
    if ((myId.isNotEmpty &&
            YanRoleDataCatalog.isSameParticipant(inv.senderId, myId)) ||
        (inv.senderRole.isNotEmpty && inv.senderRole == myRole)) {
      return 'O‘zingiz yuborgan taklifni tasdiqlay olmaysiz.';
    }
    final now = DateTime.now();
    try {
      await Supabase.instance.client
          .from('advocate_client_invitations')
          .update(<String, dynamic>{
            'status': 'accepted',
            'responded_at': now.toUtc().toIso8601String(),
          })
          .eq('id', inv.id);

      await Supabase.instance.client.from('advocate_client_links').upsert(
        <String, dynamic>{
          'advocate_id': inv.advocateId,
          'client_id': inv.clientId,
          'advocate_name': inv.advocateName,
          'client_name': inv.clientName,
          'invitation_id': inv.id,
          'status': 'active',
          'linked_at': now.toUtc().toIso8601String(),
        },
        onConflict: 'advocate_id,client_id',
      );
    } catch (e) {
      debugPrint('acceptInvitation Supabase warning: $e');
    }

    invitations.value = invitations.value
        .map(
          (item) => item.id == inv.id
              ? item.copyWith(status: 'accepted', respondedAt: now)
              : item,
        )
        .toList();

    final link = AdvocateClientLink(
      id: 'LNK-${now.millisecondsSinceEpoch}',
      advocateId: inv.advocateId,
      clientId: inv.clientId,
      advocateName: inv.advocateName,
      clientName: inv.clientName,
      invitationId: inv.id,
      status: 'active',
      linkedAt: now,
    );
    final nextLinks = List<AdvocateClientLink>.from(links.value)
      ..removeWhere((l) => l.matchesPair(inv.advocateId, inv.clientId))
      ..insert(0, link);
    links.value = nextLinks;
    await _saveCache();
    await refreshAll();
    return null;
  }

  Future<String?> rejectInvitation({
    required ContractInvitation inv,
    required String reason,
  }) async {
    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final myRole = userProfile.value.role == UserRole.advokat
        ? 'advocate'
        : 'client';
    if (!inv.isPending) {
      return 'Bu shartnoma taklifi allaqachon ko‘rib chiqilgan.';
    }
    if ((myId.isNotEmpty &&
            YanRoleDataCatalog.isSameParticipant(inv.senderId, myId)) ||
        (inv.senderRole.isNotEmpty && inv.senderRole == myRole)) {
      return 'O‘zingiz yuborgan taklifni rad eta olmaysiz.';
    }
    final now = DateTime.now();
    final cleanReason = reason.trim();
    try {
      await Supabase.instance.client
          .from('advocate_client_invitations')
          .update(<String, dynamic>{
            'status': 'rejected',
            'rejection_reason': cleanReason,
            'responded_at': now.toUtc().toIso8601String(),
          })
          .eq('id', inv.id);
    } catch (e) {
      debugPrint('rejectInvitation Supabase warning: $e');
    }

    invitations.value = invitations.value
        .map(
          (item) => item.id == inv.id
              ? item.copyWith(
                  status: 'rejected',
                  rejectionReason: cleanReason,
                  respondedAt: now,
                )
              : item,
        )
        .toList();
    await _saveCache();
    await refreshInvitations();
    return null;
  }

  String shortDisplayId(String rawId) {
    final clean = rawId.trim();
    if (clean.length <= 12) return clean;
    return '${clean.substring(0, 8).toUpperCase()}…${clean.substring(clean.length - 4).toUpperCase()}';
  }

  Future<void> _saveCache() async {
    try {
      await _cacheFile('contract_invites_v1').writeAsString(
        jsonEncode(invitations.value.map((e) => e.toJson()).toList()),
        flush: true,
      );
      await _cacheFile('contract_links_v1').writeAsString(
        jsonEncode(links.value.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  Future<void> _loadCache() async {
    try {
      final f1 = _cacheFile('contract_invites_v1');
      if (await f1.exists()) {
        final decoded = jsonDecode(await f1.readAsString());
        if (decoded is List) {
          invitations.value = decoded
              .whereType<Map>()
              .map((m) => ContractInvitation.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
      final f2 = _cacheFile('contract_links_v1');
      if (await f2.exists()) {
        final decoded = jsonDecode(await f2.readAsString());
        if (decoded is List) {
          links.value = decoded
              .whereType<Map>()
              .map((m) => AdvocateClientLink.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (_) {}
  }
}