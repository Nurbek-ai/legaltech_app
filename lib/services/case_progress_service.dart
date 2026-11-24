import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/user_profile.dart';

/// Supported process statuses for the Vertical Case Progress Stepper.
enum CaseStepStatus {
  completed('completed'),
  successful('successful'),
  failed('failed'),
  postponed('postponed'),
  rejected('rejected'),
  inProgress('in_progress'),
  upcoming('upcoming');

  const CaseStepStatus(this.wireValue);
  final String wireValue;

  static CaseStepStatus fromWire(String? raw) {
    final clean = (raw ?? '').trim().toLowerCase();
    for (final v in CaseStepStatus.values) {
      if (v.wireValue == clean) return v;
    }
    return CaseStepStatus.upcoming;
  }
}

/// Optional uploaded document attached to a specific case process step.
class CaseStepDocument {
  final String id;
  final String name;
  final String fileType; // e.g. 'PDF', 'DOCX', 'Rasm', 'Hujjat'
  final String storagePath;
  final String storageBucket;
  final String localPath;
  final DateTime uploadedAt;

  const CaseStepDocument({
    required this.id,
    required this.name,
    required this.fileType,
    this.storagePath = '',
    this.storageBucket = 'advocate_licenses',
    this.localPath = '',
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'file_type': fileType,
        'storage_path': storagePath,
        'storage_bucket': storageBucket,
        'local_path': localPath,
        'uploaded_at': uploadedAt.toUtc().toIso8601String(),
      };

  factory CaseStepDocument.fromJson(Map<String, dynamic> map) {
    return CaseStepDocument(
      id: (map['id']?.toString() ?? '').trim(),
      name: (map['name']?.toString() ?? 'Hujjat').trim(),
      fileType: (map['file_type']?.toString() ?? 'Hujjat').trim(),
      storagePath: (map['storage_path']?.toString() ?? '').trim(),
      storageBucket:
          (map['storage_bucket']?.toString() ?? 'advocate_licenses').trim(),
      localPath: (map['local_path']?.toString() ?? '').trim(),
      uploadedAt:
          DateTime.tryParse(map['uploaded_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  static String inferFileType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'DOCX';
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return 'Rasm';
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return 'Excel';
    return 'Hujjat';
  }
}

/// Single process stage inside a client's legal case timeline.
class CaseProgressStep {
  final String id;
  final String caseKey;
  final String advocateId;
  final String clientId;
  final int sortOrder;
  final String title;
  final String shortDescription;
  final CaseStepStatus status;
  final DateTime? eventDate;

  // Optional expanded details
  final String failureReason;
  final String detailedExplanation;
  final String actionsTaken;
  final String nextSteps;
  final String lawyerComment;

  // Optional relevant dates
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? decisionAt;
  final DateTime? completedAt;
  final DateTime? nextActionAt;

  // Optional uploaded documents
  final List<CaseStepDocument> attachments;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseProgressStep({
    required this.id,
    required this.caseKey,
    required this.advocateId,
    required this.clientId,
    required this.sortOrder,
    required this.title,
    this.shortDescription = '',
    required this.status,
    this.eventDate,
    this.failureReason = '',
    this.detailedExplanation = '',
    this.actionsTaken = '',
    this.nextSteps = '',
    this.lawyerComment = '',
    this.startedAt,
    this.submittedAt,
    this.decisionAt,
    this.completedAt,
    this.nextActionAt,
    this.attachments = const <CaseStepDocument>[],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAdditionalProcessInfo =>
      detailedExplanation.trim().isNotEmpty ||
      failureReason.trim().isNotEmpty ||
      actionsTaken.trim().isNotEmpty ||
      nextSteps.trim().isNotEmpty;

  bool get hasRelevantDates =>
      startedAt != null ||
      submittedAt != null ||
      decisionAt != null ||
      completedAt != null ||
      nextActionAt != null;

  bool get hasExpandableContent =>
      hasAdditionalProcessInfo ||
      attachments.isNotEmpty ||
      lawyerComment.trim().isNotEmpty ||
      hasRelevantDates;

  CaseProgressStep copyWith({
    int? sortOrder,
    String? title,
    String? shortDescription,
    CaseStepStatus? status,
    DateTime? eventDate,
    bool clearEventDate = false,
    String? failureReason,
    String? detailedExplanation,
    String? actionsTaken,
    String? nextSteps,
    String? lawyerComment,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? submittedAt,
    bool clearSubmittedAt = false,
    DateTime? decisionAt,
    bool clearDecisionAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? nextActionAt,
    bool clearNextActionAt = false,
    List<CaseStepDocument>? attachments,
    DateTime? updatedAt,
  }) {
    return CaseProgressStep(
      id: id,
      caseKey: caseKey,
      advocateId: advocateId,
      clientId: clientId,
      sortOrder: sortOrder ?? this.sortOrder,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      status: status ?? this.status,
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      failureReason: failureReason ?? this.failureReason,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      nextSteps: nextSteps ?? this.nextSteps,
      lawyerComment: lawyerComment ?? this.lawyerComment,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      submittedAt: clearSubmittedAt ? null : (submittedAt ?? this.submittedAt),
      decisionAt: clearDecisionAt ? null : (decisionAt ?? this.decisionAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      nextActionAt:
          clearNextActionAt ? null : (nextActionAt ?? this.nextActionAt),
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'case_key': caseKey,
        'advocate_id': advocateId,
        'client_id': clientId,
        'sort_order': sortOrder,
        'title': title,
        'short_description': shortDescription,
        'status': status.wireValue,
        'event_date': eventDate?.toUtc().toIso8601String(),
        'failure_reason': failureReason,
        'detailed_explanation': detailedExplanation,
        'actions_taken': actionsTaken,
        'next_steps': nextSteps,
        'lawyer_comment': lawyerComment,
        'started_at': startedAt?.toUtc().toIso8601String(),
        'submitted_at': submittedAt?.toUtc().toIso8601String(),
        'decision_at': decisionAt?.toUtc().toIso8601String(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'next_action_at': nextActionAt?.toUtc().toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory CaseProgressStep.fromJson(Map<String, dynamic> map) {
    DateTime? parseDt(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toLocal();
    }

    final rawAtt = map['attachments'];
    final docs = <CaseStepDocument>[];
    if (rawAtt is List) {
      for (final item in rawAtt) {
        if (item is Map) {
          docs.add(CaseStepDocument.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rawAtt is String && rawAtt.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAtt);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              docs.add(
                CaseStepDocument.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      } catch (_) {}
    }

    return CaseProgressStep(
      id: (map['id']?.toString() ?? '').trim(),
      caseKey: (map['case_key']?.toString() ?? '').trim(),
      advocateId: (map['advocate_id']?.toString() ?? '').trim(),
      clientId: (map['client_id']?.toString() ?? '').trim(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      title: (map['title']?.toString() ?? '').trim(),
      shortDescription: (map['short_description']?.toString() ?? '').trim(),
      status: CaseStepStatus.fromWire(map['status']?.toString()),
      eventDate: parseDt(map['event_date']),
      failureReason: (map['failure_reason']?.toString() ?? '').trim(),
      detailedExplanation:
          (map['detailed_explanation']?.toString() ?? '').trim(),
      actionsTaken: (map['actions_taken']?.toString() ?? '').trim(),
      nextSteps: (map['next_steps']?.toString() ?? '').trim(),
      lawyerComment: (map['lawyer_comment']?.toString() ?? '').trim(),
      startedAt: parseDt(map['started_at']),
      submittedAt: parseDt(map['submitted_at']),
      decisionAt: parseDt(map['decision_at']),
      completedAt: parseDt(map['completed_at']),
      nextActionAt: parseDt(map['next_action_at']),
      attachments: docs,
      createdAt: parseDt(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDt(map['updated_at']) ?? DateTime.now(),
    );
  }
}

/// Manages persistence, real-time sync, local caching, and document uploads
/// for client legal case timelines.
class CaseProgressRepository {
  CaseProgressRepository._();
  static final CaseProgressRepository instance = CaseProgressRepository._();

  final Map<String, ValueNotifier<List<CaseProgressStep>>> _caseNotifiers =
      <String, ValueNotifier<List<CaseProgressStep>>>{};
  final Map<String, RealtimeChannel> _channels = <String, RealtimeChannel>{};

  static String buildCaseKey(String advocateId, String clientId) {
    String norm(String raw) {
      var clean = raw.trim().toLowerCase();
      if (clean.startsWith('yan-')) clean = clean.substring(4);
      clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
      return clean.isEmpty ? 'unknown' : clean;
    }

    return 'case_${norm(advocateId)}__${norm(clientId)}';
  }

  ValueNotifier<List<CaseProgressStep>> notifierForCase(String caseKey) {
    return _caseNotifiers.putIfAbsent(
      caseKey,
      () => ValueNotifier<List<CaseProgressStep>>(<CaseProgressStep>[]),
    );
  }

  File _cacheFile(String caseKey) {
    final safe = caseKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_case_progress_$safe.json',
    );
  }

  Future<void> _loadCache(String caseKey) async {
    try {
      final f = _cacheFile(caseKey);
      if (!await f.exists()) return;
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is List) {
        final list = decoded
            .whereType<Map>()
            .map((e) => CaseProgressStep.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        notifierForCase(caseKey).value = List<CaseProgressStep>.unmodifiable(list);
      }
    } catch (_) {}
  }

  Future<void> _saveCache(String caseKey, List<CaseProgressStep> steps) async {
    try {
      await _cacheFile(caseKey).writeAsString(
        jsonEncode(steps.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  Future<void> loadCase({
    required String advocateId,
    required String clientId,
  }) async {
    final caseKey = buildCaseKey(advocateId, clientId);
    await _loadCache(caseKey);
    await refreshCase(advocateId: advocateId, clientId: clientId);
    _subscribeRealtime(caseKey, advocateId, clientId);
  }

  void _subscribeRealtime(
    String caseKey,
    String advocateId,
    String clientId,
  ) {
    if (_channels.containsKey(caseKey)) return;
    try {
      final channel = Supabase.instance.client
          .channel('case_progress_$caseKey')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'case_progress_steps',
            callback: (_) {
              refreshCase(advocateId: advocateId, clientId: clientId);
            },
          )
          .subscribe();
      _channels[caseKey] = channel;
    } catch (_) {}
  }

  Future<void> refreshCase({
    required String advocateId,
    required String clientId,
  }) async {
    final caseKey = buildCaseKey(advocateId, clientId);
    try {
      final rows = await Supabase.instance.client
          .from('case_progress_steps')
          .select()
          .eq('case_key', caseKey)
          .order('sort_order', ascending: true);

      final parsed = <CaseProgressStep>[];
      for (final row in rows) {
        parsed.add(
          CaseProgressStep.fromJson(Map<String, dynamic>.from(row as Map)),
        );
      }
      parsed.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      notifierForCase(caseKey).value = List<CaseProgressStep>.unmodifiable(parsed);
      await _saveCache(caseKey, parsed);
    } catch (e) {
      debugPrint('CaseProgressRepository.refreshCase warning: $e');
    }
  }

  bool _isAuthorizedAdvocateForStep(CaseProgressStep step) {
    if (userProfile.value.role == UserRole.advokat) return true;
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (authId.isNotEmpty &&
        YanRoleDataCatalog.isSameParticipant(step.advocateId, authId)) {
      return true;
    }
    final profileId = userProfile.value.clientId;
    if (profileId.isNotEmpty &&
        YanRoleDataCatalog.isSameParticipant(step.advocateId, profileId)) {
      return true;
    }
    return false;
  }

  Future<String?> upsertStep(CaseProgressStep step) async {
    if (!_isAuthorizedAdvocateForStep(step)) {
      return 'Faqat advokat ish bosqichlarini boshqara oladi.';
    }
    final current = List<CaseProgressStep>.from(
      notifierForCase(step.caseKey).value,
    );
    final idx = current.indexWhere((s) => s.id == step.id);
    if (idx >= 0) {
      current[idx] = step;
    } else {
      current.add(step);
    }
    current.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifierForCase(step.caseKey).value =
        List<CaseProgressStep>.unmodifiable(current);
    await _saveCache(step.caseKey, current);

    try {
      await Supabase.instance.client
          .from('case_progress_steps')
          .upsert(step.toJson());
    } catch (e) {
      debugPrint('CaseProgressRepository.upsertStep warning: $e');
    }
    return null;
  }

  Future<String?> deleteStep(CaseProgressStep step) async {
    if (!_isAuthorizedAdvocateForStep(step)) {
      return 'Faqat advokat ish bosqichlarini o‘chira oladi.';
    }
    final current = List<CaseProgressStep>.from(
      notifierForCase(step.caseKey).value,
    )..removeWhere((s) => s.id == step.id);
    notifierForCase(step.caseKey).value =
        List<CaseProgressStep>.unmodifiable(current);
    await _saveCache(step.caseKey, current);

    try {
      await Supabase.instance.client
          .from('case_progress_steps')
          .delete()
          .eq('id', step.id);
    } catch (e) {
      debugPrint('CaseProgressRepository.deleteStep warning: $e');
    }
    return null;
  }

  /// Uploads a real file from the advocate's device to Supabase Storage and
  /// returns a [CaseStepDocument] metadata record. Supports both in-memory
  /// `bytes` (Android scoped storage via `withData: true`) and direct `file`.
  Future<CaseStepDocument?> uploadDocument({
    required String caseKey,
    required String fileName,
    Uint8List? bytes,
    File? file,
    String localPath = '',
  }) async {
    Uint8List? fileBytes = bytes;
    if ((fileBytes == null || fileBytes.isEmpty) && file != null) {
      try {
        fileBytes = await file.readAsBytes();
      } catch (_) {}
    }
    if (fileBytes == null || fileBytes.isEmpty) return null;

    final docId = 'DOC-${DateTime.now().microsecondsSinceEpoch}';
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    String resolvedLocalPath = localPath.trim();
    if (resolvedLocalPath.isEmpty && file != null) {
      resolvedLocalPath = file.path;
    }
    // Always keep a readable temp copy so the advocate can preview immediately
    try {
      final dir = await getTemporaryDirectory();
      final cached = File(
        '${dir.path}${Platform.pathSeparator}${docId}_$safeName',
      );
      await cached.writeAsBytes(fileBytes, flush: true);
      if (resolvedLocalPath.isEmpty) {
        resolvedLocalPath = cached.path;
      }
    } catch (_) {}

    final storagePath =
        'case_progress/$caseKey/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    String uploadedBucket = 'advocate_licenses';
    String uploadedPath = '';

    for (final bucket in const <String>['advocate_licenses', 'chat_media']) {
      try {
        await Supabase.instance.client.storage.from(bucket).uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        uploadedBucket = bucket;
        uploadedPath = storagePath;
        break;
      } catch (_) {}
    }

    return CaseStepDocument(
      id: docId,
      name: fileName,
      fileType: CaseStepDocument.inferFileType(fileName),
      storagePath: uploadedPath,
      storageBucket: uploadedBucket,
      localPath: resolvedLocalPath,
      uploadedAt: DateTime.now(),
    );
  }

  /// Opens an attached document using the phone's native viewer (downloading
  /// from Supabase Storage first if not already cached locally).
  Future<String?> openDocument(CaseStepDocument doc) async {
    try {
      if (doc.localPath.isNotEmpty) {
        final local = File(doc.localPath);
        if (await local.exists()) {
          final res = await OpenFilex.open(local.path);
          if (res.type != ResultType.done) {
            return 'Faylni ochish uchun mos ilova topilmadi.';
          }
          return null;
        }
      }

      if (doc.storagePath.isEmpty) {
        return 'Hujjat fayli topilmadi.';
      }

      Uint8List? bytes;
      final buckets = <String>[
        doc.storageBucket.isNotEmpty ? doc.storageBucket : 'advocate_licenses',
        doc.storageBucket == 'chat_media' ? 'advocate_licenses' : 'chat_media',
      ];
      for (final bucket in buckets) {
        try {
          bytes = await Supabase.instance.client.storage
              .from(bucket)
              .download(doc.storagePath);
          if (bytes.isNotEmpty) break;
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty) {
        return 'Hujjatni yuklab bo‘lmadi. Internet aloqasini tekshiring.';
      }

      final dir = await getTemporaryDirectory();
      final safeName = doc.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final outFile = File(
        '${dir.path}${Platform.pathSeparator}${doc.id}_$safeName',
      );
      await outFile.writeAsBytes(bytes, flush: true);
      final res = await OpenFilex.open(outFile.path);
      if (res.type != ResultType.done) {
        return 'Faylni ochish uchun mos ilova topilmadi.';
      }
      return null;
    } catch (_) {
      return 'Hujjatni ochishda xatolik yuz berdi.';
    }
  }

  /// Optional starter template for advocates creating a new standard legal case
  /// timeline (mirrors real court workflow: intake, filing, correction, review, closing).
  Future<void> seedStandardCaseTemplate({
    required String advocateId,
    required String clientId,
  }) async {
    final caseKey = buildCaseKey(advocateId, clientId);
    final now = DateTime.now();
    final baseYear = now.year;

    final steps = <CaseProgressStep>[
      CaseProgressStep(
        id: 'STEP-${now.microsecondsSinceEpoch}-1',
        caseKey: caseKey,
        advocateId: advocateId,
        clientId: clientId,
        sortOrder: 0,
        title: 'Dastlabki qabul va hujjatlarni tekshirish',
        shortDescription: 'Mijoz hujjatlari imzolandi va tekshiruvdan o‘tdi.',
        status: CaseStepStatus.completed,
        eventDate: DateTime(baseYear, 10, 12, 9, 30),
        detailedExplanation:
            'Shartnoma va ishonchnoma rasmiylashtirildi, barcha dastlabki dalillar huquqiy ekspertizadan o‘tkazildi.',
        startedAt: DateTime(baseYear, 10, 12, 9, 0),
        completedAt: DateTime(baseYear, 10, 12, 9, 30),
        createdAt: now,
        updatedAt: now,
      ),
      CaseProgressStep(
        id: 'STEP-${now.microsecondsSinceEpoch}-2',
        caseKey: caseKey,
        advocateId: advocateId,
        clientId: clientId,
        sortOrder: 1,
        title: 'Dastlabki da’vo arizasini topshirish',
        shortDescription:
            'Ariza topshirildi, biroq notarial tasdiqlangan ilova yetishmagani sababli qaytarildi.',
        status: CaseStepStatus.failed,
        eventDate: DateTime(baseYear, 10, 18, 14, 15),
        failureReason:
            'Notarial tasdiqlangan qo‘shimcha ilova taqdim etilmagani sababli ariza qabul qilinmadi.',
        actionsTaken: 'Kamchilik bartaraf etilib, qayta topshirish yakunlandi.',
        submittedAt: DateTime(baseYear, 10, 18, 14, 15),
        createdAt: now,
        updatedAt: now,
      ),
      CaseProgressStep(
        id: 'STEP-${now.microsecondsSinceEpoch}-3',
        caseKey: caseKey,
        advocateId: advocateId,
        clientId: clientId,
        sortOrder: 2,
        title: 'Tuzatilgan ariza qabul qilindi',
        shortDescription:
            'Ariza ro‘yxatga olindi va sud ish raqami biriktirildi.',
        status: CaseStepStatus.completed,
        eventDate: DateTime(baseYear, 10, 21, 11, 0),
        detailedExplanation:
            'To‘ldirilgan hujjatlar to‘plami sud devonxonasida rasman ro‘yxatdan o‘tkazildi.',
        submittedAt: DateTime(baseYear, 10, 20, 16, 0),
        decisionAt: DateTime(baseYear, 10, 21, 11, 0),
        completedAt: DateTime(baseYear, 10, 21, 11, 0),
        createdAt: now,
        updatedAt: now,
      ),
      CaseProgressStep(
        id: 'STEP-${now.microsecondsSinceEpoch}-4',
        caseKey: caseKey,
        advocateId: advocateId,
        clientId: clientId,
        sortOrder: 3,
        title: 'Dastlabki ko‘rib chiqish',
        shortDescription: 'Sud majlisi sanasi belgilanishi kutilmoqda.',
        status: CaseStepStatus.inProgress,
        detailedExplanation:
            'Ish materiallari sudya ko‘rib chiqishida. Tayinlangan majlis sanasi e’lon qilinishi bilan xabar beriladi.',
        nextSteps: 'Sud majlisi sanasi tasdiqlangach, ishtirok etish tartibi kelishiladi.',
        startedAt: DateTime(baseYear, 10, 22, 10, 0),
        createdAt: now,
        updatedAt: now,
      ),
      CaseProgressStep(
        id: 'STEP-${now.microsecondsSinceEpoch}-5',
        caseKey: caseKey,
        advocateId: advocateId,
        clientId: clientId,
        sortOrder: 4,
        title: 'Yakuniy qaror va ishni yopish',
        shortDescription: 'Oldingi bosqich yakunlanishi kutilmoqda.',
        status: CaseStepStatus.upcoming,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final s in steps) {
      await upsertStep(s);
    }
  }
}