import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../main.dart';
import '../services/alimony_claim_document_service.dart';
import '../services/alimony_location_catalog.dart';
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
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
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
                final activeRequests = historyEntries
                    .where(
                      (e) =>
                          e.category == ActivityCategory.consultation ||
                          e.category == ActivityCategory.lawyer,
                    )
                    .toList(growable: false);

                return CustomScrollView(
                  key: const ValueKey<String>('profile-page'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ProfileTopBar(
                          profile: profile,
                          onNotificationTap: () =>
                              _toggleNotifications(profile),
                          onSecurityTap: () => _showSecuritySheet(profile),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _DigitalLegalIdCard(
                          profile: profile,
                          documentsCount: generatedDocs.length,
                          activeRequestsCount: activeRequests.length,
                          totalActivitiesCount: historyEntries.length,
                          onEditTap: () => _showEditProfileSheet(profile),
                          onAvatarTap: () => _openAvatarViewer(profile),
                          onAvatarUploadTap: () => _pickAvatarImage(profile),
                          onDocumentsTap: () =>
                              _showGeneratedDocumentsSheet(generatedDocs),
                          onRequestsTap: () =>
                              _showActiveRequestsSheet(activeRequests),
                          onCompletionTap: () => _showEditProfileSheet(profile),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Shaxsiy yuridik rekvizitlar',
                          trailing: 'Arizalar uchun',
                          trailingIcon: CupertinoIcons.doc_person_fill,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 11, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _LegalRequisitesCard(
                          profile: profile,
                          onEditTap: () => _showEditProfileSheet(profile),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 11),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Mening xizmatlarim va kabinetim',
                          trailing: 'Jonli holat',
                          trailingIcon: CupertinoIcons.bolt_horizontal_circle_fill,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _WorkspaceActionTile(
                            icon: CupertinoIcons.doc_checkmark_fill,
                            title: 'Yaratilgan da’vo arizalari (DOCX)',
                            subtitle: generatedDocs.isEmpty
                                ? 'Hozircha yaratilgan DOCX ariza yo‘q'
                                : 'Oxirgi: ${generatedDocs.first.title}',
                            badge: '${generatedDocs.length} ta fayl',
                            color: const Color(0xFF67E2B8),
                            onTap: () =>
                                _showGeneratedDocumentsSheet(generatedDocs),
                          ),
                          const SizedBox(height: 10),
                          _WorkspaceActionTile(
                            icon: CupertinoIcons.briefcase_fill,
                            title: 'Advokat va konsultatsiya murojaatlari',
                            subtitle: activeRequests.isEmpty
                                ? 'Yangi konsultatsiya yoki advokat yollash'
                                : 'Faol so‘rovlar: ${activeRequests.length} ta yozuv',
                            badge: '${activeRequests.length} ta',
                            color: const Color(0xFF83AAFF),
                            onTap: () =>
                                _showActiveRequestsSheet(activeRequests),
                          ),
                          const SizedBox(height: 10),
                          _WorkspaceActionTile(
                            icon: CupertinoIcons.chat_bubble_2_fill,
                            title: 'Fikr-mulohaza va xizmatni baholash',
                            subtitle:
                                'Taklif qoldirish yoki YAN360 xizmatlarini baholash',
                            badge: 'Aloqa',
                            color: const Color(0xFFFFC979),
                            onTap: _showFeedbackAndRatingSheet,
                          ),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 11),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Xavfsizlik va tizim',
                          trailing: profile.hasPinCode
                              ? 'PIN + Biometrika'
                              : 'Himoyalangan',
                          trailingIcon: CupertinoIcons.lock_shield_fill,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 125),
                      sliver: SliverToBoxAdapter(
                        child: _SecurityAndAccountCard(
                          profile: profile,
                          onSecurityTap: () => _showSecuritySheet(profile),
                          onPinTap: () => _showPinSetupSheet(profile),
                          onLogoutTap: _confirmLogout,
                        ),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Avatar management
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _pickAvatarImage(UserProfileData profile) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _ProfileBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const Text(
                'Profil rasmini boshqarish',
                style: TextStyle(
                  color: Color(0xFFF5F8FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Galereyadan rasm tanlang yoki kameradan foydalaning.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _SourceButton(
                icon: CupertinoIcons.photo_on_rectangle,
                label: 'Galereyadan tanlash',
                subtitle: 'Qurilma xotirasidagi suratlar',
                color: const Color(0xFF83AAFF),
                onTap: () => Navigator.pop(sheetCtx, 'gallery'),
              ),
              const SizedBox(height: 10),
              _SourceButton(
                icon: CupertinoIcons.camera_fill,
                label: 'Kamerada suratga olish',
                subtitle: 'Yangi rasmga tushish',
                color: const Color(0xFF67E2B8),
                onTap: () => Navigator.pop(sheetCtx, 'camera'),
              ),
              if (profile.avatarFile != null) ...[
                const SizedBox(height: 10),
                _SourceButton(
                  icon: CupertinoIcons.trash_fill,
                  label: 'Joriy rasmni o‘chirish',
                  subtitle: 'Harfli avatar ko‘rinishiga qaytish',
                  color: const Color(0xFFFF8F9C),
                  onTap: () => Navigator.pop(sheetCtx, 'remove'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    if (choice == 'remove') {
      userProfile.value = profile.copyWith(clearAvatar: true);
      await ActivityHistoryRepository.instance.record(
        title: 'Profil rasmi o‘chirildi',
        description: 'Standart harfli avatar tiklandi',
        category: ActivityCategory.profile,
        statusLabel: 'Yangilandi',
      );
      _showMessage('Profil rasmi o‘chirildi');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final file = File(picked.path);
      userProfile.value = profile.copyWith(avatarFile: file);
      await ActivityHistoryRepository.instance.record(
        title: 'Profil rasmi yangilandi',
        description: 'Shaxsiy kabinet uchun yangi rasm o‘rnatildi',
        category: ActivityCategory.profile,
        statusLabel: 'Bajarildi',
      );
      _showMessage('Profil rasmi muvaffaqiyatli yangilandi ✓');
    } catch (_) {
      _showMessage('Rasm tanlashda xatolik yuz berdi.');
    }
  }

  void _openAvatarViewer(UserProfileData profile) {
    if (profile.avatarFile == null) {
      _pickAvatarImage(profile);
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) =>
            FullScreenPhotoPage(file: profile.avatarFile!),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Full Legal Profile Editor Sheet
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _showEditProfileSheet(UserProfileData profile) async {
    final nameCtrl = TextEditingController(text: profile.displayName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final emailCtrl = TextEditingController(text: profile.email);
    final streetCtrl = TextEditingController(text: profile.streetAddress);
    final passportCtrl = TextEditingController(text: profile.passportOrPinfl);

    String? selectedRegion =
        AlimonyLocationCatalog.regions.contains(profile.region)
        ? profile.region
        : AlimonyLocationCatalog.regions.first;
    String? selectedDistrict = AlimonyLocationCatalog.districtsFor(
      selectedRegion,
    ).contains(profile.district)
        ? profile.district
        : AlimonyLocationCatalog.districtsFor(selectedRegion).firstOrNull;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
            final districts = AlimonyLocationCatalog.districtsFor(
              selectedRegion,
            );

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _ProfileBottomSheet(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.84,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetHandle(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const _SheetBrandMark(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Yuridik rekvizitlarni tahrirlash',
                                    style: TextStyle(
                                      color: Color(0xFFF5F8FF),
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Bu ma’lumotlar da’vo arizalarini tez to‘ldirishda xizmat qiladi.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.54,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ProfileInputField(
                          controller: nameCtrl,
                          label: 'To‘liq F.I.Sh.',
                          hint: 'Familiya, ism, otasining ismi',
                          icon: CupertinoIcons.person_fill,
                          capitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        _ProfileInputField(
                          controller: phoneCtrl,
                          label: 'Telefon raqami',
                          hint: '+998 90 123 45 67',
                          icon: CupertinoIcons.phone_fill,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _ProfileInputField(
                          controller: emailCtrl,
                          label: 'Email manzili',
                          hint: 'name@example.com',
                          icon: CupertinoIcons.mail_solid,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ProfileDropdown(
                                label: 'Viloyat / shahar',
                                value: selectedRegion,
                                options: AlimonyLocationCatalog.regions,
                                onChanged: (val) {
                                  setSheetState(() {
                                    selectedRegion = val;
                                    final nextDistricts =
                                        AlimonyLocationCatalog.districtsFor(
                                          val,
                                        );
                                    selectedDistrict = nextDistricts.isNotEmpty
                                        ? nextDistricts.first
                                        : null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileDropdown(
                                label: 'Tuman / shahar',
                                value: districts.contains(selectedDistrict)
                                    ? selectedDistrict
                                    : null,
                                options: districts,
                                onChanged: (val) {
                                  setSheetState(() => selectedDistrict = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ProfileInputField(
                          controller: streetCtrl,
                          label: 'MFY, ko‘cha va uy raqami',
                          hint: 'Masalan: Mustaqillik MFY, 12-uy',
                          icon: CupertinoIcons.location_solid,
                          capitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        _ProfileInputField(
                          controller: passportCtrl,
                          label: 'Pasport seriyasi / ID yoki JSHSHIR',
                          hint: 'Masalan: AD 1234567',
                          icon: CupertinoIcons.creditcard_fill,
                          capitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final newName = nameCtrl.text.trim();
                              if (newName.isEmpty) {
                                _showMessage('To‘liq ismingizni kiriting.');
                                return;
                              }
                              final updated = profile.copyWith(
                                displayName: newName,
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                region: selectedRegion ?? profile.region,
                                district: selectedDistrict ?? profile.district,
                                streetAddress: streetCtrl.text.trim(),
                                passportOrPinfl: passportCtrl.text.trim(),
                              );
                              userProfile.value = updated;
                              Navigator.of(sheetContext).pop();
                              await ActivityHistoryRepository.instance.record(
                                title: 'Shaxsiy yuridik rekvizitlar yangilandi',
                                description:
                                    '${updated.displayName} • ${updated.fullAddress}',
                                category: ActivityCategory.profile,
                                statusLabel:
                                    'To‘liqlik: ${updated.completionPercent}',
                                metadata: <String, String>{
                                  'F.I.Sh.': updated.displayName,
                                  'Telefon': updated.phone,
                                  'Email': updated.email,
                                  'Manzil': updated.fullAddress,
                                  if (updated.passportOrPinfl.isNotEmpty)
                                    'Pasport / ID': updated.passportOrPinfl,
                                },
                              );
                              _showMessage(
                                'Rekvizitlar saqlandi (${updated.completionPercent}) ✓',
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4A79E0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.checkmark_alt),
                            label: const Text(
                              'Ma’lumotlarni saqlash',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    streetCtrl.dispose();
    passportCtrl.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Live Generated Documents Sheet
  // ──────────────────────────────────────────────────────────────────────────

  void _showGeneratedDocumentsSheet(List<GeneratedDocument> docs) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _ProfileBottomSheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF67E2B8).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_checkmark_fill,
                        color: Color(0xFF67E2B8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yaratilgan DOCX hujjatlar',
                            style: TextStyle(
                              color: Color(0xFFF5F8FF),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Jami: ${docs.length} ta tayyor da’vo arizasi',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Hozircha yaratilgan DOCX hujjatlar mavjud emas. Bosh sahifadagi xizmatlardan birini tanlab, 1 daqiqada rasmiy ariza tayyorlashingiz mumkin.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final dateStr =
                            '${doc.createdAt.day.toString().padLeft(2, '0')}.'
                            '${doc.createdAt.month.toString().padLeft(2, '0')}.'
                            '${doc.createdAt.year}';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.085),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.doc_text_fill,
                                color: Color(0xFF67E2B8),
                                size: 20,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFF2F6FC),
                                        fontSize: 13.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'DOCX • $dateStr',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetCtx);
                                  OpenFilex.open(doc.path);
                                },
                                icon: const Icon(
                                  CupertinoIcons.arrow_up_right_square,
                                  size: 15,
                                  color: Color(0xFF9DBBFF),
                                ),
                                label: const Text(
                                  'Ochish',
                                  style: TextStyle(
                                    color: Color(0xFF9DBBFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Active Consultation & Lawyer Requests Sheet
  // ──────────────────────────────────────────────────────────────────────────

  void _showActiveRequestsSheet(List<ActivityEntry> requests) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _ProfileBottomSheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF83AAFF).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        CupertinoIcons.briefcase_fill,
                        color: Color(0xFF83AAFF),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advokat va konsultatsiyalar',
                            style: TextStyle(
                              color: Color(0xFFF5F8FF),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Faol murojaatlar: ${requests.length} ta',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (requests.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final item = requests[index];
                        return Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.085),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.statusLabel,
                                      style: TextStyle(
                                        color: item.accentColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.dateFormatted} • ${item.timeFormatted}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFFF3F6FC),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AdvokatYollashPage(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3E70E2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.videocam_fill, size: 16),
                        label: const Text(
                          'Konsultatsiya / Advokat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LawyerDraftRequestPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9DBBFF),
                          side: BorderSide(
                            color: const Color(
                              0xFF9DBBFF,
                            ).withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.doc_person, size: 16),
                        label: const Text(
                          'Ariza buyurtma',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Project 2 Feedback & Service Rating Sheet
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _showFeedbackAndRatingSheet() async {
    final feedbackCtrl = TextEditingController();
    var selectedRating = 'A’lo 🤩';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
            const ratings = <String>['Qoniqarsiz 😡', 'Yaxshi 😐', 'A’lo 🤩'];

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _ProfileBottomSheet(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 18),
                    const Text(
                      'Fikr-mulohaza va baholash',
                      style: TextStyle(
                        color: Color(0xFFF5F8FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'YAN360 platformasi ishlashi bo‘yicha bahoyingiz va taklifingizni yuboring.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: ratings.map((label) {
                        final active = selectedRating == label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => selectedRating = label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(
                                          0xFF4A79E0,
                                        ).withValues(alpha: 0.28)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: active
                                        ? const Color(0xFF8AB0FF)
                                        : Colors.white.withValues(alpha: 0.09),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _ProfileInputField(
                      controller: feedbackCtrl,
                      label: 'Murojaat yoki taklif matni',
                      hint:
                          'Taklifingiz yoki kuzatilgan muammoni batafsil yozing...',
                      icon: CupertinoIcons.chat_bubble_text_fill,
                      maxLines: 3,
                      capitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final msg = feedbackCtrl.text.trim();
                          Navigator.pop(sheetCtx);
                          await ActivityHistoryRepository.instance.record(
                            title: 'Xizmat baholandi: $selectedRating',
                            description: msg.isEmpty
                                ? 'YAN360 platformasiga baho yuborildi'
                                : msg,
                            category: ActivityCategory.profile,
                            statusLabel: 'Qabul qilindi',
                            metadata: <String, String>{
                              'Baho': selectedRating,
                              'Foydalanuvchi': userProfile.value.displayName,
                              'Telefon': userProfile.value.phone,
                              if (msg.isNotEmpty) 'Xabar': msg,
                            },
                          );
                          _showMessage(
                            'Fikr-mulohazangiz ma’muriyatga yetkazildi. Rahmat! ✓',
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A79E0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.paperplane_fill, size: 16),
                        label: const Text(
                          'Yuborish',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    feedbackCtrl.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Security, PIN & Notifications
  // ──────────────────────────────────────────────────────────────────────────

  void _toggleNotifications(UserProfileData profile) {
    final next = !profile.notificationsEnabled;
    userProfile.value = profile.copyWith(notificationsEnabled: next);
    _showMessage(
      next
          ? 'Bildirishnomalar yoqildi'
          : 'Bildirishnomalar vaqtincha o‘chirildi',
    );
  }

  Future<void> _showSecuritySheet(UserProfileData profile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ValueListenableBuilder<UserProfileData>(
          valueListenable: userProfile,
          builder: (context, currentProfile, _) {
            return _ProfileBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const Text(
                    'Xavfsizlik markazi',
                    style: TextStyle(
                      color: Color(0xFFF5F8FF),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shaxsiy ma’lumotlaringiz va DOCX hujjatlaringiz himoyasini boshqaring.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SecuritySetting(
                    icon: CupertinoIcons.lock_shield_fill,
                    title: 'Biometrik himoya (Face ID / Touch ID)',
                    subtitle: 'Ilovaga kirishda biometrik tasdiqlash',
                    value: currentProfile.biometricEnabled,
                    onChanged: (value) {
                      userProfile.value = currentProfile.copyWith(
                        biometricEnabled: value,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SecuritySetting(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Push-bildirishnomalar',
                    subtitle: 'Sud va ariza holati bo‘yicha xabarnomalar',
                    value: currentProfile.notificationsEnabled,
                    onChanged: (value) {
                      userProfile.value = currentProfile.copyWith(
                        notificationsEnabled: value,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SourceButton(
                    icon: CupertinoIcons.number_square_fill,
                    label: currentProfile.hasPinCode
                        ? 'Maxfiy PIN-kodni o‘zgartirish'
                        : '4 xonali PIN-kod o‘rnatish',
                    subtitle: currentProfile.hasPinCode
                        ? 'Faol PIN-kod o‘rnatilgan'
                        : 'Qo‘shimcha himoya kodi',
                    color: const Color(0xFF83AAFF),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showPinSetupSheet(currentProfile);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPinSetupSheet(UserProfileData profile) async {
    final pinCtrl = TextEditingController(text: profile.pinCode ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _ProfileBottomSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                const Text(
                  'Maxfiy PIN-kod',
                  style: TextStyle(
                    color: Color(0xFFF5F8FF),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Yuridik hujjatlar bo‘limini himoyalash uchun 4 xonali raqam kiriting.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileInputField(
                  controller: pinCtrl,
                  label: '4 xonali PIN-kod',
                  hint: '••••',
                  icon: CupertinoIcons.lock_fill,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (profile.hasPinCode) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            userProfile.value = profile.copyWith(
                              clearPinCode: true,
                            );
                            Navigator.pop(sheetCtx);
                            _showMessage('PIN-kod o‘chirildi');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF9AA8),
                            side: BorderSide(
                              color: const Color(
                                0xFFFF9AA8,
                              ).withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('PIN-kodni o‘chirish'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          final digits = pinCtrl.text.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digits.length != 4) {
                            _showMessage('4 ta raqamdan iborat kod kiriting.');
                            return;
                          }
                          userProfile.value = profile.copyWith(pinCode: digits);
                          Navigator.pop(sheetCtx);
                          await ActivityHistoryRepository.instance.record(
                            title: 'Xavfsizlik PIN-kodi o‘rnatildi',
                            description:
                                'Shaxsiy kabinet 4 xonali PIN-kod bilan himoyalandi',
                            category: ActivityCategory.profile,
                            statusLabel: 'Faol',
                          );
                          _showMessage('PIN-kod muvaffaqiyatli saqlandi ✓');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A79E0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'PIN-kodni saqlash',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
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
    pinCtrl.dispose();
  }

  void _confirmLogout() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return CupertinoAlertDialog(
          title: const Text('Hisobdan chiqish'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Haqiqatan ham YAN360 shaxsiy kabinetidan chiqmoqchimisiz? Saqlangan DOCX hujjatlaringiz qurilmada qoladi.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Bekor qilish'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const IntroScreen(),
                  ),
                  (_) => false,
                );
              },
              child: const Text('Chiqish'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            98 + MediaQuery.paddingOf(context).bottom,
          ),
          backgroundColor: const Color(0xFF23364C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Digital Legal ID Card (Replaces the bulky empty box + 3 generic stat squares)
// ═══════════════════════════════════════════════════════════════════════════

class _DigitalLegalIdCard extends StatelessWidget {
  const _DigitalLegalIdCard({
    required this.profile,
    required this.documentsCount,
    required this.activeRequestsCount,
    required this.totalActivitiesCount,
    required this.onEditTap,
    required this.onAvatarTap,
    required this.onAvatarUploadTap,
    required this.onDocumentsTap,
    required this.onRequestsTap,
    required this.onCompletionTap,
  });

  final UserProfileData profile;
  final int documentsCount;
  final int activeRequestsCount;
  final int totalActivitiesCount;
  final VoidCallback onEditTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onAvatarUploadTap;
  final VoidCallback onDocumentsTap;
  final VoidCallback onRequestsTap;
  final VoidCallback onCompletionTap;

  @override
  Widget build(BuildContext context) {
    final missing = profile.missingProfileItems;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1A3A63),
            Color(0xFF102542),
            Color(0xFF0C1C33),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8DB1F0).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1D3B).withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/logo.png',
                width: 185,
                height: 185,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top badge bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF67E2B8).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF67E2B8).withValues(alpha: 0.26),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: Color(0xFF7AE8C0),
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'VERIFIED LEGAL ID',
                            style: TextStyle(
                              color: Color(0xFFC9FAEA),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.clientId,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.46),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.pencil,
                              color: Color(0xFFDCE8FF),
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Tahrirlash',
                              style: TextStyle(
                                color: Color(0xFFDCE8FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Horizontal Identity Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: onAvatarTap,
                          child: Hero(
                            tag: 'profile-avatar',
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    Color(0xFF3E70E2),
                                    Color(0xFF1B3F8B),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFF82AEFF,
                                  ).withValues(alpha: 0.60),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3060D0,
                                    ).withValues(alpha: 0.40),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: buildAvatarContent(
                                  profile,
                                  initialsSize: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onAvatarUploadTap,
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A79E0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF102542),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF7F9FF),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.phone_fill,
                                size: 12,
                                color: Color(0xFF8FB4FF),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  profile.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.location_solid,
                                size: 12,
                                color: Color(0xFF67E2B8),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${profile.region}, ${profile.district}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.56),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Dynamic completion bar
                GestureDetector(
                  onTap: onCompletionTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Yuridik profil to‘liqligi',
                              style: TextStyle(
                                color: Color(0xFFD9E7FC),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              profile.completionPercent,
                              style: const TextStyle(
                                color: Color(0xFF7CE0B4),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: profile.profileCompletion,
                            minHeight: 6,
                            color: const Color(0xFF67E2B8),
                            backgroundColor: const Color(0xFF284363),
                          ),
                        ),
                        if (missing.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'To‘ldirish tavsiya etiladi: ${missing.join(' • ')}',
                            style: TextStyle(
                              color: const Color(
                                0xFFFFD18B,
                              ).withValues(alpha: 0.90),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Integrated 3-column live workspace metrics bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      _InlineMetricButton(
                        value: documentsCount.toString(),
                        label: 'DOCX Hujjatlar',
                        color: const Color(0xFF67E2B8),
                        onTap: onDocumentsTap,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                      _InlineMetricButton(
                        value: activeRequestsCount.toString(),
                        label: 'Murojaatlar',
                        color: const Color(0xFF83AAFF),
                        onTap: onRequestsTap,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                      _InlineMetricButton(
                        value: totalActivitiesCount.toString(),
                        label: 'Jami faoliyat',
                        color: const Color(0xFFFFC979),
                        onTap: onRequestsTap,
                      ),
                    ],
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

class _InlineMetricButton extends StatelessWidget {
  const _InlineMetricButton({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Personal Legal Requisites Card
// ═══════════════════════════════════════════════════════════════════════════

class _LegalRequisitesCard extends StatelessWidget {
  const _LegalRequisitesCard({
    required this.profile,
    required this.onEditTap,
  });

  final UserProfileData profile;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    String localCourt = 'Tanlanmagan';
    try {
      if (profile.district.trim().isNotEmpty) {
        localCourt =
            '${AlimonyLocationCatalog.courtForDistrict(profile.district)} sudi';
      }
    } catch (_) {
      localCourt = profile.district;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.052),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.085),
        ),
      ),
      child: Column(
        children: [
          _RequisiteRow(
            icon: CupertinoIcons.placemark_fill,
            label: 'Yashash manzili',
            value: profile.fullAddress,
            color: const Color(0xFF83AAFF),
          ),
          const SizedBox(height: 10),
          _RequisiteRow(
            icon: CupertinoIcons.building_2_fill,
            label: 'Hududiy fuqarolik sudi',
            value: localCourt,
            color: const Color(0xFF67E2B8),
          ),
          const SizedBox(height: 10),
          _RequisiteRow(
            icon: CupertinoIcons.mail_solid,
            label: 'Elektron pochta',
            value: profile.email.isEmpty ? 'Kiritilmagan' : profile.email,
            color: const Color(0xFFC8B2FF),
          ),
          const SizedBox(height: 10),
          _RequisiteRow(
            icon: CupertinoIcons.creditcard_fill,
            label: 'Pasport / JSHSHIR',
            value: profile.passportOrPinfl.isEmpty
                ? 'Kiritilmagan (tahrirlash orqali qo‘shing)'
                : profile.passportOrPinfl,
            color: const Color(0xFFFFC979),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFADC4FF),
                side: BorderSide(
                  color: const Color(0xFFADC4FF).withValues(alpha: 0.26),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 15),
              label: const Text(
                'Rekvizitlarni yangilash',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequisiteRow extends StatelessWidget {
  const _RequisiteRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF1F5FC),
                  fontSize: 12.5,
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

// ═══════════════════════════════════════════════════════════════════════════
// Security & Account Management Card
// ═══════════════════════════════════════════════════════════════════════════

class _SecurityAndAccountCard extends StatelessWidget {
  const _SecurityAndAccountCard({
    required this.profile,
    required this.onSecurityTap,
    required this.onPinTap,
    required this.onLogoutTap,
  });

  final UserProfileData profile;
  final VoidCallback onSecurityTap;
  final VoidCallback onPinTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSecurityTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF153329).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF75D9AF).withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF75D9AF).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: Color(0xFF83DEB7),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.biometricEnabled
                              ? 'Biometrik himoya va shifrlash faol'
                              : 'Biometrik himoyani yoqish',
                          style: const TextStyle(
                            color: Color(0xFFE9F8F0),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile.hasPinCode
                              ? '4 xonali PIN-kod va biometrik qulf o‘rnatilgan'
                              : 'Qo‘shimcha 4 xonali PIN-kod o‘rnatish uchun bosing',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.56),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFF9BDCBF),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPinTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD8E5FF),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(CupertinoIcons.lock_fill, size: 15),
                label: Text(
                  profile.hasPinCode ? 'PIN-kodni yangilash' : 'PIN-kod qo‘yish',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onLogoutTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9FB2),
                  side: BorderSide(
                    color: const Color(0xFFFF8B9E).withValues(alpha: 0.25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(CupertinoIcons.square_arrow_right, size: 16),
                label: const Text(
                  'Hisobdan chiqish',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Supporting Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.profile,
    required this.onNotificationTap,
    required this.onSecurityTap,
  });

  final UserProfileData profile;
  final VoidCallback onNotificationTap;
  final VoidCallback onSecurityTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YAN360',
                style: TextStyle(
                  color: Color(0xFFF3F6FC),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'SHAXSIY YURIDIK KABINET',
                style: TextStyle(
                  color: Color(0xFF8190A5),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: profile.notificationsEnabled
              ? CupertinoIcons.bell_fill
              : CupertinoIcons.bell_slash,
          tooltip: 'Bildirishnomalar',
          showBadge: profile.notificationsEnabled,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: CupertinoIcons.shield_fill,
          tooltip: 'Xavfsizlik sozlamalari',
          onTap: onSecurityTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: const Color(0xFFB8C7DC), size: 19),
                if (showBadge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF73D9AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.trailingIcon,
  });

  final String title;
  final String trailing;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF0F4FA),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          Icon(trailingIcon, color: const Color(0xFF79D8AE), size: 13),
          const SizedBox(width: 5),
        ],
        Text(
          trailing,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.46),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceActionTile extends StatelessWidget {
  const _WorkspaceActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF0F4FA),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.35),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: capitalization,
      cursorColor: const Color(0xFF9DBBFF),
      style: const TextStyle(
        color: Color(0xFFF4F7FC),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.52),
          fontSize: 12.5,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
          fontSize: 12.5,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9DBBFF), size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.11),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF84A9FF)),
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      isExpanded: true,
      dropdownColor: const Color(0xFF152940),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.52),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.11),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF84A9FF)),
        ),
      ),
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.085),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFF3F6FC),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: color.withValues(alpha: 0.60),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF132437),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SheetBrandMark extends StatelessWidget {
  const _SheetBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF4A79E0).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9DBBFF).withValues(alpha: 0.22),
        ),
      ),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }
}

class _SecuritySetting extends StatelessWidget {
  const _SecuritySetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7BE0B4).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF86E5BA), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFF57B88D),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
