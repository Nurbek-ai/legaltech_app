import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 72,
      );
      if (picked != null) {
        final file = File(picked.path);
        String b64 = '';
        try {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            b64 = base64Encode(bytes);
          }
        } catch (_) {}
        final updated = profile.copyWith(
          avatarFile: file,
          avatarBase64: b64.isNotEmpty ? b64 : profile.avatarBase64,
        );
        userProfile.value = updated;
        await syncCurrentUserProfileToSupabase(updated);
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

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _showEditProfileSheet(UserProfileData profile) {
    final isAdvocate =
        profile.roleType == UserRole.advokat ||
        profile.roleType == UserRole.yordamchi;
    final nameCtrl = TextEditingController(text: profile.displayName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final emailCtrl = TextEditingController(text: profile.email);
    String selectedRegion = profile.region.trim();
    final districtCtrl = TextEditingController(text: profile.district);
    final streetCtrl = TextEditingController(text: profile.streetAddress);
    final pinflCtrl = TextEditingController(
      text: profile.passportOrPinfl.trim(),
    );
    final initialSpecs = profile.lawyerSpecialization
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final selectedSpecs = <String>{...initialSpecs};
    final licenseCtrl = TextEditingController(
      text: profile.lawyerLicenseNumber.trim(),
    );
    final expCtrl = TextEditingController(
      text: profile.lawyerExperienceYears > 0
          ? '${profile.lawyerExperienceYears}'
          : '',
    );
    final bioCtrl = TextEditingController(
      text: profile.lawyerBio.trim(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bioWords = _countWords(bioCtrl.text);
            final bioTooLong = bioWords > 100;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.90,
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 22 + bottomInset),
              decoration: BoxDecoration(
                color: YanColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                      Text(
                        isAdvocate
                            ? 'Advokat Profili va Rekvizitlarni Tahrirlash'
                            : 'Shaxsiy Guvohnoma va Rekvizitlarni Tahrirlash',
                        style: const TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileInputField(label: 'F.I.Sh.', controller: nameCtrl),
                      const SizedBox(height: 9),
                      _ProfileInputField(
                        label: 'Telefon raqami',
                        controller: phoneCtrl,
                        placeholder: '+998 90 123 45 67',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Viloyat / Hudud',
                        style: TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: YanRoleDataCatalog.selectableRegions.map((reg) {
                          final active = selectedRegion == reg;
                          return GestureDetector(
                            onTap: () => setModalState(
                              () => selectedRegion = active ? '' : reg,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? YanColors.primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? YanColors.primaryBlue
                                      : YanColors.border,
                                ),
                              ),
                              child: Text(
                                reg,
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : YanColors.primaryNavy,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (isAdvocate) ...<Widget>[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFCFE2FF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Row(
                                children: <Widget>[
                                  Icon(
                                    CupertinoIcons.briefcase_fill,
                                    size: 16,
                                    color: YanColors.primaryBlue,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Advokat profili ma’lumotlari (mijozlarga ko‘rinadi)',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 12.6,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Mutaxassisligi (bir yoki bir nechta tanlang)',
                                style: TextStyle(
                                  color: YanColors.mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: YanRoleDataCatalog
                                    .advocateSpecializations
                                    .map((spec) {
                                  final active = selectedSpecs.contains(spec);
                                  return GestureDetector(
                                    onTap: () => setModalState(() {
                                      if (spec == 'Barcha sohalar') {
                                        if (active) {
                                          selectedSpecs.remove(spec);
                                        } else {
                                          selectedSpecs
                                            ..clear()
                                            ..add('Barcha sohalar');
                                        }
                                      } else {
                                        selectedSpecs.remove('Barcha sohalar');
                                        if (active) {
                                          selectedSpecs.remove(spec);
                                        } else {
                                          selectedSpecs.add(spec);
                                        }
                                      }
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? YanColors.primaryBlue
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: active
                                              ? YanColors.primaryBlue
                                              : YanColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        spec,
                                        style: TextStyle(
                                          color: active
                                              ? Colors.white
                                              : YanColors.primaryNavy,
                                          fontSize: 11.8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 9),
                              _ProfileInputField(
                                label: 'Litsenziya raqami',
                                controller: licenseCtrl,
                                placeholder: 'Masalan: № 001245 yoki STIR',
                              ),
                              const SizedBox(height: 9),
                              _ProfileInputField(
                                label: 'Ish tajribasi (yil)',
                                controller: expCtrl,
                                placeholder: 'Masalan: 5',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      'Advokat haqida (Bio — 100 so‘zgacha)',
                                      style: TextStyle(
                                        color: YanColors.mutedText,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bioTooLong
                                          ? const Color(0xFFFEE2E2)
                                          : const Color(0xFFEAF5FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$bioWords / 100 so‘z',
                                      style: TextStyle(
                                        color: bioTooLong
                                            ? YanColors.destructiveRed
                                            : YanColors.primaryBlue,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              CupertinoTextField(
                                controller: bioCtrl,
                                maxLines: 4,
                                minLines: 3,
                                placeholder:
                                    'Tajribangiz, asosiy yo‘nalishlaringiz va mijozlarga qanday yordam berishingiz haqida qisqacha yozing...',
                                placeholderStyle: const TextStyle(
                                  color: YanColors.subtleText,
                                  fontSize: 13,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                style: const TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: bioTooLong
                                        ? YanColors.destructiveRed
                                        : YanColors.border,
                                  ),
                                ),
                                onChanged: (_) => setModalState(() {}),
                              ),
                              if (bioTooLong)
                                const Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Text(
                                    'Bio matni 100 so‘zdan oshmasligi kerak.',
                                    style: TextStyle(
                                      color: YanColors.destructiveRed,
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 9),
                      _ProfileInputField(
                        label: 'Pasport seriya va raqami / JSHSHIR',
                        controller: pinflCtrl,
                      ),
                      const SizedBox(height: 9),
                      _ProfileInputField(
                        label: 'Email manzili',
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
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
                                if (isAdvocate && _countWords(bioCtrl.text) > 100) {
                                  setModalState(() {});
                                  return;
                                }
                                final parsedExp =
                                    int.tryParse(expCtrl.text.trim()) ?? 0;
                                final updated = profile.copyWith(
                                  displayName: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  region: selectedRegion,
                                  district: districtCtrl.text.trim(),
                                  streetAddress: streetCtrl.text.trim(),
                                  passportOrPinfl: pinflCtrl.text.trim(),
                                  lawyerSpecialization: isAdvocate
                                      ? selectedSpecs.join(', ')
                                      : profile.lawyerSpecialization,
                                  lawyerLicenseNumber: isAdvocate
                                      ? licenseCtrl.text.trim()
                                      : profile.lawyerLicenseNumber,
                                  lawyerExperienceYears: isAdvocate
                                      ? (parsedExp > 0 ? parsedExp : 0)
                                      : profile.lawyerExperienceYears,
                                  lawyerBio: isAdvocate
                                      ? bioCtrl.text.trim()
                                      : profile.lawyerBio,
                                );
                                userProfile.value = updated;
                                syncCurrentUserProfileToSupabase(updated);
                                Navigator.pop(sheetContext);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: YanColors.primaryNavy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      content: const Text(
                                        'Profil ma’lumotlari saqlandi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
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
                          ),
                          const SizedBox(height: 12),

                          // 1. Official YAN360 Passport / Digital ID Card (Screenshot 4)
                          // Automatically upgrades to a more stylish VIP Diplomatic Edition for Mijoz!
                          _YanPassportIdCard(
                            profile: profile,
                            onPhotoTap: () => _openAvatarViewer(profile),
                            onCameraTap: () => _pickAvatarImage(profile),
                            onCopyField: _copyToClipboard,
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

                          if (profile.roleType == UserRole.advokat ||
                              profile.roleType == UserRole.yordamchi) ...<Widget>[
                            const _SectionHeaderRow(
                              title: 'Advokat profili ma’lumotlari',
                              badgeText: 'Mijozlarga ko‘rinadi',
                              icon: CupertinoIcons.briefcase_fill,
                            ),
                            const SizedBox(height: 10),
                            _AdvocatePublicInfoCard(
                              profile: profile,
                              onEditTap: () => _showEditProfileSheet(profile),
                            ),
                            const SizedBox(height: 18),
                          ],

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
                                        onPressed: () async {
                                          try {
                                            await Supabase.instance.client.auth
                                                .signOut();
                                          } catch (_) {}
                                          userProfile.value =
                                              const UserProfileData();
                                          if (!context.mounted) return;
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const IntroScreen(),
                                            ),
                                            (_) => false,
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
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;

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

class _YanPassportIdCard extends StatelessWidget {
  const _YanPassportIdCard({
    required this.profile,
    required this.onPhotoTap,
    required this.onCameraTap,
    required this.onCopyField,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final VoidCallback onPhotoTap;
  final VoidCallback onCameraTap;
  final void Function(String label, String value) onCopyField;
  final VoidCallback onEditTap;

  String _formatMemberSinceDate() {
    DateTime? created;
    try {
      final raw = Supabase.instance.client.auth.currentUser?.createdAt;
      if (raw != null && raw.trim().isNotEmpty) {
        created = DateTime.tryParse(raw)?.toLocal();
      }
    } catch (_) {}
    final dt = created ?? DateTime.now();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isAdvocate =
        profile.roleType == UserRole.advokat ||
        profile.roleType == UserRole.yordamchi;

    final outerBg = isAdvocate
        ? const <Color>[Color(0xFFF7FBFF), Color(0xFFE6F1FF), Color(0xFFDAE9FF)]
        : const <Color>[Color(0xFFFFFFFF), Color(0xFFF5F9FF), Color(0xFFEBF4FF)];
    final frameBorderColor = isAdvocate
        ? const Color(0xFF93C5FD)
        : const Color(0xFFCFE2FF);
    final innerLineColor = isAdvocate
        ? const Color(0xFF60A5FA)
        : const Color(0xFFB5D2FF);
    final crestColor = isAdvocate
        ? const Color(0xFF0B1F3A)
        : const Color(0xFF1677FF);
    final inkPrimary = const Color(0xFF0B1F3A);
    final inkMuted = const Color(0xFF64748B);

    final nameParts = profile.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final firstLine = nameParts.isNotEmpty
        ? nameParts.first.toUpperCase()
        : 'YAN360';
    final secondLine = nameParts.length > 1
        ? nameParts.sublist(1).join(' ').toUpperCase()
        : '';

    final shortId = profile.clientId.trim().isNotEmpty
        ? profile.clientId.trim()
        : 'YAN-2026';
    final subCaptionLabel = isAdvocate ? 'Litsenziya' : 'A’zo bo‘lgan sana';
    final subCaptionValue = isAdvocate
        ? (profile.lawyerLicenseNumber.trim().isNotEmpty
              ? profile.lawyerLicenseNumber.trim()
              : 'Tasdiqlangan')
        : _formatMemberSinceDate();

    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: outerBg,
            ),
            border: Border.all(color: frameBorderColor, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: innerLineColor.withValues(alpha: 0.72),
                  width: 1.0,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    right: -18,
                    bottom: -20,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: isAdvocate ? 0.095 : 0.065,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 158,
                          height: 158,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: crestColor.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: crestColor.withValues(alpha: 0.45),
                                  width: 1.1,
                                ),
                              ),
                              child: Icon(
                                Icons.balance_rounded,
                                size: 18,
                                color: crestColor,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'YAN360ID',
                              style: TextStyle(
                                color: inkPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (isAdvocate) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B1F3A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ADVOKAT',
                                  style: TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontSize: 8.8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            _HolographicSealBadge(
                              size: 38,
                              isAdvocate: isAdvocate,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            GestureDetector(
                              onTap: onPhotoTap,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Container(
                                    width: 94,
                                    height: 114,
                                    decoration: BoxDecoration(
                                      color: isAdvocate
                                          ? const Color(0xFFDBEAFE)
                                          : const Color(0xFFEAF3FF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: frameBorderColor.withValues(
                                          alpha: 0.7,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: profile.avatarFile != null
                                          ? Image.file(
                                              profile.avatarFile!,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.high,
                                            )
                                          : profile.avatarBase64.trim().isNotEmpty
                                          ? Image.memory(
                                              base64Decode(
                                                profile.avatarBase64.trim(),
                                              ),
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (_, __, ___) =>
                                                  Center(
                                                    child: Text(
                                                      profile.initials,
                                                      style: TextStyle(
                                                        color: inkPrimary
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Icon(
                                                  CupertinoIcons.person_fill,
                                                  size: 44,
                                                  color: isAdvocate
                                                      ? const Color(0xFF475569)
                                                      : const Color(0xFF64748B),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  profile.initials,
                                                  style: TextStyle(
                                                    color: inkPrimary
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: GestureDetector(
                                      onTap: onCameraTap,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: frameBorderColor,
                                            width: 1.2,
                                          ),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          CupertinoIcons.camera_fill,
                                          color: inkPrimary,
                                          size: 12.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    firstLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: inkPrimary,
                                      fontSize: 19.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      height: 1.15,
                                    ),
                                  ),
                                  if (secondLine.isNotEmpty)
                                    Text(
                                      secondLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: inkPrimary,
                                        fontSize: 19.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                        height: 1.15,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () =>
                                        onCopyField('YAN360ID', shortId),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            shortId,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isAdvocate
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFF4B5563),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          CupertinoIcons.doc_on_doc,
                                          size: 12,
                                          color: inkMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              subCaptionLabel,
                                              style: TextStyle(
                                                color: inkMuted,
                                                fontSize: 11.2,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              subCaptionValue,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: inkPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _DualFoilMark(isAdvocate: isAdvocate),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YanColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.pencil,
                    color: YanColors.primaryBlue,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Ma’lumotni tahrirlash',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: YanColors.primaryNavy,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HolographicSealBadge extends StatelessWidget {
  const _HolographicSealBadge({required this.size, required this.isAdvocate});

  final double size;
  final bool isAdvocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAdvocate
              ? const <Color>[
                  Color(0xFFDBEAFE),
                  Color(0xFFC7D2FE),
                  Color(0xFFE0F2FE),
                  Color(0xFFBFDBFE),
                ]
              : const <Color>[
                  Color(0xFFE0F2FE),
                  Color(0xFFD8F3DC),
                  Color(0xFFE9D5FF),
                  Color(0xFFDBEAFE),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.verified_user_outlined,
        size: size * 0.48,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
  }
}

class _DualFoilMark extends StatelessWidget {
  const _DualFoilMark({required this.isAdvocate});

  final bool isAdvocate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isAdvocate
                  ? const <Color>[Color(0xFFBFDBFE), Color(0xFFDDD6FE)]
                  : const <Color>[Color(0xFFE9D5FF), Color(0xFFBAE6FD)],
            ),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: const Icon(
            CupertinoIcons.shield_fill,
            size: 11,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isAdvocate
                  ? const <Color>[Color(0xFFC7D2FE), Color(0xFFBAE6FD)]
                  : const <Color>[Color(0xFFD8F3DC), Color(0xFFE9D5FF)],
            ),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: const Icon(
            CupertinoIcons.checkmark_alt,
            size: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
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
    final hasAddress = profile.region.trim().isNotEmpty ||
        profile.district.trim().isNotEmpty ||
        profile.streetAddress.trim().isNotEmpty;
    final addressText = hasAddress ? profile.fullAddress : 'Kiritilmagan';

    final cleanDistrict = profile.district.trim();
    final courtText = cleanDistrict.isNotEmpty
        ? 'Fuqarolik ishlari bo‘yicha $cleanDistrict tumanlararo sudi'
        : 'Kiritilmagan';

    final cleanEmail = profile.email.trim();
    final cleanPhone = profile.phone.trim();
    final contactParts = <String>[
      if (cleanEmail.isNotEmpty) cleanEmail,
      if (cleanPhone.isNotEmpty) cleanPhone,
    ];
    final contactText =
        contactParts.isNotEmpty ? contactParts.join(' • ') : 'Kiritilmagan';

    final cleanPassport = profile.passportOrPinfl.trim();
    final passportText =
        cleanPassport.isNotEmpty ? cleanPassport : 'Kiritilmagan';

    return LiquidGlassWindow(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _CredentialTile(
            icon: CupertinoIcons.location_solid,
            iconBg: const Color(0xFFE8F2FF),
            iconColor: YanColors.primaryBlue,
            label: 'Yashash manzili (Ariza va da’volar uchun)',
            value: addressText,
            onCopy: hasAddress
                ? () => onCopy('Manzil', addressText)
                : onEditTap,
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.building_2_fill,
            iconBg: const Color(0xFFE6FAF3),
            iconColor: YanColors.successGreen,
            label: 'Biriktirilgan sud hududi',
            value: courtText,
            onCopy: cleanDistrict.isNotEmpty
                ? () => onCopy('Sud hududi', courtText)
                : onEditTap,
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.mail_solid,
            iconBg: const Color(0xFFEDF4FF),
            iconColor: YanColors.primaryBlue,
            label: 'Rasmiy elektron pochta va telefon',
            value: contactText,
            onCopy: cleanPhone.isNotEmpty
                ? () => onCopy('Telefon', cleanPhone)
                : onEditTap,
          ),
          const Divider(height: 18, color: YanColors.divider),
          _CredentialTile(
            icon: CupertinoIcons.creditcard_fill,
            iconBg: const Color(0xFFEAF5FF),
            iconColor: YanColors.primaryNavy,
            label: 'Pasport seriyasi / JSHSHIR',
            value: passportText,
            onCopy: cleanPassport.isNotEmpty
                ? () => onCopy('Pasport', cleanPassport)
                : onEditTap,
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

class _AdvocatePublicInfoCard extends StatelessWidget {
  const _AdvocatePublicInfoCard({
    required this.profile,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;

  Widget _row(String label, String value) {
    final isEmpty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(
                color: YanColors.mutedText,
                fontSize: 12.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? 'Kiritilmagan' : value.trim(),
              style: TextStyle(
                color: isEmpty ? YanColors.subtleText : YanColors.primaryNavy,
                fontSize: 12.8,
                fontWeight: isEmpty ? FontWeight.w500 : FontWeight.w700,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioText = profile.lawyerBio.trim();
    return LiquidGlassWindow(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _row('Mutaxassisligi', profile.lawyerSpecialization),
          _row('Litsenziya raqami', profile.lawyerLicenseNumber),
          _row(
            'Ish tajribasi',
            profile.lawyerExperienceYears > 0
                ? '${profile.lawyerExperienceYears} yil'
                : '',
          ),
          _row('Hudud', profile.region),
          const Divider(height: 16, color: YanColors.divider),
          const Text(
            'Advokat haqida (Bio)',
            style: TextStyle(
              color: YanColors.mutedText,
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            bioText.isEmpty
                ? 'Hali kiritilmagan. Mijozlar siz haqingizda bilishi uchun 100 so‘zgacha bio qo‘shing.'
                : bioText,
            style: TextStyle(
              color: bioText.isEmpty
                  ? YanColors.subtleText
                  : YanColors.primaryNavy,
              fontSize: 12.8,
              fontWeight: FontWeight.w500,
              fontStyle: bioText.isEmpty ? FontStyle.italic : FontStyle.normal,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: LiquidActionButton(
              label: 'Advokat ma’lumotlarini tahrirlash',
              icon: CupertinoIcons.pencil,
              isPrimary: false,
              compact: true,
              onPressed: onEditTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.label,
    required this.controller,
    this.placeholder,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;

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
          placeholder: placeholder,
          placeholderStyle: const TextStyle(
            color: YanColors.subtleText,
            fontSize: 13.5,
          ),
          keyboardType: keyboardType,
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