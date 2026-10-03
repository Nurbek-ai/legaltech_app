import 'dart:io';

import 'package:flutter/foundation.dart';

/// Immutable snapshot of the user's profile data.
///
/// All fields are nullable so the UI can render graceful empty states until
/// a real backend populates them.
class UserProfileData {
  const UserProfileData({
    this.displayName = 'Nurbek Otamurodov',
    this.role = 'Raqamli huquqiy profil',
    this.memberSince = '2026',
    this.isVerified = true,
    this.activeApplications = 3,
    this.savedDocuments = 8,
    this.profileCompletion = 0.86,
    this.avatarFile,
  });

  final String displayName;
  final String role;
  final String memberSince;
  final bool isVerified;

  /// Stats shown on both the mini-card (home) and profile page.
  final int activeApplications;
  final int savedDocuments;

  /// 0.0 – 1.0
  final double profileCompletion;

  /// Local file chosen by the user. Null → show initials avatar.
  final File? avatarFile;

  /// Returns a copy with the provided fields replaced.
  UserProfileData copyWith({
    String? displayName,
    String? role,
    String? memberSince,
    bool? isVerified,
    int? activeApplications,
    int? savedDocuments,
    double? profileCompletion,
    File? avatarFile,
    bool clearAvatar = false,
  }) {
    return UserProfileData(
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      isVerified: isVerified ?? this.isVerified,
      activeApplications: activeApplications ?? this.activeApplications,
      savedDocuments: savedDocuments ?? this.savedDocuments,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      avatarFile: clearAvatar ? null : (avatarFile ?? this.avatarFile),
    );
  }

  /// Derived helpers.

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
  }

  String get completionPercent =>
      '${(profileCompletion * 100).round()}%';
}

/// App-wide singleton. Import and use [userProfile] from any widget.
///
/// In production, replace the call to [update] with data from your auth /
/// profile service. The notifier pattern means every listening widget will
/// rebuild automatically.
final ValueNotifier<UserProfileData> userProfile =
    ValueNotifier<UserProfileData>(const UserProfileData());
