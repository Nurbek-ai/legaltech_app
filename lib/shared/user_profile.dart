import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import '../services/alimony_claim_document_service.dart';

/// Immutable snapshot of the user's legal profile and security preferences.
class UserProfileData {
  const UserProfileData({
    this.clientId = 'YAN-2026-8492',
    this.displayName = 'Nurbek Otamurodov',
    this.phone = '+998 90 123 45 67',
    this.email = 'nurbek.otamurodov@yan360.uz',
    this.region = 'Toshkent shahri',
    this.district = 'Yunusobod tumani',
    this.streetAddress = 'Mustaqillik MFY, 12-uy',
    this.passportOrPinfl = '',
    this.role = 'Raqamli huquqiy profil',
    this.memberSince = '2026',
    this.isVerified = true,
    this.activeApplications = 1,
    this.savedDocuments = 0,
    this.biometricEnabled = true,
    this.notificationsEnabled = true,
    this.pinCode,
    this.avatarFile,
  });

  final String clientId;
  final String displayName;
  final String phone;
  final String email;
  final String region;
  final String district;
  final String streetAddress;
  final String passportOrPinfl;
  final String role;
  final String memberSince;
  final bool isVerified;

  /// Dynamic stats synced with repository state.
  final int activeApplications;
  final int savedDocuments;

  /// Security & app preferences.
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final String? pinCode;

  /// Local avatar file chosen by the user.
  final File? avatarFile;

  bool get hasPinCode => pinCode != null && pinCode!.trim().length >= 4;

  String get fullAddress {
    final parts = <String>[
      if (region.trim().isNotEmpty) region.trim(),
      if (district.trim().isNotEmpty) district.trim(),
      if (streetAddress.trim().isNotEmpty) streetAddress.trim(),
    ];
    return parts.isEmpty ? 'Manzil kiritilmagan' : parts.join(', ');
  }

  /// Dynamically calculates profile completion from actual filled fields.
  double get profileCompletion {
    var completed = 0;
    const total = 6;
    if (displayName.trim().length >= 3) completed++;
    if (phone.replaceAll(RegExp(r'\D'), '').length >= 9) completed++;
    if (email.trim().contains('@')) completed++;
    if (region.trim().isNotEmpty && district.trim().isNotEmpty) completed++;
    if (streetAddress.trim().isNotEmpty) completed++;
    if (passportOrPinfl.trim().isNotEmpty ||
        avatarFile != null ||
        hasPinCode) {
      completed++;
    }
    return completed / total;
  }

  List<String> get missingProfileItems {
    final missing = <String>[];
    if (displayName.trim().length < 3) missing.add('To‘liq F.I.Sh.');
    if (phone.replaceAll(RegExp(r'\D'), '').length < 9) {
      missing.add('Telefon raqami');
    }
    if (!email.trim().contains('@')) missing.add('Email manzili');
    if (region.trim().isEmpty || district.trim().isEmpty) {
      missing.add('Viloyat va tuman');
    }
    if (streetAddress.trim().isEmpty) missing.add('Yashash manzili');
    if (passportOrPinfl.trim().isEmpty && avatarFile == null && !hasPinCode) {
      missing.add('Pasport / JSHSHIR yoki PIN-kod');
    }
    return missing;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final result = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return result.isEmpty ? 'YA' : result;
  }

  String get completionPercent => '${(profileCompletion * 100).round()}%';

