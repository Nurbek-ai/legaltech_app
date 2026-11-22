import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/alimony_claim_document_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// YAN360 Premium LegalTech Color & Typography Design System (#FEFEFA)
// ═══════════════════════════════════════════════════════════════════════════

class YanColors {
  YanColors._();

  /// Exact Primary Background Color (#FEFEFA | RGB: 254, 254, 250)
  static const Color background = Color(0xFFFEFEFA);

  /// Primary Navy (#102B57) — Headings & primary typography
  static const Color primaryNavy = Color(0xFF102B57);

  /// Primary Blue (#1677D2) — Primary solid buttons & active states
  static const Color primaryBlue = Color(0xFF1677D2);

  /// Cyan Accent (#08BDEB) — Small brand accents
  static const Color cyanAccent = Color(0xFF08BDEB);

  /// Light Blue (#EAF5FF) — Secondary solid buttons & soft badges
  static const Color lightBlue = Color(0xFFEAF5FF);

  /// Pure White (#FFFFFF) — Card surfaces & neutral solid buttons
  static const Color white = Color(0xFFFFFFFF);

  /// Success Green (#10C995) — Exclusively for success states & verification
  static const Color successGreen = Color(0xFF10C995);

  /// Supporting / Muted Navy-Gray for readable subtitles
  static const Color mutedText = Color(0xFF546B8C);
  static const Color subtleText = Color(0xFF7B90AE);

  /// Delicate surface borders & dividers
  static const Color border = Color(0xFFDCE9F7);
  static const Color divider = Color(0xFFE4EEF8);

  /// Destructive solid red when necessary
  static const Color destructiveRed = Color(0xFFE53935);
}

// ═══════════════════════════════════════════════════════════════════════════
// YAN360 4-Role Architecture Enum & Metadata
// ═══════════════════════════════════════════════════════════════════════════

