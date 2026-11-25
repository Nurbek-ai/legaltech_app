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
import '../services/contract_link_service.dart';
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
    String selectedBirthDate = profile.birthDate.trim();
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
                                      'Advokat haqida (100 so‘zgacha)',
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
                                    'Advokat haqidagi matn 100 so‘zdan oshmasligi kerak.',
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
                      const Text(
                        'Tug‘ilgan sana',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          DateTime initial = DateTime(1995, 1, 1);
                          final parts = selectedBirthDate.split('.');
                          if (parts.length == 3) {
                            final d = int.tryParse(parts[0]);
                            final m = int.tryParse(parts[1]);
                            final y = int.tryParse(parts[2]);
                            if (d != null && m != null && y != null && y >= 1930) {
                              initial = DateTime(y, m, d);
                            }
                          }
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: initial,
                            firstDate: DateTime(1930),
                            lastDate: DateTime.now(),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF1677D2),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF102B50),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            final dd = picked.day.toString().padLeft(2, '0');
                            final mm = picked.month.toString().padLeft(2, '0');
                            setModalState(
                              () => selectedBirthDate = '$dd.$mm.${picked.year}',
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: YanColors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.cake_outlined,
                                size: 18,
                                color: Color(0xFF1677D2),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedBirthDate.isEmpty
                                      ? 'Sanani tanlang (KK.OO.YYYY)'
                                      : selectedBirthDate,
                                  style: TextStyle(
                                    fontSize: 13.8,
                                    fontWeight: selectedBirthDate.isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: selectedBirthDate.isEmpty
                                        ? YanColors.mutedText
                                        : YanColors.primaryNavy,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: YanColors.mutedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      _ProfileInputField(
                        label: 'Pasport seriya va raqami / JSHSHIR',
                        controller: pinflCtrl,
                      ),
                      const SizedBox(height: 9),
                      _ProfileInputField(
                        label: 'Elektron pochta manzili',
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
                                  birthDate: selectedBirthDate,
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
                final isAdvocate =
                    profile.roleType == UserRole.advokat ||
                    profile.roleType == UserRole.yordamchi;
                final docxCount = generatedDocs.isNotEmpty
                    ? generatedDocs.length
                    : profile.savedDocuments;
                final authId =
                    Supabase.instance.client.auth.currentUser?.id ?? '';
                final activeClientsCount = ContractLinkRepository
                    .instance
                    .links
                    .value
                    .where(
                      (l) =>
                          l.isActive &&
                          ((authId.isNotEmpty &&
                                  YanRoleDataCatalog.isSameParticipant(
                                    l.advocateId,
                                    authId,
                                  )) ||
                              (profile.clientId.isNotEmpty &&
                                  YanRoleDataCatalog.isSameParticipant(
                                    l.advocateId,
                                    profile.clientId,
                                  ))),
                    )
                    .length;
                final advocateCasesCount = YanRoleDataCatalog
                    .arizaOrders
                    .value
                    .where(
                      (o) =>
                          (authId.isNotEmpty &&
                              YanRoleDataCatalog.isSameParticipant(
                                o.advocateId,
                                authId,
                              )) ||
                          (profile.clientId.isNotEmpty &&
                              YanRoleDataCatalog.isSameParticipant(
                                o.advocateId,
                                profile.clientId,
                              )),
                    )
                    .length;

                return CustomScrollView(
                  key: const ValueKey<String>('profile-page'),
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 118),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(<Widget>[
                          // Shared YAN360 Header
                          _ProfileTopHeader(
                            profile: profile,
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 14),

                          // 1. Role-Specific YAN360ID Card (Deep Royal Blue for Advocate / Light Ice Blue for User) + Edit Button
                          _YanPassportIdCard(
                            profile: profile,
                            onPhotoTap: () => _openAvatarViewer(profile),
                            onCameraTap: () => _pickAvatarImage(profile),
                            onCopyField: _copyToClipboard,
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 14),

                          // 2. Role-Aware Completeness & Dynamic Activity Stats
                          _ProfileReadinessAndStatsCard(
                            profile: profile,
                            isAdvocate: isAdvocate,
                            stat1Count: docxCount,
                            stat2Count: isAdvocate
                                ? activeClientsCount
                                : profile.activeApplications,
                            stat3Count: isAdvocate
                                ? (advocateCasesCount > 0
                                      ? advocateCasesCount
                                      : historyEntries.length)
                                : historyEntries.length,
                            onEditTap: () => _showEditProfileSheet(profile),
                          ),
                          const SizedBox(height: 18),

                          if (isAdvocate) ...<Widget>[
                            // 3A. Advocate Professional Information List
                            const _SectionHeaderRow(
                              title: 'Advokat profili ma’lumotlari',
                              badgeText: 'Kabinet',
                              icon: CupertinoIcons.briefcase_fill,
                            ),
                            const SizedBox(height: 10),
                            _AdvocateProfessionalMenuCard(
                              profile: profile,
                              activeClientsCount: activeClientsCount,
                              casesCount: advocateCasesCount > 0
                                  ? advocateCasesCount
                                  : historyEntries.length,
                              onEditTap: () => _showEditProfileSheet(profile),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // 3B. Personal Legal Information (Masked Passport / JSHSHIR)
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
                                if (!isAdvocate) ...<Widget>[
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
                                ],
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
                                          await setCurrentUserPresenceOffline();
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

    final cardGradient = isAdvocate
        ? const <Color>[
            Color(0xFF0E2C5F),
            Color(0xFF144B96),
            Color(0xFF1A6DC4),
          ]
        : const <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF3F8FF),
            Color(0xFFE5F1FF),
          ];
    final borderColor = isAdvocate
        ? const Color(0xFF3B82D6).withValues(alpha: 0.45)
        : const Color(0xFFCFE2FF);
    final titleColor = isAdvocate ? Colors.white : const Color(0xFF102B50);
    final mutedColor = isAdvocate
        ? Colors.white.withValues(alpha: 0.80)
        : const Color(0xFF64748B);
    final idColor = isAdvocate
        ? Colors.white.withValues(alpha: 0.90)
        : const Color(0xFF3B5578);

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
    final memberDate = _formatMemberSinceDate();
    final licenseText = profile.lawyerLicenseNumber.trim().isNotEmpty
        ? profile.lawyerLicenseNumber.trim()
        : 'Tasdiqlangan';

    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardGradient,
            ),
            border: Border.all(color: borderColor, width: 1.15),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isAdvocate
                    ? const Color(0xFF0E2C5F).withValues(alpha: 0.22)
                    : const Color(0xFF102B50).withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              children: <Widget>[
                // Subtle institutional YAN360 emblem watermark
                Positioned(
                  right: -20,
                  bottom: -22,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: isAdvocate ? 0.13 : 0.07,
                      child: Image.asset(
                        'assets/logo.png',
                        width: 156,
                        height: 156,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Top Row: Emblem + YAN360ID + ADVOKAT pill + Verification Badge
                      Row(
                        children: <Widget>[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAdvocate
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : const Color(0xFF1677D2).withValues(
                                      alpha: 0.10,
                                    ),
                              border: Border.all(
                                color: isAdvocate
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : const Color(0xFF1677D2).withValues(
                                        alpha: 0.30,
                                      ),
                              ),
                            ),
                            child: Icon(
                              Icons.balance_rounded,
                              size: 16,
                              color: isAdvocate
                                  ? Colors.white
                                  : const Color(0xFF1677D2),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'YAN360ID',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (isAdvocate) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ADVOKAT',
                                style: TextStyle(
                                  color: Color(0xFF102B50),
                                  fontSize: 9.2,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _ProfileVerificationBadge(
                            isVerified: profile.isVerified,
                            onDarkSurface: isAdvocate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Identity Row: Portrait + Name + Copyable ID + Dates/License
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                            onTap: onPhotoTap,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                Container(
                                  width: 84,
                                  height: 98,
                                  decoration: BoxDecoration(
                                    color: isAdvocate
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : const Color(0xFFEAF3FC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isAdvocate
                                          ? Colors.white.withValues(alpha: 0.45)
                                          : const Color(0xFFCFE2FF),
                                      width: 1.3,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14.5),
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
                                                      color: titleColor,
                                                      fontSize: 18,
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
                                                size: 38,
                                                color: isAdvocate
                                                    ? Colors.white.withValues(
                                                        alpha: 0.85,
                                                      )
                                                    : const Color(0xFF1677D2)
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                profile.initials,
                                                style: TextStyle(
                                                  color: titleColor.withValues(
                                                    alpha: 0.85,
                                                  ),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.0,
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
                                          color: const Color(0xFFDCE6F2),
                                          width: 1.2,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.camera_fill,
                                        color: Color(0xFF102B50),
                                        size: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  firstLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    height: 1.15,
                                  ),
                                ),
                                if (secondLine.isNotEmpty)
                                  Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          secondLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 18.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                      if (isAdvocate &&
                                          profile.isVerified) ...<Widget>[
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 17,
                                          color: Color(0xFF60A5FA),
                                        ),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: 7),
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
                                            color: idColor,
                                            fontSize: 11.8,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        CupertinoIcons.doc_on_doc,
                                        size: 12,
                                        color: mutedColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isAdvocate) ...<Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 13,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Litsenziya: $licenseText',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: titleColor.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontSize: 11.8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'A’zo bo‘lgan sana: $memberDate',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: mutedColor,
                                            fontSize: 11.2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...<Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'A’zo bo‘lgan sana:',
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    memberDate,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
        const SizedBox(height: 12),

        // Shared Full-Width Edit Profile Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onEditTap,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF1677D2),
              size: 17,
            ),
            label: const Text(
              'Ma’lumotni tahrirlash',
              style: TextStyle(
                color: Color(0xFF102B50),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD6E5F7), width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileVerificationBadge extends StatelessWidget {
  const _ProfileVerificationBadge({
    required this.isVerified,
    required this.onDarkSurface,
  });

  final bool isVerified;
  final bool onDarkSurface;

  @override
  Widget build(BuildContext context) {
    final bg = onDarkSurface
        ? Colors.white
        : (isVerified ? const Color(0xFFE8F8F0) : const Color(0xFFF1F5F9));
    final fg = isVerified ? const Color(0xFF0F766E) : const Color(0xFF64748B);
    final iconColor = isVerified
        ? const Color(0xFF10B981)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Text(
            isVerified ? 'Tasdiqlangan' : 'Tekshiruvda',
            style: TextStyle(
              color: onDarkSurface ? const Color(0xFF102B50) : fg,
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReadinessAndStatsCard extends StatelessWidget {
  const _ProfileReadinessAndStatsCard({
    required this.profile,
    required this.isAdvocate,
    required this.stat1Count,
    required this.stat2Count,
    required this.stat3Count,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final bool isAdvocate;
  final int stat1Count;
  final int stat2Count;
  final int stat3Count;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final completion = profile.profileCompletion;
    final pct = (completion * 100).round();
    final barColor = pct < 50
        ? YanColors.destructiveRed
        : pct < 80
        ? const Color(0xFF1677D2)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECF6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isAdvocate ? 'Profil to‘liqligi' : 'Yuridik profil to‘liqligi',
                  style: const TextStyle(
                    color: Color(0xFF102B50),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${profile.completionPercent} · ${pct >= 80 ? "Mukammal" : "To‘ldiring"}',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion.clamp(0.06, 1.0),
              minHeight: 7,
              backgroundColor: const Color(0xFFEAF3FC),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: <Widget>[
              Expanded(
                child: _ProfileStatItem(
                  icon: Icons.description_outlined,
                  value: '$stat1Count',
                  label: isAdvocate ? 'Hujjatlar' : 'DOCX hujjatlar',
                  color: const Color(0xFF1677D2),
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE9F0F8)),
              Expanded(
                child: _ProfileStatItem(
                  icon: isAdvocate
                      ? Icons.groups_outlined
                      : Icons.send_outlined,
                  value: '$stat2Count',
                  label: isAdvocate ? 'Mijozlar' : 'Murojaatlar',
                  color: const Color(0xFF1677D2),
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE9F0F8)),
              Expanded(
                child: _ProfileStatItem(
                  icon: isAdvocate
                      ? Icons.balance_rounded
                      : Icons.layers_outlined,
                  value: '$stat3Count',
                  label: isAdvocate ? 'Ishlar' : 'Jami faoliyat',
                  color: const Color(0xFF102B50),
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
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF102B50),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AdvocateProfessionalMenuCard extends StatelessWidget {
  const _AdvocateProfessionalMenuCard({
    required this.profile,
    required this.activeClientsCount,
    required this.casesCount,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final int activeClientsCount;
  final int casesCount;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final licenseSub = profile.lawyerLicenseNumber.trim().isNotEmpty
        ? 'Litsenziya: ${profile.lawyerLicenseNumber.trim()}${profile.lawyerExperienceYears > 0 ? " • ${profile.lawyerExperienceYears} yil tajriba" : ""}'
        : 'Advokatlik litsenziyasi, sertifikatlar';
    final specSub = profile.lawyerSpecialization.trim().isNotEmpty
        ? profile.lawyerSpecialization.trim()
        : 'Fuqarolik, oila, mehnat huquqi va boshqalar';
    final clientsSub = activeClientsCount > 0
        ? 'Faol mijozlar ($activeClientsCount ta), shartnomalar, xizmatlar'
        : 'Faol mijozlar, shartnomalar, xizmatlar';
    final historySub = casesCount > 0
        ? 'Ishlar, murojaatlar va natijalar ($casesCount ta)'
        : 'Ishlar, murojaatlar va natijalar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECF6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _ProfileInformationTile(
            icon: Icons.verified_user_outlined,
            title: 'Litsenziya va malaka',
            subtitle: licenseSub,
            onTap: onEditTap,
          ),
          const Divider(height: 1, indent: 68, color: Color(0xFFEFF4FA)),
          _ProfileInformationTile(
            icon: Icons.balance_rounded,
            title: 'Mutaxassisliklar',
            subtitle: specSub,
            onTap: onEditTap,
          ),
          const Divider(height: 1, indent: 68, color: Color(0xFFEFF4FA)),
          _ProfileInformationTile(
            icon: Icons.groups_outlined,
            title: 'Mijozlar va shartnomalar',
            subtitle: clientsSub,
            onTap: onEditTap,
          ),
          const Divider(height: 1, indent: 68, color: Color(0xFFEFF4FA)),
          _ProfileInformationTile(
            icon: Icons.history_rounded,
            title: 'Faoliyat tarixi',
            subtitle: historySub,
            onTap: onEditTap,
          ),
          if (profile.lawyerBio.trim().isNotEmpty) ...<Widget>[
            const Divider(height: 1, color: Color(0xFFEFF4FA)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Advokat haqida',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.lawyerBio.trim(),
                    style: const TextStyle(
                      color: Color(0xFF102B50),
                      fontSize: 12.8,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInformationTile extends StatelessWidget {
  const _ProfileInformationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF1677D2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF102B50),
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
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

class _CredentialsDetailCard extends StatefulWidget {
  const _CredentialsDetailCard({
    required this.profile,
    required this.onCopy,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final void Function(String label, String value) onCopy;
  final VoidCallback onEditTap;

  @override
  State<_CredentialsDetailCard> createState() => _CredentialsDetailCardState();
}

class _CredentialsDetailCardState extends State<_CredentialsDetailCard> {
  bool _showPassport = false;

  String _maskSensitive(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length <= 4) return '••••';
    return '${trimmed.substring(0, 2)}${'•' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
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
      if (cleanEmail.isNotEmpty && !cleanEmail.startsWith('yan360.')) cleanEmail,
      if (cleanPhone.isNotEmpty) cleanPhone,
    ];
    final contactText =
        contactParts.isNotEmpty ? contactParts.join(' • ') : 'Kiritilmagan';

    final cleanPassport = profile.passportOrPinfl.trim();
    final passportDisplay = cleanPassport.isEmpty
        ? 'Kiritilmagan'
        : (_showPassport ? cleanPassport : _maskSensitive(cleanPassport));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECF6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _CredentialTile(
            icon: CupertinoIcons.location_solid,
            iconBg: const Color(0xFFEAF3FC),
            iconColor: const Color(0xFF1677D2),
            label: 'Yashash manzili',
            value: addressText,
            onCopy: hasAddress
                ? () => widget.onCopy('Manzil', addressText)
                : widget.onEditTap,
          ),
          const Divider(height: 18, color: Color(0xFFEFF4FA)),
          _CredentialTile(
            icon: CupertinoIcons.building_2_fill,
            iconBg: const Color(0xFFEAF3FC),
            iconColor: const Color(0xFF1677D2),
            label: 'Biriktirilgan sud hududi',
            value: courtText,
            onCopy: cleanDistrict.isNotEmpty
                ? () => widget.onCopy('Sud hududi', courtText)
                : widget.onEditTap,
          ),
          const Divider(height: 18, color: Color(0xFFEFF4FA)),
          _CredentialTile(
            icon: CupertinoIcons.mail_solid,
            iconBg: const Color(0xFFEAF3FC),
            iconColor: const Color(0xFF1677D2),
            label: 'Aloqa ma’lumotlari',
            value: contactText,
            onCopy: cleanPhone.isNotEmpty
                ? () => widget.onCopy('Telefon', cleanPhone)
                : widget.onEditTap,
          ),
          const Divider(height: 18, color: Color(0xFFEFF4FA)),
          _CredentialTile(
            icon: Icons.cake_rounded,
            iconBg: const Color(0xFFEAF3FC),
            iconColor: const Color(0xFF1677D2),
            label: 'Tug‘ilgan sana',
            value: widget.profile.birthDate.trim().isEmpty
                ? 'Kiritilmagan — qo‘shish uchun bosing'
                : widget.profile.birthDate.trim(),
            onCopy: widget.profile.birthDate.trim().isNotEmpty
                ? () => widget.onCopy(
                      'Tug‘ilgan sana',
                      widget.profile.birthDate.trim(),
                    )
                : widget.onEditTap,
          ),
          const Divider(height: 18, color: Color(0xFFEFF4FA)),
          Row(
            children: <Widget>[
              Expanded(
                child: _CredentialTile(
                  icon: CupertinoIcons.creditcard_fill,
                  iconBg: const Color(0xFFEAF3FC),
                  iconColor: const Color(0xFF102B50),
                  label: 'Pasport seriyasi / JSHSHIR',
                  value: passportDisplay,
                  onCopy: cleanPassport.isNotEmpty
                      ? () => widget.onCopy('Pasport', cleanPassport)
                      : widget.onEditTap,
                ),
              ),
              if (cleanPassport.isNotEmpty) ...<Widget>[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _showPassport = !_showPassport),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _showPassport
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: LiquidActionButton(
              label: 'Rekvizitlarni yangilash',
              icon: CupertinoIcons.slider_horizontal_3,
              isPrimary: false,
              onPressed: widget.onEditTap,
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