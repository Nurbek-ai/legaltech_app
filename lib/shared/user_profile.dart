import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/alimony_claim_document_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// YAN360 4-Role Architecture Enum & Metadata
// ═══════════════════════════════════════════════════════════════════════════

enum UserRole {
  oddiy(
    id: 'oddiy',
    label: 'Oddiy foydalanuvchi',
    shortBadge: 'ODDIY',
    subtitle: 'Bepul hisob • Ariza yozish va advokat topish',
    accentColor: Color(0xFF7CE7FF),
    secondaryColor: Color(0xFF3B82F6),
    icon: CupertinoIcons.person_crop_circle_fill,
  ),
  mijoz(
    id: 'mijoz',
    label: 'Shartnomali mijoz',
    shortBadge: 'MIJOZ VIP',
    subtitle: '3 oy bepul (so‘ng \$3/oy) • 30%–50% maxsus chegirma',
    accentColor: Color(0xFF34D399),
    secondaryColor: Color(0xFF059669),
    icon: CupertinoIcons.checkmark_seal_fill,
  ),
  advokat(
    id: 'advokat',
    label: 'Litsenziyali advokat',
    shortBadge: 'ADVOKAT PRO',
    subtitle: 'YAN Legal Firm hamkori • Mijozlar va shartnomalar',
    accentColor: Color(0xFFFBBF24),
    secondaryColor: Color(0xFFD97706),
    icon: CupertinoIcons.briefcase_fill,
  ),
  yordamchi(
    id: 'yordamchi',
    label: 'Advokat yordamchisi',
    shortBadge: 'YORDAMCHI',
    subtitle: 'Shaxsiy yordamchi • Vazifalar, hujjatlar va mijozlar',
    accentColor: Color(0xFFC084FC),
    secondaryColor: Color(0xFF7C3AED),
    icon: CupertinoIcons.person_2_fill,
  );

  const UserRole({
    required this.id,
    required this.label,
    required this.shortBadge,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.icon,
  });

  final String id;
  final String label;
  final String shortBadge;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final IconData icon;