enum UserRole {
  oddiy(
    id: 'oddiy',
    label: 'Oddiy foydalanuvchi',
    shortBadge: 'ODDIY',
    subtitle: 'Bepul standart hisob • Shartnoma tuzilmagan',
    accentColor: YanColors.primaryBlue,
    secondaryColor: YanColors.cyanAccent,
    icon: CupertinoIcons.person_crop_circle_fill,
  ),
  mijoz(
    id: 'mijoz',
    label: 'Shartnomali mijoz',
    shortBadge: 'MIJOZ VIP',
    subtitle: '3 oy bepul (so‘ng \$3/oy) • 30%–50% maxsus chegirma',
    accentColor: YanColors.successGreen,
    secondaryColor: YanColors.primaryBlue,
    icon: CupertinoIcons.checkmark_seal_fill,
  ),
  advokat(
    id: 'advokat',
    label: 'Litsenziyali advokat',
    shortBadge: 'ADVOKAT PRO',
    subtitle: 'YAN Legal Firm hamkori • Mijozlar va shartnomalar',
    accentColor: YanColors.primaryNavy,
    secondaryColor: YanColors.primaryBlue,
    icon: CupertinoIcons.briefcase_fill,
  ),
  yordamchi(
    id: 'yordamchi',
    label: 'Advokat yordamchisi',
    shortBadge: 'YORDAMCHI',
    subtitle: 'Shaxsiy yordamchi • Vazifalar, hujjatlar va mijozlar',
    accentColor: YanColors.cyanAccent,
    secondaryColor: YanColors.primaryBlue,
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
    this.clientId = '',
    this.displayName = '',
    this.phone = '',
    this.email = '',
    this.region = '',
    this.district = '',
    this.streetAddress = '',
    this.passportOrPinfl = '',
    this.role = 'Raqamli huquqiy profil',
    this.memberSince = '2026',
    this.isVerified = true,
    this.activeApplications = 0,
    this.savedDocuments = 0,
    this.biometricEnabled = true,
    this.notificationsEnabled = true,
    this.pinCode,
    this.avatarFile,
    this.avatarBase64 = '',
    this.roleType = UserRole.oddiy,
    this.contractedLawyerId,
    this.contractNumber,
    this.contractSignedAt,
    this.lawyerSubscriptionTier = 2,
    this.assignedLawyerName = 'Biriktirilmagan',
    this.lawyerLicenseNumber = '',
    this.lawyerSpecialization = '',
    this.lawyerExperienceYears = 0,
    this.lawyerBio = '',
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
  final String avatarBase64;

  /// 4-Role Architecture fields.
  final UserRole roleType;
  final String? contractedLawyerId;
  final String? contractNumber;
  final DateTime? contractSignedAt;

  /// Lawyer-specific & Assistant-specific fields.
  final int lawyerSubscriptionTier;
  final String assignedLawyerName;
  final String lawyerLicenseNumber;
  final String lawyerSpecialization;
  final int lawyerExperienceYears;
  final String lawyerBio;

  bool get hasPinCode => pinCode != null && pinCode!.trim().length >= 4;

  String get effectiveRoleTitle => roleType.label;

  double get serviceDiscount => roleType == UserRole.mijoz ? 0.30 : 0.0;
  double get consultationDiscount => roleType == UserRole.mijoz ? 0.20 : 0.0;
  double get templateDiscount => roleType == UserRole.mijoz ? 0.50 : 0.0;

  bool get hasClientDiscounts => roleType == UserRole.mijoz;

  int get freeTrialDaysRemaining {
    if (roleType != UserRole.mijoz) return 0;
    final signed =
        contractSignedAt ?? DateTime.now().subtract(const Duration(days: 12));
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

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'Foydalanuvchi';
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
    String? avatarBase64,
    bool clearAvatar = false,
    UserRole? roleType,
    String? contractedLawyerId,
    bool clearContractedLawyer = false,
    String? contractNumber,
    DateTime? contractSignedAt,
    int? lawyerSubscriptionTier,
    String? assignedLawyerName,
    String? lawyerLicenseNumber,
    String? lawyerSpecialization,
    int? lawyerExperienceYears,
    String? lawyerBio,
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
      avatarBase64: clearAvatar ? '' : (avatarBase64 ?? this.avatarBase64),
      roleType: nextRoleType,
      contractedLawyerId: clearContractedLawyer
          ? null
          : (contractedLawyerId ?? this.contractedLawyerId),
      contractNumber: clearContractedLawyer
          ? null
          : (contractNumber ?? this.contractNumber),
      contractSignedAt: contractSignedAt ?? this.contractSignedAt,
      lawyerSubscriptionTier:
          lawyerSubscriptionTier ?? this.lawyerSubscriptionTier,
      assignedLawyerName: assignedLawyerName ?? this.assignedLawyerName,
      lawyerLicenseNumber: lawyerLicenseNumber ?? this.lawyerLicenseNumber,
      lawyerSpecialization: lawyerSpecialization ?? this.lawyerSpecialization,
      lawyerExperienceYears:
          lawyerExperienceYears ?? this.lawyerExperienceYears,
      lawyerBio: lawyerBio ?? this.lawyerBio,
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
    'avatarBase64': avatarBase64,
    'roleType': roleType.id,
    'contractedLawyerId': contractedLawyerId,
    'contractNumber': contractNumber,
    'contractSignedAt': contractSignedAt?.toIso8601String(),
    'lawyerSubscriptionTier': lawyerSubscriptionTier,
    'assignedLawyerName': assignedLawyerName,
    'lawyerLicenseNumber': lawyerLicenseNumber,
    'lawyerSpecialization': lawyerSpecialization,
    'lawyerExperienceYears': lawyerExperienceYears,
    'lawyerBio': lawyerBio,
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
    var loadedRegion = (json['region']?.toString() ?? '').trim();
    var loadedDistrict = (json['district']?.toString() ?? '').trim();
    var loadedStreet = (json['streetAddress']?.toString() ?? '').trim();
    var loadedPassport = (json['passportOrPinfl']?.toString() ?? '').trim();

    // Purge legacy hardcoded demo defaults saved in old local user_profile.json files
    if (loadedStreet == 'Mustaqillik MFY, 12-uy') {
      loadedStreet = '';
      if (loadedDistrict == 'Yunusobod tumani') loadedDistrict = '';
      if (loadedRegion == 'Toshkent shahri') loadedRegion = '';
    }
    if (loadedPassport == 'AA 4829104' ||
        loadedPassport == 'AA 4829104 (Tasdiqlangan)') {
      loadedPassport = '';
    }

    return UserProfileData(
      clientId: json['clientId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      region: loadedRegion,
      district: loadedDistrict,
      streetAddress: loadedStreet,
      passportOrPinfl: loadedPassport,
      role: json['role']?.toString() ?? parsedRole.label,
      memberSince: json['memberSince']?.toString() ?? '2026',
      isVerified: json['isVerified'] != false,
      activeApplications: (json['activeApplications'] as num?)?.toInt() ?? 0,
      savedDocuments: (json['savedDocuments'] as num?)?.toInt() ?? 0,
      biometricEnabled: json['biometricEnabled'] != false,
      notificationsEnabled: json['notificationsEnabled'] != false,
      pinCode: json['pinCode']?.toString(),
      avatarFile: avatar,
      avatarBase64: json['avatarBase64']?.toString() ?? '',
      roleType: parsedRole,
      contractedLawyerId: (json['contractedLawyerId']?.toString().startsWith('LAW-') ?? true)
          ? null
          : json['contractedLawyerId']?.toString(),
      contractNumber: json['contractNumber']?.toString(),
      contractSignedAt: DateTime.tryParse(
        json['contractSignedAt']?.toString() ?? '',
      ),
      lawyerSubscriptionTier:
          (json['lawyerSubscriptionTier'] as num?)?.toInt() ?? 2,
      assignedLawyerName:
          json['assignedLawyerName']?.toString() ?? 'Biriktirilmagan',
      lawyerLicenseNumber:
          json['lawyerLicenseNumber']?.toString() ?? '',
      lawyerSpecialization:
          json['lawyerSpecialization']?.toString() ?? '',
      lawyerExperienceYears:
          (json['lawyerExperienceYears'] as num?)?.toInt() ?? 0,
      lawyerBio: json['lawyerBio']?.toString() ?? '',
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
    } catch (_) {}
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

  Future<void> switchRole(
    UserRole targetRole, {
    String? lawyerId,
    String? contractNo,
  }) async {
    final now = DateTime.now();
    value = value.copyWith(
      roleType: targetRole,
      role: targetRole.label,
      contractedLawyerId: lawyerId ?? value.contractedLawyerId,
      contractNumber:
          contractNo ??
          value.contractNumber ??
          (targetRole == UserRole.mijoz
              ? 'SH-${now.year}/${100 + now.second}'
              : null),
      contractSignedAt: targetRole == UserRole.mijoz
          ? (value.contractSignedAt ?? now)
          : value.contractSignedAt,
    );
  }

  Future<void> _saveToDisk(UserProfileData data) async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(data.toJson()), flush: true);
    } catch (_) {}
  }
}

