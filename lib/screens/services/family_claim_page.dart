import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/alimony_location_catalog.dart';
import '../../services/family_claim_document_service.dart';
import '../../shared/user_profile.dart';

class FamilyClaimPage extends StatefulWidget {
  const FamilyClaimPage({
    super.key,
    required this.type,
    this.onSubmit,
  });

  final FamilyClaimType type;
  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<FamilyClaimPage> createState() => _FamilyClaimPageState();
}

class _FamilyClaimPageState extends State<FamilyClaimPage>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF061827);
  static const Color _muted = Color(0xFF9FB1C3);

  static const List<String> _weekdays = <String>[
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ];

  static final List<String> _clockOptions = List<String>.generate(
    13,
    (index) => '${(index + 7).toString().padLeft(2, '0')}:00',
    growable: false,
  );

  static final List<int> _amountOptions = List<int>.generate(
    ((50000000 - 2100000) ~/ 100000) + 1,
    (index) => 2100000 + (index * 100000),
    growable: false,
  );

  static const String _reasonDisagreement = 'o‘zaro kelishmovchiliklar';
  static const String _reasonDivorced =
      'nikoh bekor qilinganligi (ajrashganligimiz)';

  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Plaintiff
  final _plaintiffNameController = TextEditingController();
  final _plaintiffPhoneController = TextEditingController();
  final _plaintiffStreetController = TextEditingController();
  String? _plaintiffRegion;
  String? _plaintiffDistrict;

  // Step 2: Defendant
  final _defendantNameController = TextEditingController();
  final _defendantPhoneController = TextEditingController();
  final _defendantStreetController = TextEditingController();
  String? _defendantRegion;
  String? _defendantDistrict;

  // Step 3: Marriage & FHDYO
  final _marriageActNumberController = TextEditingController();
  String? _fhdyoRegion;
  String? _fhdyoDistrict;
  DateTime? _marriageDate;

  // Step 4: Service-specific fields
  int _selectedAmountValue = 2100000;
  DateTime? _livingApartDate;
  String _visitationReason = _reasonDisagreement;
  String _meetWeekend = 'Shanba';
  String _meetClock = '10:00';
  String _endWeekend = 'Yakshanba';
  String _endClock = '16:00';

  // Step 5: Children
  bool _hasNoChildren = false;
  final List<_ChildEntry> _children = <_ChildEntry>[_ChildEntry()];

  bool get _isMother => widget.type == FamilyClaimType.motherSupport;
  bool get _isResidence => widget.type == FamilyClaimType.childResidence;
  bool get _isVisitation => widget.type == FamilyClaimType.childVisitation;
  bool get _isDivorce => widget.type == FamilyClaimType.divorce;

  Color get _primaryColor => switch (widget.type) {
    FamilyClaimType.motherSupport => const Color(0xFF329D96),
    FamilyClaimType.childResidence => const Color(0xFF4D8DFF),
    FamilyClaimType.childVisitation => const Color(0xFF8B68F6),
    FamilyClaimType.divorce => const Color(0xFFD9844A),
  };

  Color get _secondaryColor => switch (widget.type) {
    FamilyClaimType.motherSupport => const Color(0xFF69E0D3),
    FamilyClaimType.childResidence => const Color(0xFF62DDEB),
    FamilyClaimType.childVisitation => const Color(0xFFC3A6FF),
    FamilyClaimType.divorce => const Color(0xFFFFC285),
  };

  String get _pageTitle => switch (widget.type) {
    FamilyClaimType.motherSupport => 'Ona ta’minoti uchun aliment',
    FamilyClaimType.childResidence => 'Bolaning yashash joyini belgilash',
    FamilyClaimType.childVisitation => 'Bola bilan ko‘rishish tartibi',
    FamilyClaimType.divorce => 'Nikohdan ajrashish',
  };

  String get _serviceTypeCode => switch (widget.type) {
    FamilyClaimType.motherSupport => 'ona_taminoti',
    FamilyClaimType.childResidence => 'bolaning_yashash_joyi',
    FamilyClaimType.childVisitation => 'bola_korishish',
    FamilyClaimType.divorce => 'nikoh_ajrashish',
  };

  List<_StepMeta> get _steps => <_StepMeta>[
    const _StepMeta(
      number: '01',
      title: 'Siz haqingizda',
      subtitle: 'Da’vogar ma’lumotlari',
      icon: Icons.person_outline_rounded,
    ),
    _StepMeta(
      number: '02',
      title: 'Javobgar haqida',
      subtitle: _isVisitation
          ? 'Bolasi bor taraf ma’lumotlari'
          : 'Turmush o‘rtog‘ingiz ma’lumotlari',
      icon: Icons.person_search_outlined,
    ),
    const _StepMeta(
      number: '03',
      title: 'Nikoh ma’lumotlari',
      subtitle: 'FHDYO va nikoh qaydi',
      icon: Icons.favorite_border_rounded,
    ),
    _StepMeta(
      number: '04',
      title: switch (widget.type) {
        FamilyClaimType.motherSupport => 'Ta’minot miqdori',
        FamilyClaimType.childResidence => 'Alohida yashash',
        FamilyClaimType.childVisitation => 'Ko‘rishish vaqti',
        FamilyClaimType.divorce => 'Oilaviy holat',
      },
      subtitle: switch (widget.type) {
        FamilyClaimType.motherSupport => 'Oylik qat’iy summa',
        FamilyClaimType.childResidence => 'Nizo va alohida yashash sanasi',
        FamilyClaimType.childVisitation => 'Sabab va uchrashuv jadvali',
        FamilyClaimType.divorce => 'Alohida yashash sanasi',
      },
      icon: switch (widget.type) {
        FamilyClaimType.motherSupport => Icons.payments_outlined,
        FamilyClaimType.childResidence => Icons.home_work_outlined,
        FamilyClaimType.childVisitation => Icons.schedule_rounded,
        FamilyClaimType.divorce => Icons.event_busy_outlined,
      },
    ),
    const _StepMeta(
      number: '05',
      title: 'Farzandlar',
      subtitle: 'O‘rtadagi farzandlar ma’lumoti',
      icon: Icons.child_care_rounded,
    ),
    const _StepMeta(
      number: '06',
      title: 'Tekshirish',
      subtitle: 'Arizani yaratishdan oldin',
      icon: Icons.fact_check_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _plaintiffNameController.dispose();
    _plaintiffPhoneController.dispose();
    _plaintiffStreetController.dispose();
    _defendantNameController.dispose();
    _defendantPhoneController.dispose();
    _defendantStreetController.dispose();
    _marriageActNumberController.dispose();
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  bool _isValidPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length == 12) {
      digits = digits.substring(3);
    }
    return digits.length == 9;
  }

  String _formatPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length == 12) {
      digits = digits.substring(3);
    }
    if (digits.isEmpty) return '';
    if (digits.length == 9) {
      return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} '
          '${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    }
    return '+998 $digits';
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'Sanani tanlang';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _fullAddress(String? region, String? district, String street) {
    return <String?>[region, district, street.trim()]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_plaintiffRegion == null || _plaintiffDistrict == null) {
          _showError('Da’vogarning viloyati va tumanini tanlang.');
          return false;
        }
        if (_plaintiffStreetController.text.trim().isEmpty) {
          _showError('MFY, ko‘cha va uy raqamingizni kiriting.');
          return false;
        }
        if (_plaintiffNameController.text.trim().isEmpty) {
          _showError('To‘liq F.I.Sh. ma’lumotingizni kiriting.');
          return false;
        }
        if (!_isValidPhone(_plaintiffPhoneController.text)) {
          _showError(
            'Da’vogar telefon raqami to‘liq 9 ta raqamdan iborat bo‘lishi shart.',
          );
          return false;
        }
        return true;

      case 1:
        if (_defendantRegion == null || _defendantDistrict == null) {
          _showError('Javobgar yashaydigan viloyat va tumanni tanlang.');
          return false;
        }
        if (_defendantStreetController.text.trim().isEmpty) {
          _showError('Javobgarning MFY, ko‘cha va uy raqamini kiriting.');
          return false;
        }
        if (_defendantNameController.text.trim().isEmpty) {
          _showError('Javobgarning to‘liq F.I.Sh. ma’lumotini kiriting.');
          return false;
        }
        if (_defendantPhoneController.text.trim().isNotEmpty &&
            !_isValidPhone(_defendantPhoneController.text)) {
          _showError(
            'Javobgar telefon raqamini to‘liq 9 ta raqam bilan kiriting yoki bo‘sh qoldiring.',
          );
          return false;
        }
        return true;

      case 2:
        if (_fhdyoRegion == null || _fhdyoDistrict == null) {
          _showError('Nikoh qayd etilgan FHDYO viloyati va tumanini tanlang.');
          return false;
        }
        if (_marriageDate == null) {
          _showError('Nikoh tuzilgan sanani tanlang.');
          return false;
        }
        if (_marriageActNumberController.text.trim().isEmpty) {
          _showError('Nikoh dalolatnomasi raqamini kiriting.');
          return false;
        }
        return true;

      case 3:
        if ((_isResidence || _isDivorce) && _livingApartDate == null) {
          _showError(
            'Javobgar bilan qachondan boshlab alohida yashayotganingizni tanlang.',
          );
          return false;
        }
        if (_isVisitation && _visitationReason.trim().isEmpty) {
          _showError('Birga yashamaslik sababini tanlang.');
          return false;
        }
        return true;

      case 4:
        if (_isDivorce && _hasNoChildren) {
          return true;
        }
        if (_children.isEmpty) {
          _showError('Kamida bitta farzand ma’lumotini kiriting.');
          return false;
        }
        for (var i = 0; i < _children.length; i++) {
          final child = _children[i];
          if (child.name.text.trim().isEmpty) {
            _showError('${i + 1}-farzandning to‘liq F.I.Sh.ni kiriting.');
            return false;
          }
          if (child.birthDate == null) {
            _showError('${i + 1}-farzandning tug‘ilgan sanasini tanlang.');
            return false;
          }
        }
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3A1E2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF8BA7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _setChildrenCount(int count) {
    setState(() {
      if (count <= 0) {
        _hasNoChildren = true;
        return;
      }
      _hasNoChildren = false;
      while (_children.length < count) {
        _children.add(_ChildEntry());
      }
      while (_children.length > count) {
        final removed = _children.removeLast();
        removed.dispose();
      }
    });
  }

  void _addChild() {
    if (_children.length >= 15) {
      _showError('15 nafargacha farzand qo‘shish mumkin.');
      return;
    }
    setState(() {
      _hasNoChildren = false;
      _children.add(_ChildEntry());
    });
  }

  void _removeChild(int index) {
    if (_children.length == 1) {
      if (_isDivorce) {
        setState(() => _hasNoChildren = true);
      } else {
        _showError('Kamida bitta farzand bo‘lishi kerak.');
      }
      return;
    }
    setState(() {
      final removed = _children.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 3),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: const Color(0xFF10283D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  Map<String, dynamic> buildPayload() {
    final courtName = AlimonyLocationCatalog.courtForDistrict(
      _defendantDistrict!,
    );
    final plaintiffAddress = _fullAddress(
      _plaintiffRegion,
      _plaintiffDistrict,
      _plaintiffStreetController.text,
    );
    final defendantAddress = _fullAddress(
      _defendantRegion,
      _defendantDistrict,
      _defendantStreetController.text,
    );

    final activeChildren = (_isDivorce && _hasNoChildren)
        ? const <_ChildEntry>[]
        : _children;

    final childrenList = activeChildren
        .map((child) {
          final birthNormal = FamilyClaimDocumentService.formatUzbekDate(
            child.birthDate!,
          );
          final birthDa = FamilyClaimDocumentService.formatUzbekDateWithDa(
            child.birthDate!,
          );
          return <String, dynamic>{
            'full_name': child.name.text.trim(),
            'birth_date': child.birthDate!.toIso8601String(),
            'birth_date_formatted': birthNormal,
            'birth_date_da_formatted': birthDa,
          };
        })
        .toList(growable: false);

    final childrenListFull = childrenList
        .asMap()
        .entries
        .map(
          (entry) =>
              '${entry.key + 1}. ${entry.value['full_name']} – '
              '${entry.value['birth_date_formatted']} da tug‘ilgan.',
        )
        .join('\n');

    final childrenBenefitList = childrenList
        .map(
          (child) =>
              '${child['birth_date_da_formatted']} tug‘ilgan ${child['full_name']}',
        )
        .join(', ');

    final count = childrenList.length;
    final childSuffix = count == 0
        ? "farzandimiz yo'q"
        : (count == 1 ? 'farzandimiz' : 'farzandlarimiz');

    final isDivorcedReason = _visitationReason == _reasonDivorced;
    final divorceNote = isDivorcedReason
        ? '(nikoh bekor qilinganligi dalolatnomasi ilova qilinadi)'
        : '';
    final divorceAttachment = isDivorcedReason
        ? '5. Nikoh bekor qilinganligi yuzasidan dalolatnoma.'
        : '';

    final livingSpFormatted = _livingApartDate == null
        ? ''
        : (_isDivorce
              ? FamilyClaimDocumentService.formatUzbekDate(_livingApartDate!)
              : FamilyClaimDocumentService.formatUzbekDateWithDan(
                  _livingApartDate!,
                ));

    return <String, dynamic>{
      'type': _serviceTypeCode,
      'court_name': courtName,
      'defendant_district': _defendantDistrict,
      'plaintiff_name': _plaintiffNameController.text.trim(),
      'plaintiff_address': plaintiffAddress,
      'plaintiff_phone': _formatPhone(_plaintiffPhoneController.text),
      'defendant_name': _defendantNameController.text.trim(),
      'defendant_address': defendantAddress,
      'defendant_phone': _formatPhone(_defendantPhoneController.text),
      'fhdyo_name': _fhdyoDistrict,
      'marriage_date': FamilyClaimDocumentService.formatUzbekDate(
        _marriageDate!,
      ),
      'marriage_act_number': _marriageActNumberController.text.trim(),
      'amount': FamilyClaimDocumentService.formatAmount(
        _selectedAmountValue.toString(),
      ),
      'living_sp_date': livingSpFormatted,
      'child_s': childSuffix,
      'disagreement_or_divorce': _visitationReason,
      'divorce_note': divorceNote,
      'divorce_attachment': divorceAttachment,
      'meet_weekend': _meetWeekend.toLowerCase(),
      'meet_clock': _meetClock,
      'end_weekend': _endWeekend.toLowerCase(),
      'end_clock': _endClock,
      'children_count': count.toString(),
      'children_list_full': childrenListFull,
      'children_benefit_list': childrenBenefitList,
      'children': childrenList,
      'date': FamilyClaimDocumentService.formatUzbekDate(DateTime.now()),
    };
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final payload = buildPayload();
      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      } else {
        await FamilyClaimDocumentService().create(widget.type, payload);
      }

      userProfile.value = userProfile.value.copyWith(
        savedDocuments: userProfile.value.savedDocuments + 1,
      );

      if (!mounted) return;
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      _showError(
        'Ariza hujjatini yaratib saqlashda xatolik yuz berdi. Ma’lumotlarni tekshirib qayta urinib ko‘ring.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
          decoration: const BoxDecoration(
            color: Color(0xFF10283D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[_primaryColor, _secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.35),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Ariza hujjati tayyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tayyor DOCX hujjat Hujjatlar bo‘limiga saqlandi. Uni Hujjatlar sahifasidan ochib ko‘rishingiz mumkin.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Tayyor',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final progress = (_currentStep + 1) / steps.length;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(steps),
                _buildProgress(progress),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPlaintiffStep(),
                      _buildDefendantStep(),
                      _buildMarriageStep(),
                      _buildSpecificStep(),
                      _buildChildrenStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),
                _buildBottomNavigation(steps.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -90,
          child: _Glow(color: _primaryColor, size: 260),
        ),
        Positioned(
          top: 280,
          left: -120,
          child: _Glow(color: _secondaryColor, size: 240),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: _Glow(color: _primaryColor, size: 220),
        ),
      ],
    );
  }

  Widget _buildTopBar(List<_StepMeta> steps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _back,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  steps[_currentStep].subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              '${_currentStep + 1}/${steps.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            );
          },
        ),
      ),
    );
  }

  // Step 1: Plaintiff
  Widget _buildPlaintiffStep() {
    return _StepPage(
      key: const ValueKey<String>('plaintiff'),
      icon: Icons.person_outline_rounded,
      eyebrow: 'DA’VOGAR (SIZ)',
      title: 'Avval siz haqingizda',
      description:
          'Arizani rasmiylashtirish uchun yashash manzilingiz va shaxsiy ma’lumotlaringizni kiriting.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _DropdownField(
          label: 'Viloyat / shaharni tanlang',
          value: _plaintiffRegion,
          icon: Icons.location_on_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) {
            setState(() {
              _plaintiffRegion = value;
              _plaintiffDistrict = null;
            });
          },
        ),
        _DropdownField(
          label: 'Tumanni tanlang',
          value: _plaintiffDistrict,
          icon: Icons.location_city_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.districtsFor(_plaintiffRegion),
          onChanged: (value) => setState(() => _plaintiffDistrict = value),
        ),
        _Field(
          controller: _plaintiffStreetController,
          label: 'MFY, ko‘cha, uy raqami',
          hint: 'Masalan: Mustaqillik MFY, 12-uy',
          icon: Icons.home_outlined,
          accentColor: _primaryColor,
          textCapitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _plaintiffNameController,
          label: 'To‘liq ismingiz (F.I.O)',
          hint: 'Masalan: Valiyeva Fotima G‘aniyevna',
          icon: Icons.badge_outlined,
          accentColor: _primaryColor,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _plaintiffPhoneController,
          label: 'Telefon raqamingiz (+998)',
          hint: '90 123 45 67',
          icon: Icons.phone_outlined,
          accentColor: _primaryColor,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
        ),
      ],
    );
  }

  // Step 2: Defendant & Auto Court Selection
  Widget _buildDefendantStep() {
    final resolvedCourt = _defendantDistrict == null
        ? null
        : AlimonyLocationCatalog.courtForDistrict(_defendantDistrict!);

    return _StepPage(
      key: const ValueKey<String>('defendant'),
      icon: Icons.person_search_outlined,
      eyebrow: 'JAVOBGAR',
      title: _isVisitation ? 'Bolasi bor taraf' : 'Turmush o‘rtog‘ingiz',
      description:
          'Sud yurisdiksiyasi qonun bo‘yicha javobgar yashaydigan tuman asosida avtomatik belgilanadi.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _DropdownField(
          label: 'Javobgar yashaydigan viloyat / shahar',
          value: _defendantRegion,
          icon: Icons.location_on_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) {
            setState(() {
              _defendantRegion = value;
              _defendantDistrict = null;
            });
          },
        ),
        _DropdownField(
          label: 'Tumanni tanlang (Yurisdiksiya shundan olinadi!)',
          value: _defendantDistrict,
          icon: Icons.account_balance_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.districtsFor(_defendantRegion),
          onChanged: (value) => setState(() => _defendantDistrict = value),
        ),
        if (resolvedCourt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _InfoCard(
              icon: Icons.gavel_rounded,
              title: 'Avtomatik aniqlangan sud',
              text:
                  'Ariza qonun bo‘yicha javobgar yashaydigan $resolvedCourt sudiga yo‘naltiriladi!',
              accentColor: _secondaryColor,
            ),
          ),
        _Field(
          controller: _defendantStreetController,
          label: 'MFY, ko‘cha, uy raqami',
          hint: 'Ko‘cha nomi va uy raqami',
          icon: Icons.home_outlined,
          accentColor: _primaryColor,
          textCapitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _defendantNameController,
          label: 'To‘liq ismi (F.I.O)',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          accentColor: _primaryColor,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _defendantPhoneController,
          label: 'Telefon raqami (agar bilsangiz)',
          hint: '90 123 45 67 (ixtiyoriy)',
          icon: Icons.phone_outlined,
          accentColor: _primaryColor,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
        ),
      ],
    );
  }

  // Step 3: Marriage & FHDYO
  Widget _buildMarriageStep() {
    return _StepPage(
      key: const ValueKey<String>('marriage'),
      icon: Icons.favorite_border_rounded,
      eyebrow: 'NIKOH VA FHDYO',
      title: 'Nikoh FHDYO ma’lumotlari',
      description:
          'Nikoh qayd etilgan FHDYO hududi, nikoh tuzilgan sana va dalolatnoma raqamini kiriting.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _DropdownField(
          label: 'Nikoh qayd etilgan FHDYO (Viloyati)',
          value: _fhdyoRegion,
          icon: Icons.account_balance_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) {
            setState(() {
              _fhdyoRegion = value;
              _fhdyoDistrict = null;
            });
          },
        ),
        _DropdownField(
          label: 'Nikoh qayd etilgan FHDYO (Tumani)',
          value: _fhdyoDistrict,
          icon: Icons.location_city_outlined,
          accentColor: _primaryColor,
          options: AlimonyLocationCatalog.districtsFor(_fhdyoRegion),
          onChanged: (value) => setState(() => _fhdyoDistrict = value),
        ),
        _DateField(
          label: 'Nikoh qachon tuzilgan?',
          value: _formatShortDate(_marriageDate),
          icon: Icons.calendar_month_outlined,
          onTap: () => _pickDate(
            current: _marriageDate,
            onSelected: (date) => _marriageDate = date,
          ),
        ),
        _Field(
          controller: _marriageActNumberController,
          label: 'Nikoh dalolatnomasi raqami',
          hint: 'Masalan: 125',
          icon: Icons.description_outlined,
          accentColor: _primaryColor,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  // Step 4: Service-specific step
  Widget _buildSpecificStep() {
    if (_isMother) {
      return _StepPage(
        key: const ValueKey<String>('mother_amount'),
        icon: Icons.payments_outlined,
        eyebrow: 'TA’MINOT MIQDORI',
        title: 'Oylik ta’minot summasi',
        description:
            'Farzandingiz 3 yoshga to‘lguniga qadar har oyda qat’iy summada undiriladigan ona ta’minoti miqdorini tanlang.',
        accentColor: _primaryColor,
        secondaryColor: _secondaryColor,
        children: [
          _DropdownField(
            label: 'Sizga kerakli oylik summa qancha?',
            value:
                '${FamilyClaimDocumentService.formatAmount(_selectedAmountValue.toString())} so‘m',
            icon: Icons.monetization_on_outlined,
            accentColor: _primaryColor,
            options: _amountOptions
                .map(
                  (amount) =>
                      '${FamilyClaimDocumentService.formatAmount(amount.toString())} so‘m',
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              final parsed = int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
              if (parsed != null) {
                setState(() => _selectedAmountValue = parsed);
              }
            },
          ),
          _InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Oila kodeksi 117-modda',
            text:
                'Bola tug‘ilgan kundan e’tiboran uch yil davomida yordamga muhtoj ona sud tartibida har oyda qat’iy summada ta’minot olish huquqiga ega.',
            accentColor: _secondaryColor,
          ),
        ],
      );
    }

    if (_isVisitation) {
      final isDivorced = _visitationReason == _reasonDivorced;
      return _StepPage(
        key: const ValueKey<String>('visitation_schedule'),
        icon: Icons.schedule_rounded,
        eyebrow: 'KO‘RISHISH VAQTI VA HOLAT',
        title: 'Ko‘rishish tartibi',
        description:
            'Birga yashamaslik sababini hamda farzandingiz bilan har hafta ko‘rishish vaqtini belgilang.',
        accentColor: _primaryColor,
        secondaryColor: _secondaryColor,
        children: [
          _DropdownField(
            label: 'Birga yashamasligingizga nima sabab bo‘lgan?',
            value: isDivorced
                ? 'Nikoh bekor qilinganligi'
                : 'O‘zaro kelishmovchiliklar',
            icon: Icons.help_outline_rounded,
            accentColor: _primaryColor,
            options: const <String>[
              'O‘zaro kelishmovchiliklar',
              'Nikoh bekor qilinganligi',
            ],
            onChanged: (value) {
              setState(() {
                _visitationReason = value == 'Nikoh bekor qilinganligi'
                    ? _reasonDivorced
                    : _reasonDisagreement;
              });
            },
          ),
          if (isDivorced)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _InfoCard(
                icon: Icons.attach_file_rounded,
                title: 'Qo‘shimcha ilova',
                text:
                    'Nikoh bekor qilinganligi tanlangani sababli arizaga "5. Nikoh bekor qilinganligi yuzasidan dalolatnoma" avtomatik kiritiladi.',
                accentColor: _secondaryColor,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Boshlanish kuni',
                  value: _meetWeekend,
                  icon: Icons.calendar_today_outlined,
                  accentColor: _primaryColor,
                  options: _weekdays,
                  onChanged: (value) {
                    if (value != null) setState(() => _meetWeekend = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownField(
                  label: 'Soati',
                  value: _meetClock,
                  icon: Icons.access_time_rounded,
                  accentColor: _primaryColor,
                  options: _clockOptions,
                  onChanged: (value) {
                    if (value != null) setState(() => _meetClock = value);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Qaytarish kuni',
                  value: _endWeekend,
                  icon: Icons.event_available_outlined,
                  accentColor: _primaryColor,
                  options: _weekdays,
                  onChanged: (value) {
                    if (value != null) setState(() => _endWeekend = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownField(
                  label: 'Soati',
                  value: _endClock,
                  icon: Icons.access_time_filled_rounded,
                  accentColor: _primaryColor,
                  options: _clockOptions,
                  onChanged: (value) {
                    if (value != null) setState(() => _endClock = value);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    // childResidence or divorce
    return _StepPage(
      key: const ValueKey<String>('living_apart'),
      icon: Icons.home_work_outlined,
      eyebrow: 'OILAVIY HOLAT',
      title: 'Alohida yashash sanasi',
      description:
          'Javobgar bilan qachondan boshlab oilaviy munosabatlarni to‘xtatib, birga yashamayotganingizni belgilang.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _DateField(
          label: 'Javobgar bilan qachondan boshlab birga yashamayapsiz?',
          value: _formatShortDate(_livingApartDate),
          icon: Icons.event_busy_outlined,
          onTap: () => _pickDate(
            current: _livingApartDate,
            onSelected: (date) => _livingApartDate = date,
          ),
        ),
        _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Shablon formati',
          text: _livingApartDate == null
              ? 'Sana tanlangach, hujjat matniga mos ravishda avtomatik formatlanadi.'
              : 'Hujjatda: "${FamilyClaimDocumentService.formatUzbekDateWithDan(_livingApartDate!)} buyon oilaviy munosabatlarni to‘xtatganmiz"',
          accentColor: _secondaryColor,
        ),
      ],
    );
  }

  // Step 5: Children
  Widget _buildChildrenStep() {
    final currentCount = (_isDivorce && _hasNoChildren) ? 0 : _children.length;
    final countOptions = <String>[
      if (_isDivorce) "Farzandimiz yo‘q (0 nafar)",
      ...List<String>.generate(15, (i) => '${i + 1} nafar'),
    ];
    final selectedCountLabel = currentCount == 0
        ? "Farzandimiz yo‘q (0 nafar)"
        : '$currentCount nafar';

    return _StepPage(
      key: const ValueKey<String>('children'),
      icon: Icons.child_care_rounded,
      eyebrow: 'FARZANDLAR TO‘G‘RISIDA',
      title: 'O‘rtadagi farzandlar',
      description: _isDivorce
          ? 'O‘rtadagi farzandlar sonini tanlang (agar farzandingiz bo‘lmasa, 0 nafarni tanlang).'
          : 'Voyaga yetmagan farzandlaringizning to‘liq F.I.Sh. va tug‘ilgan sanalarini kiriting.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _DropdownField(
          label: 'O‘rtadagi farzandlar soni',
          value: selectedCountLabel,
          icon: Icons.family_restroom_rounded,
          accentColor: _primaryColor,
          options: countOptions,
          onChanged: (value) {
            if (value == null) return;
            if (value.startsWith('Farzandimiz')) {
              _setChildrenCount(0);
            } else {
              final count = int.tryParse(value.split(' ').first) ?? 1;
              _setChildrenCount(count);
            }
          },
        ),
        if (!(_isDivorce && _hasNoChildren)) ...[
          Column(
            children: List<Widget>.generate(_children.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ChildCard(
                  index: index,
                  entry: _children[index],
                  accentColor: _primaryColor,
                  canDelete: _children.length > 1 || _isDivorce,
                  onDelete: () => _removeChild(index),
                  onDateTap: () => _pickDate(
                    current: _children[index].birthDate,
                    onSelected: (date) => _children[index].birthDate = date,
                  ),
                ),
              );
            }),
          ),
          if (_children.length < 15)
            GestureDetector(
              onTap: _addChild,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: _secondaryColor,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Yana farzand qo‘shish',
                      style: TextStyle(
                        color: _secondaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  // Step 6: Review
  Widget _buildReviewStep() {
    final court = _defendantDistrict == null
        ? ''
        : '${AlimonyLocationCatalog.courtForDistrict(_defendantDistrict!)} sudi';
    final activeChildren = (_isDivorce && _hasNoChildren)
        ? const <_ChildEntry>[]
        : _children;

    return _StepPage(
      key: const ValueKey<String>('review'),
      icon: Icons.fact_check_outlined,
      eyebrow: 'YAKUNIY TEKSHIRUV',
      title: 'Ma’lumotlarni tasdiqlang',
      description:
          'Ariza DOCX faylini yaratishdan oldin barcha bandlarni ko‘zdan kechiring.',
      accentColor: _primaryColor,
      secondaryColor: _secondaryColor,
      children: [
        _ReviewCard(
          icon: Icons.person_outline_rounded,
          title: 'Da’vogar',
          accentColor: _secondaryColor,
          rows: [
            _ReviewRow('F.I.Sh.', _plaintiffNameController.text.trim()),
            _ReviewRow('Telefon', _formatPhone(_plaintiffPhoneController.text)),
            _ReviewRow(
              'Manzil',
              _fullAddress(
                _plaintiffRegion,
                _plaintiffDistrict,
                _plaintiffStreetController.text,
              ),
            ),
          ],
        ),
        _ReviewCard(
          icon: Icons.person_search_outlined,
          title: 'Javobgar va Sud',
          accentColor: _secondaryColor,
          rows: [
            _ReviewRow('F.I.Sh.', _defendantNameController.text.trim()),
            _ReviewRow(
              'Telefon',
              _defendantPhoneController.text.trim().isEmpty
                  ? 'Kiritilmagan'
                  : _formatPhone(_defendantPhoneController.text),
            ),
            _ReviewRow(
              'Manzil',
              _fullAddress(
                _defendantRegion,
                _defendantDistrict,
                _defendantStreetController.text,
              ),
            ),
            _ReviewRow('Sud', court),
          ],
        ),
        _ReviewCard(
          icon: Icons.favorite_border_rounded,
          title: 'Nikoh va Ariza tafsilotlari',
          accentColor: _secondaryColor,
          rows: [
            _ReviewRow('FHDYO', '${_fhdyoDistrict ?? ''} FHDYO bo‘limi'),
            _ReviewRow(
              'Nikoh sanasi',
              _marriageDate == null
                  ? ''
                  : FamilyClaimDocumentService.formatUzbekDate(_marriageDate!),
            ),
            _ReviewRow(
              'Dalolatnoma',
              _marriageActNumberController.text.trim(),
            ),
            if (_isMother)
              _ReviewRow(
                'Ta’minot summasi',
                '${FamilyClaimDocumentService.formatAmount(_selectedAmountValue.toString())} so‘m',
              ),
            if (_isResidence || _isDivorce)
              _ReviewRow(
                'Alohida yashash',
                _livingApartDate == null
                    ? ''
                    : FamilyClaimDocumentService.formatUzbekDateWithDan(
                        _livingApartDate!,
                      ),
              ),
            if (_isVisitation) ...[
              _ReviewRow('Sabab', _visitationReason),
              _ReviewRow(
                'Ko‘rishish vaqti',
                '${_meetWeekend.toLowerCase()} $_meetClock dan ${_endWeekend.toLowerCase()} $_endClock gacha',
              ),
            ],
          ],
        ),
        _ReviewCard(
          icon: Icons.child_care_rounded,
          title: 'Farzandlar (${activeChildren.length} nafar)',
          accentColor: _secondaryColor,
          rows: activeChildren.isEmpty
              ? const <_ReviewRow>[
                  _ReviewRow('Holat', 'Farzandimiz yo‘q (0 nafar)'),
                ]
              : List<_ReviewRow>.generate(activeChildren.length, (index) {
                  final child = activeChildren[index];
                  final dob = child.birthDate == null
                      ? ''
                      : FamilyClaimDocumentService.formatUzbekDate(
                          child.birthDate!,
                        );
                  return _ReviewRow(
                    '${index + 1}-farzand',
                    '${child.name.text.trim()} • $dob',
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(int totalSteps) {
    final isLast = _currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _bg.withValues(alpha: 0.0),
            _bg.withValues(alpha: 0.97),
            _bg,
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _GlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: _back,
                size: 56,
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: _isSubmitting ? null : _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[_primaryColor, _secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'ARIZANI TAYYORLASH' : 'DAVOM ETISH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isLast
                                  ? Icons.auto_awesome_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.secondaryColor,
    required this.children,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color accentColor;
  final Color secondaryColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[accentColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.28),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFA5B6C8),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: accentColor,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF6E8397),
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF8499AC), size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.055),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(color: accentColor, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color accentColor;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = options.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            value: effectiveValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF102A40),
            iconEnabledColor: Colors.white54,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF8499AC), size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.055),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
            hint: const Text(
              'Tanlang',
              style: TextStyle(color: Color(0xFF6E8397), fontSize: 13),
            ),
            items: options
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: options.isEmpty ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != 'Sanani tanlang';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF8499AC), size: 20),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: hasValue
                            ? Colors.white
                            : const Color(0xFF6E8397),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.index,
    required this.entry,
    required this.accentColor,
    required this.canDelete,
    required this.onDelete,
    required this.onDateTap,
  });

  final int index;
  final _ChildEntry entry;
  final Color accentColor;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final dateText = entry.birthDate == null
        ? 'Sanani tanlang'
        : '${entry.birthDate!.day.toString().padLeft(2, '0')}.'
              '${entry.birthDate!.month.toString().padLeft(2, '0')}.'
              '${entry.birthDate!.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.child_care_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '${index + 1}-farzand',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 19,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            controller: entry.name,
            label: '${index + 1}-farzand to‘liq F.I.Sh.',
            hint: 'Masalan: Valiyev Ali G‘aniyevich',
            icon: Icons.badge_outlined,
            accentColor: accentColor,
            textCapitalization: TextCapitalization.words,
          ),
          _DateField(
            label: 'Tug‘ilgan sanasi',
            value: dateText,
            icon: Icons.cake_outlined,
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFB4C6D8),
                    fontSize: 12,
                    height: 1.45,
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_ReviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 105,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFF71879B),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value.isEmpty ? 'Kiritilmagan' : row.value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.065),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.13),
              blurRadius: size * 0.65,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildEntry {
  final TextEditingController name = TextEditingController();
  DateTime? birthDate;

  void dispose() {
    name.dispose();
  }
}

class _StepMeta {
  const _StepMeta({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _ReviewRow {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;
}
