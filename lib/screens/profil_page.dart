import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../main.dart';
import '../services/alimony_claim_document_service.dart';
import '../shared/profile_widgets.dart';
import '../shared/user_profile.dart';
import 'services/advokat_yollash_page.dart';
import 'services/lawyer_draft_request_page.dart';

export '../shared/user_profile.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
  }

  Future<void> _pickAvatarImage(UserProfileData profile) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 96,
      );
      if (picked != null) {
        final file = File(picked.path);
        userProfile.value = profile.copyWith(avatarFile: file);
        await ActivityHistoryRepository.instance.record(
          title: 'Guvohnoma fotosurati yangilandi',
          description:
              'YAN360 shaxsiy yuridik guvohnomasi uchun yangi rasm o‘rnatildi',
          category: ActivityCategory.profile,
          statusLabel: 'Saqlandi',
        );
      }
    } catch (_) {
      // Ignore cancel
    }
  }

  void _openAvatarViewer(UserProfileData profile) {
    if (profile.avatarFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FullScreenPhotoPage(file: profile.avatarFile!),
        ),
      );
    } else {
      _pickAvatarImage(profile);
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: YanColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          '$label nusxalandi: $value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQrShareModal(UserProfileData profile) {
    final isMijoz = profile.roleType == UserRole.mijoz;
    final passportNo = profile.passportOrPinfl.trim().isNotEmpty
        ? profile.passportOrPinfl.trim()
        : 'AA 4829104';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: BoxDecoration(
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YanColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMijoz
                      ? 'YAN360 VIP Mijoz Raqamli QR Guvohnomasi'
                      : 'YAN360 Raqamli Yuridik Guvohnoma QR Kodi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Advokat yoki sud devonxonasi ushbu QR kod orqali shaxsingiz va shartnomangizni tasdiqlaydi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: YanColors.mutedText,
                    fontSize: 12.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 176,
                  height: 176,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YanColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: YanColors.border, width: 1.5),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: YanColors.primaryNavy.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.qrcode,
                        size: 138,
                        color: YanColors.primaryNavy,
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: YanColors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: YanColors.border),
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${profile.displayName} • ${profile.clientId} • $passportNo',
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: LiquidActionButton(
                        label: 'ID nusxalash',
                        icon: CupertinoIcons.doc_on_doc,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _copyToClipboard(
                            'Raqamli Guvohnoma ID',
                            '${profile.displayName} | ID: ${profile.clientId} | Pasport: $passportNo',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LiquidActionButton(
                        label: 'Tayyor',
                        icon: CupertinoIcons.checkmark_alt,
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(UserProfileData profile) {
    final nameCtrl = TextEditingController(text: profile.displayName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final emailCtrl = TextEditingController(text: profile.email);
    final regionCtrl = TextEditingController(text: profile.region);
    final districtCtrl = TextEditingController(text: profile.district);
    final streetCtrl = TextEditingController(text: profile.streetAddress);
    final pinflCtrl = TextEditingController(
      text: profile.passportOrPinfl.isEmpty
          ? 'AA 4829104'
          : profile.passportOrPinfl,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 22 + bottomInset),
          decoration: BoxDecoration(
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: YanColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Shaxsiy Guvohnoma va Rekvizitlarni Tahrirlash',
                    style: TextStyle(
                      color: YanColors.primaryNavy,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInputField(label: 'F.I.Sh.', controller: nameCtrl),
                  const SizedBox(height: 9),
                  _ProfileInputField(
                    label: 'Pasport seriya va raqami / JSHSHIR',
                    controller: pinflCtrl,
                  ),
                  const SizedBox(height: 9),
                  _ProfileInputField(
                    label: 'Telefon raqami',
                    controller: phoneCtrl,
                  ),
                  const SizedBox(height: 9),
                  _ProfileInputField(
                    label: 'Email manzili',
                    controller: emailCtrl,
                  ),
                  const SizedBox(height: 9),
                  _ProfileInputField(
                    label: 'Viloyat / Shahar',
                    controller: regionCtrl,
                  ),
                  const SizedBox(height: 9),
                  _ProfileInputField(label: 'Tuman', controller: districtCtrl),
                  const SizedBox(height: 9),
                  _ProfileInputField(
                    label: 'Mahalla va uy manzili',
                    controller: streetCtrl,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: LiquidActionButton(
                          label: 'Bekor qilish',
                          icon: CupertinoIcons.xmark,
                          isPrimary: false,
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LiquidActionButton(
                          label: 'Saqlash',
                          icon: CupertinoIcons.checkmark_alt,
                          onPressed: () {
                            userProfile.value = profile.copyWith(
                              displayName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              region: regionCtrl.text.trim(),
                              district: districtCtrl.text.trim(),
                              streetAddress: streetCtrl.text.trim(),
                              passportOrPinfl: pinflCtrl.text.trim(),
                            );
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        return ValueListenableBuilder<List<GeneratedDocument>>(
          valueListenable: GeneratedDocumentRepository.instance.documents,
          builder: (context, generatedDocs, _) {
            return ValueListenableBuilder<List<ActivityEntry>>(
              valueListenable: ActivityHistoryRepository.instance.entries,
              builder: (context, historyEntries, _) {
                final docxCount = generatedDocs.isNotEmpty
                    ? generatedDocs.length
                    : profile.savedDocuments;

                return CustomScrollView(
                  key: const ValueKey<String>('profile-page'),
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 118),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(<Widget>[
                          // Top Header Row
                          _ProfileTopHeader(
                            profile: profile,
                            onEditTap: () => _showEditProfileSheet(profile),
                            onQrTap: () => _showQrShareModal(profile),
                          ),
                          const SizedBox(height: 12),

                          // 1. Official YAN360 Passport / Digital ID Card (Screenshot 4)
                          // Automatically upgrades to a more stylish VIP Diplomatic Edition for Mijoz!
                          _YanPassportIdCard(
                            profile: profile,
                            onPhotoTap: () => _openAvatarViewer(profile),
                            onCameraTap: () => _pickAvatarImage(profile),
                            onCopyField: _copyToClipboard,
                            onQrShareTap: () => _showQrShareModal(profile),
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 14),

                          // 2. Quick Stats & Readiness Strip
                          _ProfileReadinessAndStatsCard(
                            profile: profile,
                            docxCount: docxCount,
                            requestsCount: 24 + profile.activeApplications,
                            totalHistoryCount: 64 + historyEntries.length,
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 18),

                          // 3. Shaxsiy yuridik rekvizitlar (High-Contrast Dark Navy Typography)
                          const _SectionHeaderRow(
                            title: 'Shaxsiy yuridik rekvizitlar',
                            badgeText: 'Arizalar uchun',
                            icon: CupertinoIcons.doc_person_fill,
                          ),
                          const SizedBox(height: 10),
                          _CredentialsDetailCard(
                            profile: profile,
                            onCopy: _copyToClipboard,
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 18),

                          // 4. Faol Rol va Kabinet Rejimi (4-Role Switcher)
                          const _SectionHeaderRow(
                            title: 'Faol rol va kabinet rejimi',
                            badgeText: '4 xil profil',
                            icon: CupertinoIcons.person_2_square_stack_fill,
                          ),
                          const SizedBox(height: 10),
                          LiquidGlassWindow(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  profile.subscriptionStatusLabel,
                                  style: const TextStyle(
                                    color: YanColors.mutedText,
                                    fontSize: 12.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: UserRole.values.map((role) {
                                    final selected = profile.roleType == role;
                                    return LiquidActionButton(
                                      label: role.label,
                                      icon: role.icon,
                                      isPrimary: selected,
                                      compact: true,
                                      onPressed: () =>
                                          userProfile.switchRole(role),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 5. Mening xizmatlarim va xavfsizlik
                          const _SectionHeaderRow(
                            title: 'Mening xizmatlarim va kabinetim',
                            badgeText: 'Jonli holat',
                            icon: CupertinoIcons.shield_lefthalf_fill,
                          ),
                          const SizedBox(height: 10),
                          LiquidGlassWindow(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: LiquidActionButton(
                                        label: 'Ariza yozdirish',
                                        icon: CupertinoIcons.doc_text_fill,
                                        isPrimary: false,
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const LawyerDraftRequestPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: LiquidActionButton(
                                        label: 'Advokat yollash',
                                        icon: CupertinoIcons.briefcase_fill,
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const AdvokatYollashPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: LiquidActionButton(
                                        label: 'Rasmni yangilash',
                                        icon: CupertinoIcons.camera_fill,
                                        isNeutral: true,
                                        onPressed: () =>
                                            _pickAvatarImage(profile),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: LiquidActionButton(
                                        label: 'Hisobdan chiqish',
                                        icon: CupertinoIcons.square_arrow_right,
                                        isDestructive: true,
                                        onPressed: () {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const IntroScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProfileTopHeader extends StatelessWidget {
  const _ProfileTopHeader({
    required this.profile,
    required this.onEditTap,
    required this.onQrTap,
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 38,
          height: 38,
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'YAN360',
                style: TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'SHAXSIY YURIDIK KABINET VA GUVOHNOMA',
                style: TextStyle(
                  color: YanColors.mutedText,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onQrTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: YanColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: YanColors.border),
            ),
            child: const Icon(
              CupertinoIcons.qrcode,
              color: YanColors.primaryNavy,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEditTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: YanColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: YanColors.border),
            ),
            child: const Icon(
              CupertinoIcons.slider_horizontal_3,
              color: YanColors.primaryBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Official YAN360 Passport / Şəxsiyyət Vəsiqəsi Style ID Card (Screenshot 4)
// With rectangular photo, medium shining firm logo watermark at the background,
// copyable FIN / Document fields, bottom QR share strip, and Mijoz VIP styling!
// ═══════════════════════════════════════════════════════════════════════════

class _YanPassportIdCard extends StatelessWidget {
  const _YanPassportIdCard({
    required this.profile,
    required this.onPhotoTap,
    required this.onCameraTap,
    required this.onCopyField,
    required this.onQrShareTap,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final VoidCallback onPhotoTap;
  final VoidCallback onCameraTap;
  final void Function(String label, String value) onCopyField;
  final VoidCallback onQrShareTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final isMijoz = profile.roleType == UserRole.mijoz;
    final isAdvokat = profile.roleType == UserRole.advokat;
    final passportNumber = profile.passportOrPinfl.trim().isNotEmpty
        ? profile.passportOrPinfl.trim()
        : (isAdvokat ? profile.lawyerLicenseNumber : 'AA 4829104');
    final contractedLawyer = YanRoleDataCatalog.byId(
      profile.contractedLawyerId,
    );

    return Container(
      decoration: BoxDecoration(
        color: YanColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isMijoz
              ? YanColors.primaryBlue.withValues(alpha: 0.45)
              : YanColors.border,
          width: isMijoz ? 1.5 : 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: YanColors.primaryNavy.withValues(
              alpha: isMijoz ? 0.11 : 0.07,
            ),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Upper Passport Body with Guilloche Network + Shining Firm Logo Watermark
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMijoz
                      ? const <Color>[
                          Color(0xFFEAF4FF),
                          Color(0xFFD9ECFF),
                          Color(0xFFE3F6F1),
                        ]
                      : const <Color>[
                          Color(0xFFF3F8FF),
                          Color(0xFFE5F0FF),
                          Color(0xFFDCEBFA),
                        ],
                ),
              ),
              child: Stack(
                children: <Widget>[
                  // Official Passport Guilloche & Constellation Lines
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PassportGuillochePainter(isVip: isMijoz),
                      ),
                    ),
                  ),
                  // Medium-size Shining YAN360 Firm Logo Watermark in the Background
                  Positioned(
                    right: 44,
                    top: 22,
                    bottom: 12,
                    child: IgnorePointer(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: YanColors.cyanAccent.withValues(
                                alpha: isMijoz ? 0.22 : 0.14,
                              ),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: isMijoz ? 0.22 : 0.16,
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Foreground Passport Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Passport Top Header Row
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        isMijoz
                                            ? 'Shaxsiy Yuridik Guvohnoma • VIP'
                                            : 'Shaxsiy Yuridik Guvohnoma',
                                        style: const TextStyle(
                                          color: YanColors.primaryNavy,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 16,
                                        color: YanColors.successGreen,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMijoz
                                        ? 'YAN360 PRIVILEGE PASSPORT • SHARTNOMA № ${profile.contractNumber ?? "SH-2026/084"}'
                                        : 'YAN360 DIGITAL LEGAL ID • O‘ZBEKISTON RESPUBLIKASI',
                                    style: const TextStyle(
                                      color: YanColors.mutedText,
                                      fontSize: 9.6,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMijoz
                                    ? YanColors.successGreen
                                    : YanColors.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                profile.roleType.shortBadge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Main Passport Row: Rectangular Photo on Left + Credentials & Copy Buttons on Right
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Rectangular ID Portrait Photo (Screenshot 4 style)
                            GestureDetector(
                              onTap: onPhotoTap,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Container(
                                    width: 96,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: YanColors.primaryNavy,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isMijoz
                                            ? YanColors.successGreen
                                            : Colors.white,
                                        width: 2.2,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: YanColors.primaryNavy
                                              .withValues(alpha: 0.16),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: profile.avatarFile != null
                                          ? Image.file(
                                              profile.avatarFile!,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.high,
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                const Icon(
                                                  CupertinoIcons.person_fill,
                                                  color: Color(0xFF9ED8FF),
                                                  size: 42,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  profile.initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -5,
                                    bottom: -5,
                                    child: GestureDetector(
                                      onTap: onCameraTap,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: YanColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.8,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.camera_fill,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Right Column: Holder Name, YAN-ID (FIN), Passport Number + Copy Buttons
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'FUQARO / F.I.SH.',
                                    style: TextStyle(
                                      color: YanColors.mutedText,
                                      fontSize: 9.8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    profile.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 16.2,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Row 1: YAN-ID / FIN with Copy Button
                                  _PassportFieldWithCopy(
                                    label: 'SHAXSIY YAN-ID (FIN)',
                                    value: profile.clientId,
                                    onCopy: () => onCopyField(
                                      'YAN-ID',
                                      profile.clientId,
                                    ),
                                  ),
                                  const SizedBox(height: 7),

                                  // Row 2: Guvohnoma / Pasport raqami with Copy Button
                                  _PassportFieldWithCopy(
                                    label: isAdvokat
                                        ? 'ADVOKAT LITSENZIYASI'
                                        : 'GUVOHNOMA / PASPORT RAQAMI',
                                    value: passportNumber,
                                    onCopy: () => onCopyField(
                                      'Pasport / Guvohnoma raqami',
                                      passportNumber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Special Mijoz VIP Diplomatic Privilege Strip inside the Passport Card
                        if (isMijoz) ...<Widget>[
                          const SizedBox(height: 13),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: YanColors.successGreen.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  CupertinoIcons.shield_lefthalf_fill,
                                  color: YanColors.primaryBlue,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Biriktirilgan advokat: ${contractedLawyer.fullName} • Imtiyoz: -30% / -50%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom White Action Bar (Matches "QR paylaş" in Screenshot 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: YanColors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onQrShareTap,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.qrcode,
                          color: YanColors.primaryBlue,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'QR Guvohnomani ulashish',
                          style: TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 13.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: YanColors.divider,
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEditTap,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.pencil_outline,
                          color: YanColors.primaryBlue,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ma’lumotni tahrirlash',
                          style: TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportFieldWithCopy extends StatelessWidget {
  const _PassportFieldWithCopy({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: YanColors.mutedText,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: YanColors.border),
            ),
            child: const Icon(
              CupertinoIcons.doc_on_doc,
              color: YanColors.primaryBlue,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _PassportGuillochePainter extends CustomPainter {
  const _PassportGuillochePainter({required this.isVip});

  final bool isVip;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = YanColors.primaryBlue.withValues(alpha: isVip ? 0.13 : 0.09);

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = YanColors.white.withValues(alpha: 0.65);

    final p1 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width * 0.95, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height);

    final p2 = Path()
      ..moveTo(size.width * 0.42, size.height)
      ..lineTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.68);

    canvas.drawPath(p1, linePaint);
    canvas.drawPath(p2, linePaint);

    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.45),
      4.5,
      nodePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.28),
      3.5,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PassportGuillochePainter oldDelegate) =>
      oldDelegate.isVip != isVip;
}

class _ProfileReadinessAndStatsCard extends StatelessWidget {
  const _ProfileReadinessAndStatsCard({
    required this.profile,
    required this.docxCount,
    required this.requestsCount,
    required this.totalHistoryCount,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final int docxCount;
  final int requestsCount;
  final int totalHistoryCount;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final completion = profile.profileCompletion;
    final pct = (completion * 100).round();
    final barColor = pct < 50
        ? YanColors.destructiveRed
        : pct < 80
        ? const Color(0xFFF59E0B)
        : YanColors.successGreen;

    return LiquidGlassWindow(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Yuridik profil to‘liqligi',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${profile.completionPercent} • ${pct >= 80 ? "Mukammal" : "To‘ldiring"}',
                style: TextStyle(
                  color: barColor == YanColors.successGreen
                      ? const Color(0xFF098562)
                      : barColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion.clamp(0.1, 1.0),
              minHeight: 7,
              backgroundColor: YanColors.lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: _ProfileStatItem(
                  value: '$docxCount',
                  label: 'DOCX Hujjatlar',
                  color: YanColors.successGreen,
                ),
              ),
              Container(width: 1, height: 32, color: YanColors.divider),
              Expanded(
                child: _ProfileStatItem(
                  value: '$requestsCount',
                  label: 'Murojaatlar',
                  color: YanColors.primaryBlue,
                ),
              ),
              Container(width: 1, height: 32, color: YanColors.divider),
              Expanded(
                child: _ProfileStatItem(
                  value: '$totalHistoryCount',
                  label: 'Jami faoliyat',
                  color: YanColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: YanColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.badgeText,
    required this.icon,
  });

  final String title;
  final String badgeText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: YanColors.primaryNavy,
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: YanColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 13, color: YanColors.primaryBlue),
              const SizedBox(width: 5),
              Text(
                badgeText,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CredentialsDetailCard extends StatelessWidget {
  const _CredentialsDetailCard({
    required this.profile,
    required this.onCopy,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final void Function(String label, String value) onCopy;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final passportText = profile.passportOrPinfl.trim().isNotEmpty
        ? profile.passportOrPinfl.trim()
        : 'AA 4829104 (Tasdiqlangan)';

    return LiquidGlassWindow(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _CredentialTile(
            icon: CupertinoIcons.location_solid,
            iconBg: const Color(0xFFE8F2FF),
            iconColor: YanColors.primaryBlue,
            label: 'Yashash manzili (Ariza va da’volar uchun)',
            value: profile.fullAddress,
            onCopy: () => onCopy('Manzil', profile.fullAddress),
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.building_2_fill,
            iconBg: const Color(0xFFE6FAF3),
            iconColor: YanColors.successGreen,
            label: 'Biriktirilgan sud hududi',
            value:
                'Fuqarolik ishlari bo‘yicha ${profile.district} tumanlararo sudi',
            onCopy: () => onCopy('Sud hududi', profile.district),
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.mail_solid,
            iconBg: const Color(0xFFEDF4FF),
            iconColor: YanColors.primaryBlue,
            label: 'Rasmiy elektron pochta va telefon',
            value: '${profile.email} • ${profile.phone}',
            onCopy: () => onCopy('Telefon', profile.phone),
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.creditcard_fill,
            iconBg: const Color(0xFFEAF5FF),
            iconColor: YanColors.primaryNavy,
            label: 'Pasport seriyasi / JSHSHIR',
            value: passportText,
            onCopy: () => onCopy('Pasport', passportText),
          ),
          const SizedBox(height: 14),
           SizedBox(
            width: double.infinity,
            child: LiquidActionButton(
              label: 'Rekvizitlarni yangilash',
              icon: CupertinoIcons.slider_horizontal_3,
              isPrimary: false,
              onPressed: onEditTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  const _CredentialTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: YanColors.mutedText,
                  fontSize: 11.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 13.6,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: YanColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.doc_on_doc,
              size: 15,
              color: YanColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: YanColors.mutedText,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          style: const TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: YanColors.lightBlue.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: YanColors.border),
          ),
        ),
      ],
    );
  }
}