  UserProfileData copyWith({
    String? clientId,
    String? displayName,
    String? phone,
    String? email,
    String? region,
    String? district,
    String? streetAddress,
    String? passportOrPinfl,
    String? role,
    String? memberSince,
    bool? isVerified,
    int? activeApplications,
    int? savedDocuments,
    double? profileCompletion,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    String? pinCode,
    bool clearPinCode = false,
    File? avatarFile,
    bool clearAvatar = false,
  }) {
    return UserProfileData(
      clientId: clientId ?? this.clientId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      region: region ?? this.region,
      district: district ?? this.district,
      streetAddress: streetAddress ?? this.streetAddress,
      passportOrPinfl: passportOrPinfl ?? this.passportOrPinfl,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      isVerified: isVerified ?? this.isVerified,
      activeApplications: activeApplications ?? this.activeApplications,
      savedDocuments: savedDocuments ?? this.savedDocuments,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pinCode: clearPinCode ? null : (pinCode ?? this.pinCode),
      avatarFile: clearAvatar ? null : (avatarFile ?? this.avatarFile),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientId': clientId,
    'displayName': displayName,
    'phone': phone,
    'email': email,
    'region': region,
    'district': district,
    'streetAddress': streetAddress,
    'passportOrPinfl': passportOrPinfl,
    'role': role,
    'memberSince': memberSince,
    'isVerified': isVerified,
    'activeApplications': activeApplications,
    'savedDocuments': savedDocuments,
    'biometricEnabled': biometricEnabled,
    'notificationsEnabled': notificationsEnabled,
    'pinCode': pinCode,
    'avatarPath': avatarFile?.path,
  };

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    final avatarPath = json['avatarPath']?.toString();
    File? avatar;
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      final candidate = File(avatarPath);
      if (candidate.existsSync()) {
        avatar = candidate;
      }
    }
    return UserProfileData(
      clientId: json['clientId']?.toString() ?? 'YAN-2026-8492',
      displayName: json['displayName']?.toString() ?? 'Nurbek Otamurodov',
      phone: json['phone']?.toString() ?? '+998 90 123 45 67',
      email: json['email']?.toString() ?? 'nurbek.otamurodov@yan360.uz',
      region: json['region']?.toString() ?? 'Toshkent shahri',
      district: json['district']?.toString() ?? 'Yunusobod tumani',
      streetAddress:
          json['streetAddress']?.toString() ?? 'Mustaqillik MFY, 12-uy',
      passportOrPinfl: json['passportOrPinfl']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Raqamli huquqiy profil',
      memberSince: json['memberSince']?.toString() ?? '2026',
      isVerified: json['isVerified'] != false,
      activeApplications: (json['activeApplications'] as num?)?.toInt() ?? 1,
      savedDocuments: (json['savedDocuments'] as num?)?.toInt() ?? 0,
      biometricEnabled: json['biometricEnabled'] != false,
      notificationsEnabled: json['notificationsEnabled'] != false,
      pinCode: json['pinCode']?.toString(),
      avatarFile: avatar,
    );
  }
}

class UserProfileNotifier extends ValueNotifier<UserProfileData> {
  UserProfileNotifier() : super(const UserProfileData()) {
    _loadFromDisk();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}user_profile.json');
  }

  Future<void> _loadFromDisk() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        if (raw.trim().isNotEmpty) {
          final map = jsonDecode(raw);
          if (map is Map<String, dynamic>) {
            super.value = UserProfileData.fromJson(map);
          }
        }
      }
    } catch (_) {
      // Ignore load errors and keep default profile
    }
  }

  @override
  set value(UserProfileData newValue) {
    super.value = newValue;
    _saveToDisk(newValue);
  }

  Future<void> update(
    UserProfileData Function(UserProfileData current) fn,
  ) async {
    final updated = fn(value);
    value = updated;
  }

  Future<void> _saveToDisk(UserProfileData data) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(data.toJson()), flush: true);
    } catch (_) {
      // Ignore write errors in restricted environments
    }
  }
}

/// App-wide persistent singleton.
final UserProfileNotifier userProfile = UserProfileNotifier();

// ═══════════════════════════════════════════════════════════════════════════
// Persistent Activity History & Legal Ledger Service
// ═══════════════════════════════════════════════════════════════════════════

enum ActivityCategory {
  documents('Hujjatlar'),
  consultation('Konsultatsiya'),
  lawyer('Advokat'),
  profile('Profil');

  const ActivityCategory(this.label);
  final String label;

  static ActivityCategory fromLabel(String? value) {
    for (final item in ActivityCategory.values) {
      if (item.label.toLowerCase() == (value ?? '').toLowerCase()) {
        return item;
      }
    }
    return ActivityCategory.documents;
  }
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.statusLabel,
    required this.createdAt,
    this.filePath,
    this.referenceCode,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String title;
  final String description;
  final ActivityCategory category;
  final String statusLabel;
  final DateTime createdAt;
  final String? filePath;
  final String? referenceCode;
  final Map<String, String> metadata;

  bool get hasFile => filePath != null && filePath!.trim().isNotEmpty;

