import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../shared/dashboard_background.dart';
import '../../shared/user_profile.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ADVOKATGA ARIZA YOZDIRISH — 3-Step Direct Executive Flow (#FEFEFA Design)
// 1. Vaziyat bayoni ("Nima sodir bo‘lganini ayting.") + Advocate Selection
// 2. Dalillar va hujjatlar ("Hujjatlaringizni tartib bilan qo‘shing." + Skip)
// 3. Murojaatni tekshirish (Review + Edit buttons + Dynamic Free/Paid Config)
// -> Forwards structured E2EE application + docs to Advocate's Chat, starts
//    30-minute real-time timer in Advocate's Mijozlar, and sends Auto-Welcome!
// ═══════════════════════════════════════════════════════════════════════════

class LawyerDraftRequestPage extends StatefulWidget {
  const LawyerDraftRequestPage({super.key, this.onSubmit});

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<LawyerDraftRequestPage> createState() =>
      _LawyerDraftRequestPageState();
}

class _LawyerDraftRequestPageState extends State<LawyerDraftRequestPage> {
  final TextEditingController _subjectController = TextEditingController(
    text: 'Rasmiy huquqiy ariza',
  );
  final TextEditingController _problemController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _files = <XFile>[];

  int _step = 0; // 0: Vaziyat bayoni, 1: Hujjatlar (with Skip), 2: Review
  bool _busy = false;
  bool _loadingAdvocates = true;
  LawyerDirectoryProfile? _selectedAdvocate;

  static const List<String> _quickSubjectSuggestions = <String>[
    'Sudga da’vo arizasi',
    'Oilaviy va aliment masalasi',
    'Qarz va shartnoma nizosi',
    'Mehnat huquqi bo‘yicha ariza',
    'Rasmiy shikoyat arizasi',
  ];

  @override
  void initState() {
    super.initState();
    _problemController.addListener(_onTextChanged);
    _subjectController.addListener(_onTextChanged);
    _loadRegisteredAdvocates();
  }

  @override
  void dispose() {
    _problemController
      ..removeListener(_onTextChanged)
      ..dispose();
    _subjectController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRegisteredAdvocates() async {
    if (mounted) setState(() => _loadingAdvocates = true);
    try {
      final byId = <String, Map<String, dynamic>>{};

      try {
        final rows = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('role', 'advocate');
        for (final item in rows) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            byId[id] = map;
          }
        }
      } catch (_) {}

      try {
        final licRows = await Supabase.instance.client
            .from('advocate_licenses')
            .select();
        for (final item in licRows) {
          final map = Map<String, dynamic>.from(item as Map);
          final id =
              map['advocate_id']?.toString() ?? map['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final existing = byId[id] ?? <String, dynamic>{'id': id};
            if ((existing['full_name']?.toString() ?? '').trim().isEmpty &&
                (map['full_name']?.toString() ?? '').trim().isNotEmpty) {
              existing['full_name'] = map['full_name'];
            }
            if ((map['phone']?.toString() ?? '').trim().isNotEmpty) {
              existing['phone'] = map['phone'];
            }
            if ((map['stir_number']?.toString() ?? '').trim().isNotEmpty) {
              existing['license_number'] = 'STIR: ${map['stir_number']}';
            }
            byId[id] = existing;
          }
        }
      } catch (_) {}

      final parsed = byId.values
          .map(LawyerDirectoryProfile.fromSupabaseMap)
          .toList();
      if (parsed.isNotEmpty) {
        YanRoleDataCatalog.registeredLawyers.value = parsed;
      }
    } catch (_) {
    } finally {
      final list = YanRoleDataCatalog.registeredLawyers.value;
      final contractedId = userProfile.value.contractedLawyerId;
      LawyerDirectoryProfile? initial;
      if (contractedId != null) {
        for (final adv in list) {
          if (adv.id == contractedId) {
            initial = adv;
            break;
          }
        }
      }
      initial ??= list.isNotEmpty ? list.first : null;
      if (mounted) {
        setState(() {
          _selectedAdvocate = initial;
          _loadingAdvocates = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: YanColors.primaryNavy,
        ),
      );
  }

  void _nextStep() {
    if (_step == 0) {
      if (_problemController.text.trim().length < 15) {
        _showError(
          'Iltimos, nima sodir bo‘lganini kamida 15 ta belgi bilan batafsilroq yozing.',
        );
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      setState(() => _step = 2);
      return;
    }

    _submitAndForwardToAdvocateChat();
  }

  void _skipDocumentsStep() {
    FocusScope.of(context).unfocus();
    setState(() => _step = 2);
  }

  void _previousStep() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _pickDocuments(ImageSource source) async {
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(imageQuality: 85);
      } else {
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        picked = file == null ? <XFile>[] : <XFile>[file];
      }

      if (!mounted) return;
      setState(() {
        for (final file in picked) {
          if (_files.length < 10 &&
              !_files.any((item) => item.path == file.path)) {
            _files.add(file);
          }
        }
      });
    } catch (_) {
      _showError('Hujjatni yuklashda xatolik yuz berdi.');
    }
  }