/// App-wide persistent singleton.
final UserProfileNotifier userProfile = UserProfileNotifier();

// ═══════════════════════════════════════════════════════════════════════════
// YAN360 Real Lawyer Directory, Client Feedback, Contracts & Assistant Models
// (Zero hardcoded fake profiles; populated dynamically from Supabase!)
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
    this.avatarBase64 = '',
    this.avatarUrl = '',
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
  final String avatarBase64;
  final String avatarUrl;

  double get rankingScore => rating * 20.0 + (feedbackCount * 0.35);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final res = parts
        .take(2)
        .map((e) => e.isEmpty ? '' : e[0])
        .join()
        .toUpperCase();
    return res.isEmpty ? 'AD' : res;
  }

  LawyerDirectoryProfile copyWith({
    double? rating,
    int? feedbackCount,
    int? wonCasesCount,
    List<LawyerFeedbackItem>? feedbacks,
    String? avatarBase64,
    String? avatarUrl,
  }) {
    return LawyerDirectoryProfile(
      id: id,
      fullName: fullName,
      title: title,
      region: region,
      specialization: specialization,
      experienceYears: experienceYears,
      rating: rating ?? this.rating,
      feedbackCount: feedbackCount ?? this.feedbackCount,
      wonCasesCount: wonCasesCount ?? this.wonCasesCount,
      consultationPriceUzs: consultationPriceUzs,
      contractMonthlyNote: contractMonthlyNote,
      licenseNumber: licenseNumber,
      phone: phone,
      assistantName: assistantName,
      assistantRole: assistantRole,
      assistantPhone: assistantPhone,
      bio: bio,
      feedbacks: feedbacks ?? this.feedbacks,
      isVerifiedPartner: isVerifiedPartner,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory LawyerDirectoryProfile.fromSupabaseMap(Map<String, dynamic> row) {
    String cleanText(dynamic value) {
      final v = (value?.toString() ?? '').trim();
      return v;
    }

    String cleanPhone(dynamic value) {
      final v = (value?.toString() ?? '').trim();
      if (v.isEmpty || v == '+998' || v == '998') return '';
      return v;
    }

    int parseExp(dynamic value) {
      if (value is num) return value.toInt() > 0 ? value.toInt() : 0;
      final parsed = int.tryParse((value?.toString() ?? '').trim()) ?? 0;
      return parsed > 0 ? parsed : 0;
    }

    final name = cleanText(row['full_name']);
    return LawyerDirectoryProfile(
      id: cleanText(row['id']),
      fullName: name.isEmpty ? 'Advokat' : name,
      title: 'Litsenziyali advokat • YAN360',
      region: cleanText(row['region']),
      specialization: cleanText(row['specialization']),
      experienceYears: parseExp(row['experience_years']),
      rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
      feedbackCount: (row['feedback_count'] as num?)?.toInt() ?? 0,
      wonCasesCount: (row['won_cases_count'] as num?)?.toInt() ?? 0,
      consultationPriceUzs:
          (row['consultation_price_uzs'] as num?)?.toInt() ?? 0,
      contractMonthlyNote: '3 oy bepul ilova obunasi • 30%–50% imtiyoz',
      licenseNumber: cleanText(row['license_number']),
      phone: cleanPhone(row['phone']),
      assistantName: '',
      assistantRole: '',
      assistantPhone: '',
      bio: cleanText(row['bio']),
      feedbacks: const <LawyerFeedbackItem>[],
      isVerifiedPartner: row['is_verified'] != false,
      avatarBase64: cleanText(row['avatar_base64']),
      avatarUrl: cleanText(row['avatar_url']),
    );
  }
}

class ArizaOrderItem {
  const ArizaOrderItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientRegion,
    required this.advocateId,
    required this.advocateName,
    required this.categoryType,
    required this.subjectTitle,
    required this.detailedStatement,
    required this.attachmentNames,
    required this.createdAt,
    required this.deadlineAt,
    this.isCompleted = false,
    this.completedArizaText,
    this.completedAt,
    this.completedAttachmentMeta,
    this.arizaSentAt,
    this.clientResponseStatus,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientRegion;
  final String advocateId;
  final String advocateName;
  final String categoryType;
  final String subjectTitle;
  final String detailedStatement;
  final List<String> attachmentNames;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final bool isCompleted;
  final String? completedArizaText;
  final DateTime? completedAt;
  final String? completedAttachmentMeta;

  /// Timestamp when the advocate sent the `#ariza` file in chat.
  final DateTime? arizaSentAt;

  /// `'accepted'`, `'rejected'`, or `null` (if not yet responded by client).
  final String? clientResponseStatus;

  Duration remainingTime(DateTime now) {
    final diff = deadlineAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// True if:
  /// 1. Client clicked `Qabul qilish` (`clientResponseStatus == 'accepted'`), OR
  /// 2. Advocate sent the `#ariza` (`arizaSentAt != null`), client has not
  ///    responded (`clientResponseStatus == null`), and 30 minutes have passed!
  bool isEffectivelyCompleted(DateTime now) {
    if (isCompleted || clientResponseStatus == 'accepted') {
      return true;
    }
    if (arizaSentAt != null &&
        clientResponseStatus == null &&
        now.difference(arizaSentAt!).inMinutes >= 30) {
      return true;
    }
    return false;
  }

  /// True if the 30-minute deadline expired before the advocate delivered
  /// an accepted ariza (or after client rejected it and timer ran out).
  bool isAdvocateLate(DateTime now) {
    if (isEffectivelyCompleted(now)) return false;
    if (arizaSentAt != null && clientResponseStatus == null) {
      return false;
    }
    return now.isAfter(deadlineAt);
  }

  String formatCountdown(DateTime now) {
    if (isEffectivelyCompleted(now)) {
      return 'Tayyor #ariza topshirildi';
    }
    if (arizaSentAt != null && clientResponseStatus == null) {
      final elapsed = now.difference(arizaSentAt!);
      final waitRem = const Duration(minutes: 30) - elapsed;
      if (waitRem.isNegative || waitRem == Duration.zero) {
        return 'Tayyor #ariza topshirildi';
      }
      final wm = waitRem.inMinutes.toString().padLeft(2, '0');
      final ws = (waitRem.inSeconds % 60).toString().padLeft(2, '0');
      return 'Mijoz tekshirmoqda ($wm:$ws)';
    }
    final rem = remainingTime(now);
    if (rem == Duration.zero) {
      return 'Kech qoldingiz!!!';
    }
    final mins = rem.inMinutes.toString().padLeft(2, '0');
    final secs = (rem.inSeconds % 60).toString().padLeft(2, '0');
    if (clientResponseStatus == 'rejected') {
      return '$mins:$secs qoldi • Rad etildi';
    }
    return '$mins:$secs qoldi';
  }

  ArizaOrderItem copyWith({
    bool? isCompleted,
    String? completedArizaText,
    DateTime? completedAt,
    String? completedAttachmentMeta,
    DateTime? arizaSentAt,
    bool clearArizaSentAt = false,
    String? clientResponseStatus,
    bool clearClientResponseStatus = false,
  }) {
    return ArizaOrderItem(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientRegion: clientRegion,
      advocateId: advocateId,
      advocateName: advocateName,
      categoryType: categoryType,
      subjectTitle: subjectTitle,
      detailedStatement: detailedStatement,
      attachmentNames: attachmentNames,
      createdAt: createdAt,
      deadlineAt: deadlineAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedArizaText: completedArizaText ?? this.completedArizaText,
      completedAt: completedAt ?? this.completedAt,
      completedAttachmentMeta:
          completedAttachmentMeta ?? this.completedAttachmentMeta,
      arizaSentAt: clearArizaSentAt ? null : (arizaSentAt ?? this.arizaSentAt),
      clientResponseStatus: clearClientResponseStatus
          ? null
          : (clientResponseStatus ?? this.clientResponseStatus),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'clientRegion': clientRegion,
    'advocateId': advocateId,
    'advocateName': advocateName,
    'categoryType': categoryType,
    'subjectTitle': subjectTitle,
    'detailedStatement': detailedStatement,
    'attachmentNames': attachmentNames,
    'createdAt': createdAt.toIso8601String(),
    'deadlineAt': deadlineAt.toIso8601String(),
    'isCompleted': isCompleted,
    'completedArizaText': completedArizaText,
    'completedAt': completedAt?.toIso8601String(),
    'completedAttachmentMeta': completedAttachmentMeta,
    'arizaSentAt': arizaSentAt?.toIso8601String(),
    'clientResponseStatus': clientResponseStatus,
  };

  factory ArizaOrderItem.fromJson(Map<String, dynamic> map) {
    final rawAttachments = map['attachmentNames'];
    final parsedAttachments = <String>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        parsedAttachments.add(a.toString());
      }
    }
    final created =
        DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final deadline =
        DateTime.tryParse(map['deadlineAt']?.toString() ?? '')?.toLocal() ??
        created.add(const Duration(minutes: 30));
    return ArizaOrderItem(
      id: map['id']?.toString() ?? 'ARZ-1001',
      clientId: map['clientId']?.toString() ?? '',
      clientPhone: map['clientPhone']?.toString() ?? '+998',
      clientName: map['clientName']?.toString() ?? 'Mijoz',
      clientRegion: map['clientRegion']?.toString() ?? 'Toshkent shahri',
      advocateId: map['advocateId']?.toString() ?? '',
      advocateName: map['advocateName']?.toString() ?? 'Advokat',
      categoryType: map['categoryType']?.toString() ?? 'Ariza yozdirish',
      subjectTitle: map['subjectTitle']?.toString() ?? 'Rasmiy ariza',
      detailedStatement: map['detailedStatement']?.toString() ?? '',
      attachmentNames: parsedAttachments,
      createdAt: created,
      deadlineAt: deadline,
      isCompleted: map['isCompleted'] == true,
      completedArizaText: map['completedArizaText']?.toString(),
      completedAt: DateTime.tryParse(
        map['completedAt']?.toString() ?? '',
      )?.toLocal(),
      completedAttachmentMeta: map['completedAttachmentMeta']?.toString(),
      arizaSentAt: DateTime.tryParse(
        map['arizaSentAt']?.toString() ?? '',
      )?.toLocal(),
      clientResponseStatus: map['clientResponseStatus']?.toString(),
    );
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
  static final Set<String> _appliedArizaRatings = <String>{};
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

  /// Live list of real advocates fetched directly from Supabase `public.profiles`
  /// where `role = 'advocate'`. Zero fake accounts!
  static final ValueNotifier<List<LawyerDirectoryProfile>> registeredLawyers =
      ValueNotifier<List<LawyerDirectoryProfile>>(<LawyerDirectoryProfile>[]);

  static List<LawyerDirectoryProfile> get lawyers => registeredLawyers.value;

  static LawyerDirectoryProfile? byIdOrNull(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final lawyer in registeredLawyers.value) {
      if (lawyer.id == id) return lawyer;
    }
    return null;
  }

  static LawyerDirectoryProfile byId(String? id) {
    final found = byIdOrNull(id);
    if (found != null) return found;
    if (registeredLawyers.value.isNotEmpty) {
      return registeredLawyers.value.first;
    }
    return const LawyerDirectoryProfile(
      id: '',
      fullName: 'Advokat tanlanmagan',
      title: 'Advokatxona bo‘limidan tanlang',
      region: 'O‘zbekiston',
      specialization: 'Yuridik xizmatlar',
      experienceYears: 0,
      rating: 5.0,
      feedbackCount: 0,
      wonCasesCount: 0,
      consultationPriceUzs: 0,
      contractMonthlyNote: '',
      licenseNumber: '-',
      phone: '',
      assistantName: '-',
      assistantRole: '',
      assistantPhone: '',
      bio: 'Hozircha shartnomali advokat biriktirilmagan.',
      feedbacks: <LawyerFeedbackItem>[],
    );
  }

  /// Dynamic Pricing Configuration for "Advokatga ariza yozdirish".
  /// Currently free (`isFreeNow = true`, `baseFeeUzs = 0`), but structured
  /// dynamically so future price changes or Click payment integration work
  /// by updating a single value.
  static bool isArizaDraftFreeNow = true;
  static int dynamicArizaBaseFeeUzs = 0;

  static int computeArizaFeeUzs(UserProfileData profile) {
    if (isArizaDraftFreeNow || dynamicArizaBaseFeeUzs <= 0) return 0;
    return profile.applyDiscount(dynamicArizaBaseFeeUzs, category: 'service');
  }

  static String formatArizaFeeLabel(UserProfileData profile) {
    final fee = computeArizaFeeUzs(profile);
    if (fee <= 0) {
      return 'Bepul (Hozircha to‘lov olinmaydi)';
    }
    return '$fee so‘m';
  }

  /// Normalizes participant IDs (whether 'YAN-12345678' or full UUID '12345678-...')
  /// so multi-advocate and multi-client checks are strictly isolated.
  static String normalizeId(String rawId) {
    var clean = rawId.trim().toLowerCase();
    if (clean.startsWith('yan-')) {
      clean = clean.substring(4);
    }
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    // Keep the full identifier: truncating UUIDs made unrelated users collide.
    return clean;
  }

  static bool isSameParticipant(String idA, String idB) {
    final normA = normalizeId(idA);
    final normB = normalizeId(idB);
    if (normA.isEmpty || normB.isEmpty) return false;
    if (normA == normB) return true;
    // Match 8-char YAN-XXXXXXXX short IDs against their full 32-char UUID prefix
    if (normA.length == 8 && normB.length >= 16 && normB.startsWith(normA)) {
      return true;
    }
    if (normB.length == 8 && normA.length >= 16 && normA.startsWith(normB)) {
      return true;
    }
    return false;
  }

  /// Live list of "Advokatga ariza yozdirish" orders & completed `#ariza` deliveries.
  static final ValueNotifier<List<ArizaOrderItem>> arizaOrders =
      ValueNotifier<List<ArizaOrderItem>>(<ArizaOrderItem>[]);

  /// Strictly returns ONLY orders belonging to the specified advocate!
  /// Prevents any advocate from seeing another advocate's client orders.
  static List<ArizaOrderItem> ordersForAdvocate(String advocateId) {
    if (normalizeId(advocateId).isEmpty) return const <ArizaOrderItem>[];
    return arizaOrders.value
        .where((o) => isSameParticipant(o.advocateId, advocateId))
        .toList(growable: false);
  }

  /// Strictly returns ONLY orders belonging to the specified client!
  static List<ArizaOrderItem> ordersForClient(String clientId) {
    if (normalizeId(clientId).isEmpty) return const <ArizaOrderItem>[];
    return arizaOrders.value
        .where((o) => isSameParticipant(o.clientId, clientId))
        .toList(growable: false);
  }

  static void upsertArizaOrder(ArizaOrderItem item) {
    final current = List<ArizaOrderItem>.from(arizaOrders.value);
    final idx = current.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      current[idx] = item;
    } else {
      current.insert(0, item);
    }
    arizaOrders.value = current;
  }

  /// Applies a 1..5 star rating from a client after accepting an #ariza file,
  /// recalculating the advocate's overall rating and updating `registeredLawyers`.
  static double applyAdvocateStarRating({
    required String advocateId,
    required String advocateName,
    required int stars,
    required String clientName,
    String ratingId = '',
    String comment = '',
  }) {
    final dedupeKey = ratingId.trim().isEmpty
        ? ''
        : '${normalizeId(advocateId)}:${ratingId.trim()}';
    if (dedupeKey.isNotEmpty && !_appliedArizaRatings.add(dedupeKey)) {
      final existing = registeredLawyers.value.where(
        (lawyer) => isSameParticipant(lawyer.id, advocateId),
      );
      return existing.isEmpty ? stars.toDouble() : existing.first.rating;
    }
    final clampedStars = stars.clamp(1, 5).toDouble();
    final currentList = List<LawyerDirectoryProfile>.from(
      registeredLawyers.value,
    );
    var updatedRating = clampedStars;
    var found = false;

    for (var i = 0; i < currentList.length; i++) {
      final adv = currentList[i];
      if (isSameParticipant(adv.id, advocateId) ||
          adv.fullName.toLowerCase() == advocateName.toLowerCase()) {
        final oldCount = adv.feedbackCount < 0 ? 0 : adv.feedbackCount;
        final nextCount = oldCount + 1;
        final rawAvg = ((adv.rating * oldCount) + clampedStars) / nextCount;
        updatedRating = double.parse(rawAvg.toStringAsFixed(2));
        final newFeedback = LawyerFeedbackItem(
          clientName: clientName,
          comment: comment.trim().isEmpty
              ? 'Tayyor #ariza hujjati qabul qilindi ($stars/5 yulduz).'
              : comment.trim(),
          rating: clampedStars,
          dateLabel: 'Hozir',
          caseType: 'Ariza yozdirish (#ariza)',
        );
        currentList[i] = adv.copyWith(
          rating: updatedRating,
          feedbackCount: nextCount,
          wonCasesCount: adv.wonCasesCount + 1,
          feedbacks: <LawyerFeedbackItem>[newFeedback, ...adv.feedbacks],
        );
        found = true;
        break;
      }
    }

    if (found) {
      registeredLawyers.value = currentList;
    }
    return updatedRating;
  }

  /// Records when the advocate sends the `#ariza` file (`status = null` in DB,
  /// waiting up to 30 minutes for client response).
  static void markArizaSentByAdvocate({
    required String clientId,
    required String advocateId,
    required DateTime sentAt,
    String? attachmentMeta,
  }) {
    final current = List<ArizaOrderItem>.from(arizaOrders.value);
    for (var i = 0; i < current.length; i++) {
      final item = current[i];
      if (isSameParticipant(item.clientId, clientId) &&
          isSameParticipant(item.advocateId, advocateId) &&
          !item.isCompleted) {
        current[i] = item.copyWith(
          arizaSentAt: sentAt,
          clearClientResponseStatus: true,
          completedAttachmentMeta: attachmentMeta,
        );
        break;
      }
    }
    arizaOrders.value = current;
  }

  static void markArizaRejectedByClient({
    required String clientId,
    required String advocateId,
    required String rejectionReason,
  }) {
    final current = List<ArizaOrderItem>.from(arizaOrders.value);
    for (var i = 0; i < current.length; i++) {
      final item = current[i];
      if (isSameParticipant(item.clientId, clientId) &&
          isSameParticipant(item.advocateId, advocateId)) {
        final now = DateTime.now();
        final newDeadline = item.deadlineAt.isBefore(now)
            ? now.add(const Duration(minutes: 15))
            : item.deadlineAt;
        current[i] = ArizaOrderItem(
          id: item.id,
          clientId: item.clientId,
          clientName: item.clientName,
          clientPhone: item.clientPhone,
          clientRegion: item.clientRegion,
          advocateId: item.advocateId,
          advocateName: item.advocateName,
          categoryType: item.categoryType,
          subjectTitle: item.subjectTitle,
          detailedStatement: item.detailedStatement,
          attachmentNames: item.attachmentNames,
          createdAt: item.createdAt,
          deadlineAt: newDeadline,
          isCompleted: false,
          completedArizaText: 'Rad etildi: $rejectionReason',
          completedAt: null,
          completedAttachmentMeta: null,
          arizaSentAt: null,
          clientResponseStatus: 'rejected',
        );
        break;
      }
    }
    arizaOrders.value = current;
  }

  static void markArizaCompletedByHashtag({
    required String clientId,
    required String advocateId,
    required String advocateName,
    required String arizaContent,
    String? attachmentMeta,
  }) {
    final now = DateTime.now();
    final current = List<ArizaOrderItem>.from(arizaOrders.value);
    var matched = false;
    for (var i = 0; i < current.length; i++) {
      final item = current[i];
      if (isSameParticipant(item.clientId, clientId) &&
          isSameParticipant(item.advocateId, advocateId) &&
          !item.isCompleted) {
        current[i] = item.copyWith(
          isCompleted: true,
          clientResponseStatus: 'accepted',
          completedArizaText: arizaContent,
          completedAt: now,
          completedAttachmentMeta: attachmentMeta,
        );
        matched = true;
        break;
      }
    }
    if (!matched) {
      current.insert(
        0,
        ArizaOrderItem(
          id: 'ARZ-${now.millisecondsSinceEpoch % 100000}',
          clientId: clientId,
          clientName: userProfile.value.displayName,
          clientPhone: userProfile.value.phone,
          clientRegion: userProfile.value.region,
          advocateId: advocateId,
          advocateName: advocateName,
          categoryType: 'Ariza yozdirish',
          subjectTitle: 'Advokat tayyorlagan rasmiy ariza (#ariza)',
          detailedStatement: arizaContent,
          attachmentNames: const <String>[],
          createdAt: now.subtract(const Duration(minutes: 5)),
          deadlineAt: now.add(const Duration(minutes: 25)),
          isCompleted: true,
          clientResponseStatus: 'accepted',
          completedArizaText: arizaContent,
          completedAt: now,
          completedAttachmentMeta: attachmentMeta,
        ),
      );
    }
    arizaOrders.value = current;
  }

  static final ValueNotifier<List<LegalContractItem>> liveContracts =
      ValueNotifier<List<LegalContractItem>>(<LegalContractItem>[]);

  static List<LegalContractItem> get sampleContracts => liveContracts.value;

  static final ValueNotifier<List<AssistantTaskItem>> assistantTasks =
      ValueNotifier<List<AssistantTaskItem>>(<AssistantTaskItem>[]);

  static void toggleTask(String id) {
    assistantTasks.value = assistantTasks.value
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList(growable: false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Selective Liquid Glass Surface & Strict Monochromatic Solid Buttons
// ═══════════════════════════════════════════════════════════════════════════

class LiquidGlassWindow extends StatelessWidget {
  const LiquidGlassWindow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
    this.accentGlowColor,
    this.onTap,
    this.isHighlighted = false,
    this.useBlur = false,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentGlowColor;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool useBlur;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        backgroundColor ??
        (isHighlighted
            ? const Color(0xFFF3F9FF).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.92));

    Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isHighlighted
              ? (accentGlowColor ?? YanColors.primaryBlue).withValues(
                  alpha: 0.45,
                )
              : YanColors.border,
          width: isHighlighted ? 1.3 : 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: YanColors.primaryNavy.withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (useBlur) {
      container = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: container,
        ),
      );
    }

    final wrapped = RepaintBoundary(child: container);

    if (onTap == null) return wrapped;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: wrapped,
    );
  }
}