  IconData get icon => switch (category) {
    ActivityCategory.documents =>
      hasFile ? CupertinoIcons.doc_checkmark_fill : CupertinoIcons.doc_text_fill,
    ActivityCategory.consultation => CupertinoIcons.videocam_fill,
    ActivityCategory.lawyer => CupertinoIcons.briefcase_fill,
    ActivityCategory.profile => CupertinoIcons.shield_lefthalf_fill,
  };

  Color get accentColor => switch (category) {
    ActivityCategory.documents => const Color(0xFF67E2B8),
    ActivityCategory.consultation => const Color(0xFFFFC979),
    ActivityCategory.lawyer => const Color(0xFF9DBBFF),
    ActivityCategory.profile => const Color(0xFFC8B2FF),
  };

  Color get iconBackground => switch (category) {
    ActivityCategory.documents => const Color(0xFF1A4338),
    ActivityCategory.consultation => const Color(0xFF4B3B24),
    ActivityCategory.lawyer => const Color(0xFF21385C),
    ActivityCategory.profile => const Color(0xFF362C54),
  };

  String get timeFormatted {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get dateFormatted {
    const months = <String>[
      'yanvar',
      'fevral',
      'mart',
      'aprel',
      'may',
      'iyun',
      'iyul',
      'avgust',
      'sentyabr',
      'oktyabr',
      'noyabr',
      'dekabr',
    ];
    return '${createdAt.day}-${months[createdAt.month - 1]}, ${createdAt.year}';
  }

  String groupLabel(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (itemDay == today) return 'Bugun';
    if (itemDay == yesterday) return 'Kecha';
    return dateFormatted;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'category': category.label,
    'statusLabel': statusLabel,
    'createdAt': createdAt.toIso8601String(),
    'filePath': filePath,
    'referenceCode': referenceCode,
    'metadata': metadata,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['metadata'];
    final parsedMeta = <String, String>{};
    if (rawMeta is Map) {
      for (final entry in rawMeta.entries) {
        parsedMeta[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    return ActivityEntry(
      id:
          json['id']?.toString() ??
          'ACT-${DateTime.now().microsecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Faoliyat yozuvi',
      description: json['description']?.toString() ?? '',
      category: ActivityCategory.fromLabel(json['category']?.toString()),
      statusLabel: json['statusLabel']?.toString() ?? 'Bajarildi',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      filePath: json['filePath']?.toString(),
      referenceCode: json['referenceCode']?.toString(),
      metadata: parsedMeta,
    );
  }
}

class ActivityHistoryRepository {
  ActivityHistoryRepository({
    Future<Directory> Function()? appDirectoryProvider,
  }) : _appDirectoryProvider =
           appDirectoryProvider ?? getApplicationDocumentsDirectory;

  static final ActivityHistoryRepository instance = ActivityHistoryRepository();

  final Future<Directory> Function() _appDirectoryProvider;
  final ValueNotifier<List<ActivityEntry>> entries =
      ValueNotifier<List<ActivityEntry>>(<ActivityEntry>[]);

  bool _initialized = false;

  Future<File> _storageFile() async {
    final dir = await _appDirectoryProvider();
    await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}activity_history.json');
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await reload();
  }

  Future<void> reload() async {
    try {
      final file = await _storageFile();
      var loaded = <ActivityEntry>[];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            loaded = decoded
                .whereType<Map<String, dynamic>>()
                .map(ActivityEntry.fromJson)
                .toList();
          }
        }
      } else {
        loaded = _defaultSeedEntries();
      }

      await GeneratedDocumentRepository.instance.reload();
      final docs = GeneratedDocumentRepository.instance.documents.value;
      final existingPaths = loaded
          .map((e) => e.filePath)
          .whereType<String>()
          .toSet();

      var changed = !await file.exists();
      for (final doc in docs) {
        if (!existingPaths.contains(doc.path)) {
          final filename = doc.path.split(Platform.pathSeparator).last;
          loaded.add(
            ActivityEntry(
              id: 'DOC-${doc.createdAt.millisecondsSinceEpoch}',
              title: doc.title,
              description: 'Yaratilgan rasmiy DOCX da’vo arizasi ($filename)',
              category: ActivityCategory.documents,
              statusLabel: 'Tayyor',
              createdAt: doc.createdAt,
              filePath: doc.path,
              referenceCode:
                  '#DOC-${doc.createdAt.millisecondsSinceEpoch.toString().substring(7)}',
              metadata: <String, String>{
                'Hujjat turi': doc.title,
                'Format': 'Microsoft Word (.docx)',
                'Fayl nomi': filename,
                'Holati': 'Hujjatlar bo‘limida saqlangan',
              },
            ),
          );
          changed = true;
        }
      }

      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      entries.value = List<ActivityEntry>.unmodifiable(loaded);
      if (changed) {
        await _persist(loaded);
      }
    } catch (_) {
      if (entries.value.isEmpty) {
        entries.value = List<ActivityEntry>.unmodifiable(_defaultSeedEntries());
      }
    }
  }