  void _moveFileUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _files.removeAt(index);
      _files.insert(index - 1, item);
    });
  }

  void _moveFileDown(int index) {
    if (index >= _files.length - 1) return;
    setState(() {
      final item = _files.removeAt(index);
      _files.insert(index + 1, item);
    });
  }

  void _openAttachmentPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
                'E2EE Hujjat va Dalil Qo‘shish',
                style: TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pasport, shartnoma, sud qarori yoki yozishmalar skanerini tanlang',
                style: TextStyle(
                  color: YanColors.mutedText,
                  fontSize: 12.2,
                ),
              ),
              const SizedBox(height: 14),
              _PickerOptionTile(
                icon: Icons.photo_library_rounded,
                title: 'Galereyadan tanlash (10 tagacha)',
                subtitle: 'Qurilmadagi rasm va skanerlarni tartib bilan qo‘shish',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocuments(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              _PickerOptionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Kamera orqali rasmga olish',
                subtitle: 'Hujjatning asl nusxasini suratga tushirish',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocuments(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdvocatePickerSheet() {
    final advocates = YanRoleDataCatalog.registeredLawyers.value;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
                'Arizani qabul qiluvchi rasmiy advokatni tanlang',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              if (advocates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Hozircha ro‘yxatdan o‘tgan advokatlar topilmadi. Ariza navbatdagi rasmiy advokatga yo‘naltiriladi.',
                    style: TextStyle(
                      fontSize: 13,
                      color: YanColors.mutedText,
                    ),
                  ),
                )
              else
                ...advocates.map((adv) {
                  final selected = _selectedAdvocate?.id == adv.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAdvocate = adv);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: selected
                            ? YanColors.lightBlue
                            : YanColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? YanColors.primaryBlue
                              : YanColors.border,
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: YanColors.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              adv.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        adv.fullName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: YanColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 15,
                                      color: YanColors.primaryBlue,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${adv.specialization} • Litsenziya: ${adv.licenseNumber}',
                                  style: const TextStyle(
                                    fontSize: 11.8,
                                    color: YanColors.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: selected
                                ? YanColors.primaryBlue
                                : YanColors.subtleText,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  LawyerDirectoryProfile get _resolvedAdvocate {
    if (_selectedAdvocate != null) return _selectedAdvocate!;
    final list = YanRoleDataCatalog.registeredLawyers.value;
    if (list.isNotEmpty) return list.first;
    return const LawyerDirectoryProfile(
      id: 'official_advocate',
      fullName: 'Rasmiy Advokat (YAN360)',
      title: 'Litsenziyali advokat • YAN360',
      region: 'Toshkent shahri',
      specialization: 'Fuqarolik, oila va shartnoma huquqi',
      experienceYears: 7,
      rating: 5.0,
      feedbackCount: 12,
      wonCasesCount: 48,
      consultationPriceUzs: 0,
      contractMonthlyNote: '30 daqiqada rasmiy ariza tayyorlash',
      licenseNumber: 'Tasdiqlangan',
      phone: '+998',
      assistantName: '-',
      assistantRole: '',
      assistantPhone: '',
      bio: 'YAN360 rasmiy litsenziyali advokati.',
      feedbacks: <LawyerFeedbackItem>[],
      isVerifiedPartner: true,
    );
  }

  Map<String, dynamic> _buildPayload(String referenceCode, int dynamicFeeUzs) {
    final subject = _subjectController.text.trim().isEmpty
        ? 'Rasmiy huquqiy ariza'
        : _subjectController.text.trim();
    return <String, dynamic>{
      'type': 'lawyer_draft_request',
      'reference_code': referenceCode,
      'category_title': subject,
      'problem': _problemController.text.trim(),
      'problem_content': _problemController.text.trim(),
      'base_price': dynamicFeeUzs,
      'starting_price_uzs': dynamicFeeUzs,
      'advocate_id': _resolvedAdvocate.id,
      'advocate_name': _resolvedAdvocate.fullName,
      'files': _files.map((f) => f.path).toList(),
      'attachments': _files
          .map(
            (file) => <String, String>{
              'name': file.name,
              'local_path': file.path,
            },
          )
          .toList(),
    };
  }

  Future<void> _submitAndForwardToAdvocateChat() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final profile = userProfile.value;
      final dynamicFeeUzs = YanRoleDataCatalog.computeArizaFeeUzs(profile);
      final costLabel = YanRoleDataCatalog.formatArizaFeeLabel(profile);
      final refCode =
          '#ARZ-${(DateTime.now().millisecondsSinceEpoch % 90000) + 10000}';
      final subject = _subjectController.text.trim().isEmpty
          ? 'Rasmiy huquqiy ariza'
          : _subjectController.text.trim();
      final detailedText = _problemController.text.trim();
      final attachmentNames = _files.map((e) => e.name).toList();

      final payload = _buildPayload(refCode, dynamicFeeUzs);
      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      }

      if (!mounted) return;
      await AdvocateClientChatPage.sendArizaPackageAndOpenChat(
        context: context,
        advocate: _resolvedAdvocate,
        clientProfile: profile,
        referenceCode: refCode,
        subjectTitle: subject,
        detailedStatement: detailedText,
        attachmentNames: attachmentNames,
        formattedCostLabel: costLabel,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _showError('Murojaatni yuborishda xatolik yuz berdi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = ((_step + 1) / 3 * 100).round();
    final stepBadgeText = 'QADAM ${_step + 1} / 3';

    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                // Top Executive Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: _previousStep,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: YanColors.primaryNavy.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: YanColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: YanColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: YanColors.border),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: YanColors.primaryBlue,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Advokatga ariza yozdirish',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: YanColors.primaryNavy,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'E2EE himoyalangan • 30 daqiqada tayyor ariza',
                              style: TextStyle(
                                color: YanColors.mutedText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Indicator Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            stepBadgeText,
                            style: const TextStyle(
                              color: YanColors.primaryBlue,
                              fontSize: 10.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              color: YanColors.mutedText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / 3,
                          minHeight: 6,
                          backgroundColor: YanColors.lightBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            YanColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildCurrentStepView(),
                    ),
                  ),
                ),

                // Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: const BoxDecoration(
                    color: YanColors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE4EEF8))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_step == 1) ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            onPressed: _skipDocumentsStep,
                            style: TextButton.styleFrom(
                              backgroundColor: YanColors.lightBlue,
                              foregroundColor: YanColors.primaryNavy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: YanColors.border),
                              ),
                            ),
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 18,
                              color: YanColors.primaryBlue,
                            ),
                            label: const Text(
                              'Hujjat bo‘lmasa o‘tkazib yuborish (Skip)',
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: <Widget>[
                          if (_step > 0) ...<Widget>[
                            GestureDetector(
                              onTap: _previousStep,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: YanColors.lightBlue,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: YanColors.border),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: YanColors.primaryNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _busy ? null : _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: YanColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _busy
                                    ? const CupertinoActivityIndicator(
                                        color: Colors.white,
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              _step == 2
                                                  ? 'TASDIQLASH VA ADVOKATGA YUBORISH'
                                                  : 'DAVOM ETISH',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13.8,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _step == 2
                                                ? Icons.send_rounded
                                                : Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_step) {
      case 0:
        return _buildStep1StatementForm();
      case 1:
        return _buildStep2DocumentsForm();
      default:
        return _buildStep3ReviewPage();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 1 / 3: VAZIYAT BAYONI ("Nima sodir bo‘lganini ayting.")
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildStep1StatementForm() {
    final charCount = _problemController.text.length;
    final adv = _resolvedAdvocate;

    return Column(
      key: const ValueKey<String>('step-1-statement'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'VAZIYAT BAYONI • TO‘G‘RIDAN-TO‘G‘RI MUROJAAT',
            style: TextStyle(
              color: YanColors.primaryBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nima sodir\nbo‘lganini ayting.',
          style: TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Muhim sanalar, ishtirokchilar va nimaga erishmoqchi ekanligingizni yozing. Hozircha bilmagan ma’lumotlarni taxmin qilib kiritishingiz shart emas.',
          style: TextStyle(
            color: YanColors.mutedText,
            fontSize: 13.2,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),

        // Selected Advocate Banner (Tap to switch)
        LiquidGlassWindow(
          padding: const EdgeInsets.all(14),
          onTap: _openAdvocatePickerSheet,
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: YanColors.primaryNavy,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _loadingAdvocates
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        adv.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'QABUL QILUVCHI RASMIY ADVOKAT:',
                      style: TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w900,
                        color: YanColors.primaryBlue,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            adv.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: YanColors.primaryBlue,
                        ),
                      ],
                    ),
                    Text(
                      'Litsenziya: ${adv.licenseNumber} • Tayyorlash muddati: 30 daqiqa',
                      style: const TextStyle(
                        fontSize: 11.3,
                        color: YanColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: YanColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tanlash',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: YanColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Subject Pills
        const Text(
          'ARIZA MAVZUSI (IXTIYORIY TEZ TANLOV):',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: YanColors.mutedText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickSubjectSuggestions.map((topic) {
              final active = _subjectController.text.trim() == topic;
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: GestureDetector(
                  onTap: () => setState(() => _subjectController.text = topic),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active ? YanColors.primaryBlue : YanColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? YanColors.primaryBlue : YanColors.border,
                      ),
                    ),
                    child: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : YanColors.primaryNavy,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Detailed Multiline Statement Input Card
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: YanColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: YanColors.primaryBlue.withValues(alpha: 0.35),
              width: 1.3,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0B0E2A54),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _problemController,
                maxLines: 8,
                maxLength: 5000,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.48,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText:
                      'Masalan: Muammo qachon boshlandi, kimlar ishtirok etgan, qanday hujjatlar bor va qanday yechim kutyapsiz...',
                  hintStyle: TextStyle(
                    color: YanColors.subtleText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const Divider(height: 16, color: Color(0xFFE4EEF8)),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: YanColors.successGreen,
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Zero-Knowledge E2EE bilan shifrlanadi',
                      style: TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w700,
                        color: YanColors.successGreen,
                      ),
                    ),
                  ),
                  Text(
                    '$charCount / 5000',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: YanColors.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Helpful Tip Row
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YanColors.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline_rounded,
                color: YanColors.primaryBlue,
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Aniq va xolis yozing. Parol yoki bank karta PIN-kodi kabi maxfiy ma’lumotlarni kiritmang.',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 2 / 3: DALILLAR VA HUJJATLAR ("Hujjatlaringizni tartib bilan qo‘shing.")
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildStep2DocumentsForm() {
    return Column(
      key: const ValueKey<String>('step-2-documents'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'DALILLAR VA HUJJATLAR • E2EE',
            style: TextStyle(
              color: YanColors.primaryBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Hujjatlaringizni\ntartib bilan qo‘shing.',
          style: TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.14,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pasport, shartnoma, yozishmalar yoki ishga tegishli hujjatlarning rasmlarini qo‘shishingiz mumkin. Hujjat bo‘lmasa, o‘tkazib yuboring.',
          style: TextStyle(
            color: YanColors.mutedText,
            fontSize: 13.2,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),

        // Main Upload Box
        GestureDetector(
          onTap: _openAttachmentPickerSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: YanColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: YanColors.primaryBlue.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0B0E2A54),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: YanColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: YanColors.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hujjat qo‘shish',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: YanColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Galereya yoki kamera • ${_files.length} / 10 ta rasm tanlandi',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: YanColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (_files.isNotEmpty) ...<Widget>[
          const Text(
            'QO‘SHILGAN HUJJATLAR TARTIBI:',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: YanColors.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(_files.length, (index) {
            final file = _files[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: YanColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: YanColors.border),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: YanColors.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(file.path),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: YanColors.lightBlue,
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: YanColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: YanColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${index + 1}-tartibdagi E2EE hujjat',
                          style: const TextStyle(
                            fontSize: 11.2,
                            color: YanColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: index > 0 ? () => _moveFileUp(index) : null,
                    icon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: index < _files.length - 1
                        ? () => _moveFileDown(index)
                        : null,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _files.removeAt(index)),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: YanColors.destructiveRed,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],

        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YanColors.border),
          ),
          child: const Row(
            children: <Widget>[
              Icon(
                Icons.verified_user_rounded,
                color: YanColors.primaryBlue,
                size: 19,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tanlangan hujjatlar E2EE shifrlangan holda to‘g‘ridan-to‘g‘ri advokat chatiga tartib bilan yuboriladi.',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STEP 3 / 3: REVIEW PAGE ("Murojaatingizni tekshirib chiqing.")
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildStep3ReviewPage() {
    final adv = _resolvedAdvocate;
    final profile = userProfile.value;
    final dynamicFeeUzs = YanRoleDataCatalog.computeArizaFeeUzs(profile);
    final subject = _subjectController.text.trim().isEmpty
        ? 'Rasmiy huquqiy ariza'
        : _subjectController.text.trim();

    return Column(
      key: const ValueKey<String>('step-3-review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'YUBORISHDAN OLDIN • TEKSHIRUV',
            style: TextStyle(
              color: YanColors.primaryBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Murojaatingizni\ntekshirib chiqing.',
          style: TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.14,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tasdiqlaganingizdan so‘ng barcha ma’lumotlar tanlangan advokat profiliga chat xabari sifatida tartib bilan yuboriladi va 30 daqiqalik taymer ishga tushadi.',
          style: TextStyle(
            color: YanColors.mutedText,
            fontSize: 13.0,
            height: 1.44,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Selected Advocate Review Card
        _ReviewSectionCard(
          icon: Icons.verified_user_rounded,
          sectionTitle: 'Qabul qiluvchi advokat',
          onEditTap: _openAdvocatePickerSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                adv.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${adv.specialization} • Litsenziya: ${adv.licenseNumber}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: YanColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: YanColors.successGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '⏳ Tayyor bo‘lish muddati: 30 daqiqa (Real-vaqt nazorati)',
                  style: TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A936B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Detailed Statement Review Card
        _ReviewSectionCard(
          icon: Icons.subject_rounded,
          sectionTitle: 'Vaziyat bayoni ($subject)',
          onEditTap: () => setState(() => _step = 0),
          child: Text(
            _problemController.text.trim(),
            style: const TextStyle(
              fontSize: 13.8,
              fontWeight: FontWeight.w600,
              color: YanColors.primaryNavy,
              height: 1.48,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Attached Documents Review Card
        _ReviewSectionCard(
          icon: Icons.attach_file_rounded,
          sectionTitle: 'Hujjatlar (${_files.length} ta)',
          onEditTap: () => setState(() => _step = 1),
          child: _files.isEmpty
              ? const Text(
                  'Hujjat qo‘shilmagan (chatda ham yuborishingiz mumkin)',
                  style: TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w600,
                    color: YanColors.mutedText,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(_files.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: YanColors.primaryBlue,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${i + 1}. ${_files[i].name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 12),

        // Dynamic Pricing Banner (Only shows price if dynamicFeeUzs > 0; free for now)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: YanColors.lightBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: YanColors.border),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.verified_rounded,
                color: YanColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dynamicFeeUzs > 0
                      ? 'Xizmat to‘lovi: $dynamicFeeUzs so‘m • E2EE orqali advokat chatiga yuboriladi.'
                      : 'Murojaat E2EE shifrlangan holda advokat chatiga bepul yuboriladi. Tayyor ariza #ariza tegi bilan "Arizalarim" bo‘limida paydo bo‘ladi.',
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSectionCard extends StatelessWidget {
  final IconData icon;
  final String sectionTitle;
  final VoidCallback onEditTap;
  final Widget child;

  const _ReviewSectionCard({
    required this.icon,
    required this.sectionTitle,
    required this.onEditTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YanColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YanColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0E2A54),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: YanColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: YanColors.primaryNavy,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: YanColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Tahrirlash',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: YanColors.lightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YanColors.border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: YanColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.8,
                      color: YanColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}