class LiquidActionButton extends StatefulWidget {
  const LiquidActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accentColor = YanColors.primaryBlue,
    this.isPrimary = true,
    this.isNeutral = false,
    this.isDestructive = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;
  final bool isPrimary;
  final bool isNeutral;
  final bool isDestructive;
  final bool compact;

  @override
  State<LiquidActionButton> createState() => _LiquidActionButtonState();
}

class _LiquidActionButtonState extends State<LiquidActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool useDestructive =
        widget.isDestructive ||
        widget.accentColor == const Color(0xFFF87171) ||
        widget.accentColor == YanColors.destructiveRed;

    final Color bgColor;
    final Color fgColor;
    final Border? border;

    if (useDestructive) {
      bgColor = YanColors.destructiveRed;
      fgColor = YanColors.white;
      border = null;
    } else if (widget.isNeutral) {
      bgColor = YanColors.white;
      fgColor = YanColors.primaryNavy;
      border = Border.all(color: YanColors.border, width: 1.0);
    } else if (widget.isPrimary) {
      bgColor = YanColors.primaryBlue;
      fgColor = YanColors.white;
      border = null;
    } else {
      bgColor = YanColors.lightBlue;
      fgColor = YanColors.primaryNavy;
      border = Border.all(color: YanColors.border, width: 1.0);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 10 : 13.5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.compact ? 13 : 16),
            border: border,
            boxShadow: widget.isPrimary || useDestructive
                ? <BoxShadow>[
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: widget.compact ? 15.5 : 17.5,
                color: fgColor,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: widget.compact ? 12.4 : 13.8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
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
    ActivityCategory.documents => YanColors.primaryBlue,
    ActivityCategory.consultation => YanColors.cyanAccent,
    ActivityCategory.lawyer => YanColors.primaryNavy,
    ActivityCategory.profile => YanColors.successGreen,
  };

  Color get iconBackground => YanColors.lightBlue;

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
      }

      await GeneratedDocumentRepository.instance.reload();
      final docs = GeneratedDocumentRepository.instance.documents.value;
      final existingPaths = loaded
          .map((e) => e.filePath)
          .whereType<String>()
          .toSet();

      var changed = false;
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
    } catch (_) {}
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
    } catch (_) {}
  }
}