  static UserRole fromId(String? value) {
    for (final item in UserRole.values) {
      if (item.id == value?.trim().toLowerCase()) {
        return item;
      }
    }
    return UserRole.oddiy;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Immutable Snapshot of User's Legal Profile, Role & Security Preferences
// ═══════════════════════════════════════════════════════════════════════════

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
    this.roleType = UserRole.oddiy,
    this.contractedLawyerId = 'LAW-001',
    this.contractNumber = 'SH-2026/084',
    this.contractSignedAt,
    this.lawyerSubscriptionTier = 2,
    this.assignedLawyerName = 'Shohruh Jo‘rayev',
    this.lawyerLicenseNumber = 'TN-004829',
    this.lawyerSpecialization = 'Oila, mulk va fuqarolik huquqi',
    this.lawyerExperienceYears = 9,
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

  /// 4-Role Architecture fields.
  final UserRole roleType;
  final String? contractedLawyerId;
  final String? contractNumber;
  final DateTime? contractSignedAt;

  /// Lawyer-specific & Assistant-specific fields.
  /// Tier 1 = Start ($19/oy), Tier 2 = Pro ($39/oy), Tier 3 = Elite ($69/oy)
  final int lawyerSubscriptionTier;
  final String assignedLawyerName;
  final String lawyerLicenseNumber;
  final String lawyerSpecialization;
  final int lawyerExperienceYears;

  bool get hasPinCode => pinCode != null && pinCode!.trim().length >= 4;

  /// Dynamic role label that reflects the active 4-role state.
  String get effectiveRoleTitle => roleType.label;

  /// Mijoz automatic discount getters (per YAN360 specification):
  /// - 30% discount on any general service in the app
  /// - 20% discount on lawyer consultations
  /// - 50% discount on template petitions (shablon arizalar)
  double get serviceDiscount => roleType == UserRole.mijoz ? 0.30 : 0.0;
  double get consultationDiscount => roleType == UserRole.mijoz ? 0.20 : 0.0;
  double get templateDiscount => roleType == UserRole.mijoz ? 0.50 : 0.0;

  bool get hasClientDiscounts => roleType == UserRole.mijoz;

  /// Calculates remaining days in the 3-month (90-day) free trial after signing a lawyer contract.
  int get freeTrialDaysRemaining {
    if (roleType != UserRole.mijoz) return 0;
    final signed = contractSignedAt ?? DateTime.now().subtract(const Duration(days: 12));
    final elapsed = DateTime.now().difference(signed).inDays;
    final remaining = 90 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isInFreeTrialPeriod =>
      roleType == UserRole.mijoz && freeTrialDaysRemaining > 0;

  String get subscriptionStatusLabel {
    switch (roleType) {
      case UserRole.oddiy:
        return 'Bepul standart hisob • Shartnoma tuzilmagan';
      case UserRole.mijoz:
        if (isInFreeTrialPeriod) {
          return '3 oylik bepul davr ($freeTrialDaysRemaining kun qoldi) • So‘ng \$3/oy';
        }
        return 'Faol obuna (\$3/oy) • 30%–50% imtiyoz faol';
      case UserRole.advokat:
        final tierName = switch (lawyerSubscriptionTier) {
          1 => 'START obuna (\$19/oy)',
          2 => 'PRO obuna (\$39/oy)',
          _ => 'ELITE obuna (\$69/oy)',
        };
        return '$tierName • Har bir shartnoma uchun komissiya';
      case UserRole.yordamchi:
        return 'Biriktirilgan advokat: $assignedLawyerName';
    }
  }

  /// Calculates discounted price in UZS based on service category.
  int applyDiscount(int basePriceUzs, {String category = 'service'}) {
    final rate = switch (category) {
      'consultation' => consultationDiscount,
      'template' => templateDiscount,
      _ => serviceDiscount,
    };
    return (basePriceUzs * (1.0 - rate)).round();
  }

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
    UserRole? roleType,
    String? contractedLawyerId,
    String? contractNumber,
    DateTime? contractSignedAt,
    int? lawyerSubscriptionTier,
    String? assignedLawyerName,
    String? lawyerLicenseNumber,
    String? lawyerSpecialization,
    int? lawyerExperienceYears,
  }) {
    final nextRoleType = roleType ?? this.roleType;
    return UserProfileData(
      clientId: clientId ?? this.clientId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      region: region ?? this.region,
      district: district ?? this.district,
      streetAddress: streetAddress ?? this.streetAddress,
      passportOrPinfl: passportOrPinfl ?? this.passportOrPinfl,
      role: role ?? (roleType != null ? roleType.label : this.role),
      memberSince: memberSince ?? this.memberSince,
      isVerified: isVerified ?? this.isVerified,
      activeApplications: activeApplications ?? this.activeApplications,
      savedDocuments: savedDocuments ?? this.savedDocuments,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pinCode: clearPinCode ? null : (pinCode ?? this.pinCode),
      avatarFile: clearAvatar ? null : (avatarFile ?? this.avatarFile),
      roleType: nextRoleType,
      contractedLawyerId: contractedLawyerId ?? this.contractedLawyerId,
      contractNumber: contractNumber ?? this.contractNumber,
      contractSignedAt: contractSignedAt ?? this.contractSignedAt,
      lawyerSubscriptionTier:
          lawyerSubscriptionTier ?? this.lawyerSubscriptionTier,
      assignedLawyerName: assignedLawyerName ?? this.assignedLawyerName,
      lawyerLicenseNumber: lawyerLicenseNumber ?? this.lawyerLicenseNumber,
      lawyerSpecialization: lawyerSpecialization ?? this.lawyerSpecialization,
      lawyerExperienceYears:
          lawyerExperienceYears ?? this.lawyerExperienceYears,
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
    'roleType': roleType.id,
    'contractedLawyerId': contractedLawyerId,
    'contractNumber': contractNumber,
    'contractSignedAt': contractSignedAt?.toIso8601String(),
    'lawyerSubscriptionTier': lawyerSubscriptionTier,
    'assignedLawyerName': assignedLawyerName,
    'lawyerLicenseNumber': lawyerLicenseNumber,
    'lawyerSpecialization': lawyerSpecialization,
    'lawyerExperienceYears': lawyerExperienceYears,
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
    final parsedRole = UserRole.fromId(json['roleType']?.toString());
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
      role: json['role']?.toString() ?? parsedRole.label,
      memberSince: json['memberSince']?.toString() ?? '2026',
      isVerified: json['isVerified'] != false,
      activeApplications: (json['activeApplications'] as num?)?.toInt() ?? 1,
      savedDocuments: (json['savedDocuments'] as num?)?.toInt() ?? 0,
      biometricEnabled: json['biometricEnabled'] != false,
      notificationsEnabled: json['notificationsEnabled'] != false,
      pinCode: json['pinCode']?.toString(),
      avatarFile: avatar,
      roleType: parsedRole,
      contractedLawyerId: json['contractedLawyerId']?.toString() ?? 'LAW-001',
      contractNumber: json['contractNumber']?.toString() ?? 'SH-2026/084',
      contractSignedAt: DateTime.tryParse(
        json['contractSignedAt']?.toString() ?? '',
      ),
      lawyerSubscriptionTier:
          (json['lawyerSubscriptionTier'] as num?)?.toInt() ?? 2,
      assignedLawyerName:
          json['assignedLawyerName']?.toString() ?? 'Shohruh Jo‘rayev',
      lawyerLicenseNumber:
          json['lawyerLicenseNumber']?.toString() ?? 'TN-004829',
      lawyerSpecialization:
          json['lawyerSpecialization']?.toString() ??
          'Oila, mulk va fuqarolik huquqi',
      lawyerExperienceYears:
          (json['lawyerExperienceYears'] as num?)?.toInt() ?? 9,
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

  /// Switches the active role and records the transition in ActivityHistoryRepository.
  Future<void> switchRole(
    UserRole targetRole, {
    String? lawyerId,
    String? contractNo,
  }) async {
    final now = DateTime.now();
    value = value.copyWith(
      roleType: targetRole,
      role: targetRole.label,
      contractedLawyerId: lawyerId ?? value.contractedLawyerId ?? 'LAW-001',
      contractNumber:
          contractNo ??
          value.contractNumber ??
          'SH-${now.year}/${100 + now.second}',
      contractSignedAt: targetRole == UserRole.mijoz
          ? (value.contractSignedAt ?? now)
          : value.contractSignedAt,
    );
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
// YAN360 Lawyer Directory, Client Feedback, Contracts & Assistant Models
// ═══════════════════════════════════════════════════════════════════════════

class LawyerFeedbackItem {
  const LawyerFeedbackItem({
    required this.clientName,
    required this.comment,
    required this.rating,
    required this.dateLabel,
    required this.caseType,
  });

  final String clientName;
  final String comment;
  final double rating;
  final String dateLabel;
  final String caseType;
}

class LawyerDirectoryProfile {
  const LawyerDirectoryProfile({
    required this.id,
    required this.fullName,
    required this.title,
    required this.region,
    required this.specialization,
    required this.experienceYears,
    required this.rating,
    required this.feedbackCount,
    required this.wonCasesCount,
    required this.consultationPriceUzs,
    required this.contractMonthlyNote,
    required this.licenseNumber,
    required this.phone,
    required this.assistantName,
    required this.assistantRole,
    required this.assistantPhone,
    required this.bio,
    required this.feedbacks,
    this.isVerifiedPartner = true,
  });

  final String id;
  final String fullName;
  final String title;
  final String region;
  final String specialization;
  final int experienceYears;
  final double rating;
  final int feedbackCount;
  final int wonCasesCount;
  final int consultationPriceUzs;
  final String contractMonthlyNote;
  final String licenseNumber;
  final String phone;
  final String assistantName;
  final String assistantRole;
  final String assistantPhone;
  final String bio;
  final List<LawyerFeedbackItem> feedbacks;
  final bool isVerifiedPartner;

  /// Composite ranking score so lawyers with higher and more feedback appear at the top.
  double get rankingScore => rating * 20.0 + (feedbackCount * 0.35);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((e) => e.isEmpty ? '' : e[0]).join().toUpperCase();
  }
}

class LegalContractItem {
  const LegalContractItem({
    required this.contractNumber,
    required this.clientName,
    required this.clientPhone,
    required this.region,
    required this.caseCategory,
    required this.signedDate,
    required this.statusLabel,
    required this.feeAmountUzs,
    required this.isPaid,
  });

  final String contractNumber;
  final String clientName;
  final String clientPhone;
  final String region;
  final String caseCategory;
  final String signedDate;
  final String statusLabel;
  final int feeAmountUzs;
  final bool isPaid;
}

class AssistantTaskItem {
  const AssistantTaskItem({
    required this.id,
    required this.title,
    required this.clientName,
    required this.assignedByLawyer,
    required this.deadlineLabel,
    required this.categoryLabel,
    required this.priorityLabel,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String clientName;
  final String assignedByLawyer;
  final String deadlineLabel;
  final String categoryLabel;
  final String priorityLabel;
  final bool isCompleted;

  AssistantTaskItem copyWith({bool? isCompleted}) {
    return AssistantTaskItem(
      id: id,
      title: title,
      clientName: clientName,
      assignedByLawyer: assignedByLawyer,
      deadlineLabel: deadlineLabel,
      categoryLabel: categoryLabel,
      priorityLabel: priorityLabel,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class YanRoleDataCatalog {
  YanRoleDataCatalog._();

  static const List<String> regions = <String>[
    'Barchasi',
    'Toshkent shahri',
    'Toshkent viloyati',
    'Samarqand viloyati',
    'Farg‘ona viloyati',
    'Buxoro viloyati',
    'Andijon viloyati',
    'Namangan viloyati',
    'Qashqadaryo viloyati',
  ];

  static const List<String> specializations = <String>[
    'Barchasi',
    'Oila va aliment huquqi',
    'Fuqarolik va mulk huquqi',
    'Mehnat va shartnoma huquqi',
    'Biznes va korporativ huquq',
    'Jinoyat va ma’muriy himoya',
  ];

  static const List<LawyerDirectoryProfile> lawyers = <LawyerDirectoryProfile>[
    LawyerDirectoryProfile(
      id: 'LAW-001',
      fullName: 'Shohruh Jo‘rayev',
      title: 'YAN Legal Firm Bosh advokati',
      region: 'Toshkent shahri',
      specialization: 'Oila va aliment huquqi',
      experienceYears: 11,
      rating: 4.98,
      feedbackCount: 184,
      wonCasesCount: 412,
      consultationPriceUzs: 250000,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: 'TN-004829',
      phone: '+998 90 945 11 22',
      assistantName: 'Madina Karimova',
      assistantRole: 'Katta advokat yordamchisi • Hujjatlar va sud monitoringi',
      assistantPhone: '+998 90 945 11 23',
      bio:
          'Oila, aliment, nikohdan ajratish va mulkiy nizolar bo‘yicha 11 yillik tajribaga ega oliy toifali advokat.',
      feedbacks: <LawyerFeedbackItem>[
        LawyerFeedbackItem(
          clientName: 'Dilnoza R.',
          comment:
              'Aliment va bola yashash joyi bo‘yicha sud jarayonini juda tez va professional hal qilib berdilar.',
          rating: 5.0,
          dateLabel: '2 kun oldin',
          caseType: 'Aliment va oila nizosi',
        ),
        LawyerFeedbackItem(
          clientName: 'Javohir M.',
          comment:
              'Shartnoma tuzganimdan so‘ng barcha arizalarga 50% chegirma berildi, advokat yordamchisi ham doim aloqada.',
          rating: 5.0,
          dateLabel: '1 hafta oldin',
          caseType: 'Yuridik hamkorlik',
        ),
      ],
    ),
    LawyerDirectoryProfile(
      id: 'LAW-002',
      fullName: 'Kamola Islomova',
      title: 'Katta hamkor advokat',
      region: 'Toshkent shahri',
      specialization: 'Fuqarolik va mulk huquqi',
      experienceYears: 9,
      rating: 4.95,
      feedbackCount: 146,
      wonCasesCount: 318,
      consultationPriceUzs: 220000,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: 'TN-005194',
      phone: '+998 93 512 88 90',
      assistantName: 'Sardor Yo‘ldoshev',
      assistantRole: 'Advokat yordamchisi • Kadastr va da’vo arizalari',
      assistantPhone: '+998 93 512 88 91',
      bio:
          'Uy-joy, meros, shartnoma majburiyatlari va oilaviy mulk taqsimoti bo‘yicha yetakchi mutaxassis.',
      feedbacks: <LawyerFeedbackItem>[
        LawyerFeedbackItem(
          clientName: 'Otabek T.',
          comment:
              'Uy-joy va ulush masalasida barcha hujjatlarni qonuniy asoslab sudda yutib chiqdik.',
          rating: 5.0,
          dateLabel: '3 kun oldin',
          caseType: 'Mulk huquqi',
        ),
      ],
    ),
    LawyerDirectoryProfile(
      id: 'LAW-003',
      fullName: 'bekzod Rahmonov',
      title: 'Viloyat bo‘limi bosh advokati',
      region: 'Samarqand viloyati',
      specialization: 'Oila va aliment huquqi',
      experienceYears: 8,
      rating: 4.91,
      feedbackCount: 118,
      wonCasesCount: 265,
      consultationPriceUzs: 180000,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: 'SM-002310',
      phone: '+998 91 540 77 11',
      assistantName: 'Zarina Normurodova',
      assistantRole: 'Advokat yordamchisi • Sudga arizalar tayyorlash',
      assistantPhone: '+998 91 540 77 12',
      bio:
          'Samarqand va qo‘shni viloyatlarda oilaviy nizolar, aliment va nikoh shartnomalari bo‘yicha 8 yillik amaliyot.',
      feedbacks: <LawyerFeedbackItem>[
        LawyerFeedbackItem(
          clientName: 'Mohira S.',
          comment:
              'Masofadan turib shartnoma imzoladik, sudga bormasdan barcha hujjatlar tayyorlandi.',
          rating: 4.9,
          dateLabel: '5 kun oldin',
          caseType: 'Ona ta’minoti va aliment',
        ),
      ],
    ),
    LawyerDirectoryProfile(
      id: 'LAW-004',
      fullName: 'Ulug‘bek Xolmatov',
      title: 'Korporativ va mehnat huquqi advokati',
      region: 'Farg‘ona viloyati',
      specialization: 'Mehnat va shartnoma huquqi',
      experienceYears: 12,
      rating: 4.89,
      feedbackCount: 104,
      wonCasesCount: 290,
      consultationPriceUzs: 200000,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: 'FR-001982',
      phone: '+998 94 611 33 44',
      assistantName: 'Abrorjon Toirov',
      assistantRole: 'Advokat yordamchisi • Shartnomalar ekspertizasi',
      assistantPhone: '+998 94 611 33 45',
      bio:
          'Mehnat nizolari, ishga tiklash, kompensatsiya undirish va tadbirkorlik shartnomalari bo‘yicha katta advokat.',
      feedbacks: <LawyerFeedbackItem>[
        LawyerFeedbackItem(
          clientName: 'Sanjar K.',
          comment:
              'Ishdan noqonuniy bo‘shatilganim bo‘yicha da’vo arizasi yozilib, to‘liq kompensatsiya undirildi.',
          rating: 4.9,
          dateLabel: '1 hafta oldin',
          caseType: 'Mehnat huquqi',
        ),
      ],
    ),
    LawyerDirectoryProfile(
      id: 'LAW-005',
      fullName: 'Nilufar Qodirova',
      title: 'Oila va bolalar huquqi advokati',
      region: 'Buxoro viloyati',
      specialization: 'Oila va aliment huquqi',
      experienceYears: 6,
      rating: 4.86,
      feedbackCount: 79,
      wonCasesCount: 164,
      consultationPriceUzs: 170000,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: 'BX-001450',
      phone: '+998 97 302 45 67',
      assistantName: 'Nigina Saidova',
      assistantRole: 'Advokat yordamchisi • Mijozlar bilan ishlash',
      assistantPhone: '+998 97 302 45 68',
      bio:
          'Bola bilan ko‘rishish tartibi, aliment miqdorini o‘zgartirish va vasiylik masalalari bo‘yicha ixtisoslashgan advokat.',
      feedbacks: <LawyerFeedbackItem>[
        LawyerFeedbackItem(
          clientName: 'Gulnoza A.',
          comment:
              'Juda samimiy va professional yondashuv, barcha savollarimga aniq yechim berishdi.',
          rating: 4.9,
          dateLabel: '2 hafta oldin',
          caseType: 'Bola bilan ko‘rishish tartibi',
        ),
      ],
    ),
  ];

  static LawyerDirectoryProfile byId(String? id) {
    for (final lawyer in lawyers) {
      if (lawyer.id == id) return lawyer;
    }
    return lawyers.first;
  }

  static const List<LegalContractItem> sampleContracts = <LegalContractItem>[
    LegalContractItem(
      contractNumber: 'SH-2026/084',
      clientName: 'Nurbek Otamurodov',
      clientPhone: '+998 90 123 45 67',
      region: 'Toshkent shahri',
      caseCategory: 'Bolaga aliment va yashash joyini belgilash',
      signedDate: '05.11.2026',
      statusLabel: 'Faol shartnoma',
      feeAmountUzs: 1800000,
      isPaid: true,
    ),
    LegalContractItem(
      contractNumber: 'SH-2026/081',
      clientName: 'Malika Abdullayeva',
      clientPhone: '+998 93 441 92 10',
      region: 'Toshkent shahri',
      caseCategory: 'Ona ta’minoti va nikohdan ajrashish da’vosi',
      signedDate: '02.11.2026',
      statusLabel: 'Sud jarayonida',
      feeAmountUzs: 2400000,
      isPaid: true,
    ),
    LegalContractItem(
      contractNumber: 'SH-2026/076',
      clientName: 'Rustamjon Karimov',
      clientPhone: '+998 99 812 04 55',
      region: 'Samarqand viloyati',
      caseCategory: 'Mulkiy ulush va meros huquqi',
      signedDate: '28.10.2026',
      statusLabel: 'Ekspertizada',
      feeAmountUzs: 3200000,
      isPaid: true,
    ),
    LegalContractItem(
      contractNumber: 'SH-2026/069',
      clientName: 'Sevara Mirzayeva',
      clientPhone: '+998 97 701 33 19',
      region: 'Toshkent viloyati',
      caseCategory: 'Bola bilan ko‘rishish tartibini belgilash',
      signedDate: '21.10.2026',
      statusLabel: 'Yakunlangan',
      feeAmountUzs: 1500000,
      isPaid: true,
    ),
  ];

  static final ValueNotifier<List<AssistantTaskItem>> assistantTasks =
      ValueNotifier<List<AssistantTaskItem>>(<AssistantTaskItem>[
        const AssistantTaskItem(
          id: 'TSK-101',
          title: 'Nurbek Otamurodov ishi bo‘yicha DOCX da’vo arizasini tekshirish',
          clientName: 'Nurbek Otamurodov',
          assignedByLawyer: 'Shohruh Jo‘rayev',
          deadlineLabel: 'Bugun, 17:30',
          categoryLabel: 'Da’vo arizasi',
          priorityLabel: 'Muhim',
          isCompleted: false,
        ),
        const AssistantTaskItem(
          id: 'TSK-102',
          title: 'Fuqarolik ishlari bo‘yicha Yunusobod sudiga ilova hujjatlarni yuklash',
          clientName: 'Malika Abdullayeva',
          assignedByLawyer: 'Shohruh Jo‘rayev',
          deadlineLabel: 'Ertaga, 11:00',
          categoryLabel: 'E-Sud monitoring',
          priorityLabel: 'Yuqori',
          isCompleted: false,
        ),
        const AssistantTaskItem(
          id: 'TSK-103',
          title: 'Mijoz bilan 20 daqiqalik videomuloqot vaqtini tasdiqlash',
          clientName: 'Rustamjon Karimov',
          assignedByLawyer: 'Shohruh Jo‘rayev',
          deadlineLabel: '07.11.2026',
          categoryLabel: 'Konsultatsiya',
          priorityLabel: 'Rejadagi',
          isCompleted: true,
        ),
        const AssistantTaskItem(
          id: 'TSK-104',
          title: 'Nikohdan ajrashish bo‘yicha guvohnoma va tug‘ilganlik ma’lumotlarini solishtirish',
          clientName: 'Sevara Mirzayeva',
          assignedByLawyer: 'Shohruh Jo‘rayev',
          deadlineLabel: '08.11.2026',
          categoryLabel: 'Hujjat tahlili',
          priorityLabel: 'Tayyor',
          isCompleted: true,
        ),
      ]);

  static void toggleTask(String id) {
    assistantTasks.value = assistantTasks.value
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList(growable: false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared Frosted Pearl-Blue & Silver-Rim Liquid Window UI Components
// (Hardware-accelerated, zero-lag, matches BoshSahifaPage aesthetic)
// ═══════════════════════════════════════════════════════════════════════════

class LiquidGlassWindow extends StatelessWidget {
  const LiquidGlassWindow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.accentGlowColor,
    this.onTap,
    this.isHighlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentGlowColor;
  final VoidCallback? onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final glow = accentGlowColor ?? const Color(0xFF7CE7FF);
    final card = RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHighlighted
                ? <Color>[
                    const Color(0xFF8AB2F8).withValues(alpha: 0.44),
                    const Color(0xFF5A84D2).withValues(alpha: 0.34),
                    const Color(0xFF2D549E).withValues(alpha: 0.46),
                    const Color(0xFF1A3772).withValues(alpha: 0.62),
                  ]
                : <Color>[
                    const Color(0xFF7FA4E8).withValues(alpha: 0.34),
                    const Color(0xFF537BC4).withValues(alpha: 0.25),
                    const Color(0xFF2B5096).withValues(alpha: 0.38),
                    const Color(0xFF19356E).withValues(alpha: 0.54),
                  ],
            stops: const <double>[0.0, 0.32, 0.70, 1.0],
          ),
          border: Border.all(
            color: isHighlighted
                ? glow.withValues(alpha: 0.72)
                : const Color(0xFFDCEBFF).withValues(alpha: 0.38),
            width: isHighlighted ? 1.45 : 1.15,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF071535).withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: glow.withValues(alpha: isHighlighted ? 0.22 : 0.10),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Container(
                  height: 1.3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.68),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class LiquidActionButton extends StatefulWidget {
  const LiquidActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accentColor = const Color(0xFF63B3FF),
    this.isPrimary = true,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;
  final bool isPrimary;
  final bool compact;

  @override
  State<LiquidActionButton> createState() => _LiquidActionButtonState();
}

class _LiquidActionButtonState extends State<LiquidActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 13 : 16,
            vertical: widget.compact ? 10 : 13.5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 17),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isPrimary
                  ? <Color>[
                      widget.accentColor.withValues(alpha: 0.92),
                      const Color(0xFF356AE6).withValues(alpha: 0.92),
                      const Color(0xFF1F47AA).withValues(alpha: 0.96),
                    ]
                  : <Color>[
                      const Color(0xFF83A8EC).withValues(alpha: 0.32),
                      const Color(0xFF3D66B4).withValues(alpha: 0.28),
                      const Color(0xFF1E3E82).withValues(alpha: 0.44),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: widget.isPrimary ? 0.52 : 0.34,
              ),
              width: 1.1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.accentColor.withValues(
                  alpha: widget.isPrimary ? 0.28 : 0.12,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: widget.compact ? 15.5 : 17.5,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.compact ? 12.5 : 13.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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