  Future<ActivityEntry> record({
    required String title,
    required String description,
    required ActivityCategory category,
    String statusLabel = 'Tayyor',
    String? filePath,
    String? referenceCode,
    Map<String, String> metadata = const <String, String>{},
    DateTime? createdAt,
  }) async {
    await ensureInitialized();
    final now = createdAt ?? DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    final prefix = switch (category) {
      ActivityCategory.documents => 'DOC',
      ActivityCategory.consultation => 'CNS',
      ActivityCategory.lawyer => 'LAW',
      ActivityCategory.profile => 'PRF',
    };
    final entry = ActivityEntry(
      id: '$prefix-${now.microsecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      statusLabel: statusLabel,
      createdAt: now,
      filePath: filePath,
      referenceCode: referenceCode ?? '#$prefix-$suffix',
      metadata: metadata,
    );

    final updated = <ActivityEntry>[entry, ...entries.value];
    updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    entries.value = List<ActivityEntry>.unmodifiable(updated);
    await _persist(updated);
    return entry;
  }

  Future<void> removeById(String id) async {
    final updated = entries.value.where((item) => item.id != id).toList();
    entries.value = List<ActivityEntry>.unmodifiable(updated);
    await _persist(updated);
  }

  Future<void> restoreEntry(ActivityEntry entry) async {
    final updated = <ActivityEntry>[
      entry,
      ...entries.value.where((e) => e.id != entry.id),
    ];
    updated.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    entries.value = List<ActivityEntry>.unmodifiable(updated);
    await _persist(updated);
  }

  Future<void> clearAll() async {
    entries.value = const <ActivityEntry>[];
    await _persist(const <ActivityEntry>[]);
  }

  Future<void> _persist(List<ActivityEntry> list) async {
    try {
      final file = await _storageFile();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded, flush: true);
    } catch (_) {
      // Ignore disk write errors in restricted environments
    }
  }

  List<ActivityEntry> _defaultSeedEntries() {
    final now = DateTime.now();
    return <ActivityEntry>[
      ActivityEntry(
        id: 'PRF-SEED-1',
        title: 'Raqamli yuridik profil faollashtirildi',
        description:
            'YAN360 shaxsiy kabineti va hujjatlar ombori shifrlangan holda ishga tushirildi',
        category: ActivityCategory.profile,
        statusLabel: 'Himoyalangan',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        referenceCode: '#PRF-20261',
        metadata: const <String, String>{
          'Modul': 'YAN360 Shaxsiy Kabinet',
          'Xavfsizlik': 'AES-256 va Biometrik himoya',
          'Holati': 'Tasdiqlangan foydalanuvchi',
        },
      ),
      ActivityEntry(
        id: 'CNS-SEED-2',
        title: 'Advokat konsultatsiyasi bo‘yicha ma’lumotnoma',
        description:
            'Bosh advokat Shohruh Jo‘rayev bilan 20 daqiqalik jonli videomuloqot tizimi tayyor',
        category: ActivityCategory.consultation,
        statusLabel: 'Faol xizmat',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        referenceCode: '#CNS-10492',
        metadata: const <String, String>{
          'Mutaxassis': 'Shohruh Jo‘rayev (YAN Legal Firm)',
          'Davomiyligi': '20 daqiqa (onlayn)',
          'Hudud': 'Toshkent va barcha viloyatlar',
        },
      ),
    ];
  }
}
