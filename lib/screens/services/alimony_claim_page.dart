import 'package:flutter/material.dart';

import '../../services/alimony_location_catalog.dart';
import '../../shared/user_profile.dart';

/// ===============================================================
/// ALIMONY CLAIM — FRONTEND
/// ===============================================================
///
/// This page is intentionally independent from the backend.
///
/// Later, [buildPayload()] can be sent to the backend.
/// The reference project expects:
///
///     type: "aliment_undirish_new"
///
/// No payment, API, Telegram or document-generation logic belongs
/// in this screen.
/// ===============================================================

class AlimonyClaimPage extends StatefulWidget {
  const AlimonyClaimPage({
    super.key,
    this.onSubmit,
  });

  /// Optional callback for the future backend integration.
  ///
  /// Example later:
  ///
  /// onSubmit: (payload) async {
  ///   await api.createDocument(payload);
  /// }
  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<AlimonyClaimPage> createState() => _AlimonyClaimPageState();
}

class _AlimonyClaimPageState extends State<AlimonyClaimPage>
    with TickerProviderStateMixin {
  // ===============================================================
  // THEME
  // ===============================================================

  static const Color _background = Color(0xFFF5F8FC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF1677D2);
  static const Color _primarySoft = Color(0xFFEAF3FC);
  static const Color _navy = Color(0xFF102B50);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFDCE6F2);
  static const Color _success = Color(0xFF10B981);

  // ===============================================================
  // STEPS
  // ===============================================================

  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  final List<_AlimonyStep> _steps = const [
    _AlimonyStep(
      number: '01',
      title: 'Siz haqingizda',
      subtitle: 'Arizachi maʼlumotlari',
      icon: Icons.person_outline_rounded,
    ),
    _AlimonyStep(
      number: '02',
      title: 'Javobgar haqida',
      subtitle: 'Aliment toʻlovchi maʼlumotlari',
      icon: Icons.person_search_outlined,
    ),
    _AlimonyStep(
      number: '03',
      title: 'Nikoh maʼlumotlari',
      subtitle: 'Nikoh va FHDYO maʼlumotlari',
      icon: Icons.favorite_border_rounded,
    ),
    _AlimonyStep(
      number: '04',
      title: 'Farzandlar',
      subtitle: 'Voyaga yetmagan farzandlar',
      icon: Icons.child_care_rounded,
    ),
    _AlimonyStep(
      number: '05',
      title: 'Tekshirish',
      subtitle: 'Arizani yuborishdan oldin',
      icon: Icons.fact_check_outlined,
    ),
  ];

  // ===============================================================
  // FORM CONTROLLERS
  // ===============================================================

  final _claimantNameController = TextEditingController();
  final _claimantPhoneController = TextEditingController();
  final _claimantAddressController = TextEditingController();

  final _respondentNameController = TextEditingController();
  final _respondentPhoneController = TextEditingController();
  final _respondentAddressController = TextEditingController();

  final _marriageActNumberController = TextEditingController();

  DateTime? _marriageDate;

  String? _claimantRegion;
  String? _claimantDistrict;

  String? _respondentRegion;
  String? _respondentDistrict;

  String? _fhdyoRegion;
  String? _fhdyoDistrict;

  final List<_ChildData> _children = [
    _ChildData(),
  ];

  // ===============================================================
  // LIFECYCLE
  // ===============================================================

  @override
  void dispose() {
    _pageController.dispose();

    _claimantNameController.dispose();
    _claimantPhoneController.dispose();
    _claimantAddressController.dispose();

    _respondentNameController.dispose();
    _respondentPhoneController.dispose();
    _respondentAddressController.dispose();

    _marriageActNumberController.dispose();

    for (final child in _children) {
      child.dispose();
    }

    super.dispose();
  }

  // ===============================================================
  // NAVIGATION
  // ===============================================================

  void _next() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });

      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentStep--;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  // ===============================================================
  // VALIDATION
  // ===============================================================

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_claimantNameController.text.trim().isEmpty) {
          _showError('Iltimos, toʻliq ismingizni kiriting.');
          return false;
        }

        if (_claimantPhoneController.text.trim().isEmpty) {
          _showError('Telefon raqamingizni kiriting.');
          return false;
        }

        if (_claimantAddressController.text.trim().isEmpty) {
          _showError('Yashash manzilingizni kiriting.');
          return false;
        }
        if (_claimantRegion == null || _claimantDistrict == null) {
          _showError('Viloyat va tumaningizni tanlang.');
          return false;
        }
        if (!_isValidPhone(_claimantPhoneController.text)) {
          _showError('Telefon raqami 9 ta raqamdan iborat boʻlishi kerak.');
          return false;
        }

        return true;

      case 1:
        if (_respondentNameController.text.trim().isEmpty) {
          _showError('Javobgarning toʻliq ismini kiriting.');
          return false;
        }

        if (_respondentAddressController.text.trim().isEmpty) {
          _showError('Javobgarning manzilini kiriting.');
          return false;
        }
        if (_respondentRegion == null || _respondentDistrict == null) {
          _showError('Javobgarning viloyati va tumanini tanlang.');
          return false;
        }
        if (_respondentPhoneController.text.trim().isNotEmpty &&
            !_isValidPhone(_respondentPhoneController.text)) {
          _showError('Javobgarning telefon raqami 9 ta raqam boʻlishi kerak.');
          return false;
        }

        return true;

      case 2:
        if (_fhdyoRegion == null || _fhdyoDistrict == null) {
          _showError('Nikoh qayd etilgan FHDYO viloyati va tumanini tanlang.');
          return false;
        }
        if (_marriageDate == null ||
            _marriageActNumberController.text.trim().isEmpty) {
          _showError('Nikoh sanasi va dalolatnoma raqamini kiriting.');
          return false;
        }

        return true;

      case 3:
        if (_children.isEmpty) {
          _showError('Kamida bitta farzand qoʻshing.');
          return false;
        }

        for (final child in _children) {
          if (child.name.text.trim().isEmpty) {
            _showError('Farzandning toʻliq ismini kiriting.');
            return false;
          }
          if (child.birthDate == null) {
            _showError('Har bir farzandning tugʻilgan sanasini tanlang.');
            return false;
          }
        }

        return true;

      case 4:
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
          backgroundColor: _navy,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFCA5A5),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ===============================================================
  // CHILDREN
  // ===============================================================

  void _addChild() {
    if (_children.length >= 15) {
      _showError('15 nafargacha farzand qoʻshish mumkin.');
      return;
    }

    setState(() {
      _children.add(_ChildData());
    });
  }

  void _removeChild(int index) {
    if (_children.length == 1) {
      _showError('Kamida bitta farzand boʻlishi kerak.');
      return;
    }

    setState(() {
      final child = _children.removeAt(index);
      child.dispose();
    });
  }

  // ===============================================================
  // DATE
  // ===============================================================

  Future<void> _pickMarriageDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _marriageDate ?? DateTime(now.year - 5),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _marriageDate = selected;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sanani tanlang';

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  static const _monthNames = <String>[
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr',
  ];

  String _formatTemplateDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-yil ${date.day}-${_monthNames[date.month - 1]}';
  }

  bool _isValidPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length == 12) {
      digits = digits.substring(3);
    }
    return digits.length == 9;
  }

  String _formattedPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length == 12) {
      digits = digits.substring(3);
    }
    return digits.isEmpty ? '' : '+998 $digits';
  }

  String _fullAddress(String? region, String? district, String street) =>
      [region, district, street.trim()].whereType<String>()
          .where((part) => part.trim().isNotEmpty).join(', ');

  // ===============================================================
  // BACKEND-READY PAYLOAD
  // ===============================================================

  Map<String, dynamic> buildPayload() {
    final children = _children.map((child) {
      return {
        'full_name': child.name.text.trim(),
        'birth_date': child.birthDate?.toIso8601String(),
        'birth_date_formatted': _formatTemplateDate(child.birthDate),
      };
    }).toList(growable: false);
    final courtName = AlimonyLocationCatalog.courtForDistrict(
      _respondentDistrict!,
    );
    final plaintiffAddress = _fullAddress(
      _claimantRegion, _claimantDistrict, _claimantAddressController.text,
    );
    final defendantAddress = _fullAddress(
      _respondentRegion, _respondentDistrict, _respondentAddressController.text,
    );

    return {
      'type': 'aliment_undirish_new',
      'court_name': courtName,
      'plaintiff_name': _claimantNameController.text.trim(),
      'plaintiff_address': plaintiffAddress,
      'plaintiff_phone': _formattedPhone(_claimantPhoneController.text),
      'defendant_name': _respondentNameController.text.trim(),
      'defendant_address': defendantAddress,
      'defendant_phone': _formattedPhone(_respondentPhoneController.text),
      'fhdyo_name': _fhdyoDistrict,
      'marriage_date': _formatTemplateDate(_marriageDate),
      'marriage_act_number': _marriageActNumberController.text.trim(),
      'children_count': children.length.toString(),
      'children_list_full': children.asMap().entries.map((entry) =>
          '${entry.key + 1}. ${entry.value['full_name']} – '
          '${entry.value['birth_date_formatted']} da tugʻilgan.'
      ).join('\n'),
      'children_benefit_list': children.map((child) =>
          '${child['birth_date_formatted']} da tugʻilgan ${child['full_name']}'
      ).join(', '),
      'date': _formatTemplateDate(DateTime.now()),
      'claimant': {
        'full_name': _claimantNameController.text.trim(),
        'phone': _formattedPhone(_claimantPhoneController.text),
        'region': _claimantRegion,
        'district': _claimantDistrict,
        'address': plaintiffAddress,
      },
      'respondent': {
        'full_name': _respondentNameController.text.trim(),
        'phone': _formattedPhone(_respondentPhoneController.text),
        'region': _respondentRegion,
        'district': _respondentDistrict,
        'address': defendantAddress,
      },
      'marriage': {
        'place': _fhdyoDistrict,
        'region': _fhdyoRegion,
        'district': _fhdyoDistrict,
        'date': _marriageDate?.toIso8601String(),
        'act_number': _marriageActNumberController.text.trim(),
      },
      'children': children,
    };
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final payload = buildPayload();

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      } else {
        throw StateError('Document generation service is not connected.');
      }

      if (!mounted) return;

      _showSuccess();
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Ariza hujjatini yaratib saqlashda xatolik yuz berdi. Qayta urinib koʻring.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccess() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFECFDF5),
                    border: Border.all(
                      color: _success.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _success,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ariza hujjati tayyor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tayyor DOCX hujjat Arizalarim boʻlimiga saqlandi. Uni Arizalarim sahifasidan ochib koʻrishingiz mumkin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Tayyor',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                _buildProgress(progress),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildClaimantStep(),
                      _buildRespondentStep(),
                      _buildMarriageStep(),
                      _buildChildrenStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),

                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BACKGROUND
  // ===============================================================

  Widget _buildBackground() {
    return const SizedBox.shrink();
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EFF7)),
        ),
      ),
      child: Row(
        children: [
          _GlassButton(
            icon: Icons.arrow_back_rounded,
            onTap: _back,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bolaga aliment undirish',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentStep + 1}-qadam · ${_steps[_currentStep].subtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primary.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              '${_currentStep + 1}/${_steps.length}',
              style: const TextStyle(
                color: _primary,
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
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List<Widget>.generate(_steps.length, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              height: 4.5,
              margin: EdgeInsets.only(
                right: index == _steps.length - 1 ? 0 : 6,
              ),
              decoration: BoxDecoration(
                color: isActive ? _primary : _border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _fillFromProfile() {
    final p = userProfile.value;
    setState(() {
      if (p.displayName.trim().isNotEmpty) {
        _claimantNameController.text = p.displayName.trim();
      }
      final digits = p.phone.replaceAll(RegExp(r"\D"), "");
      if (digits.length >= 9) {
        _claimantPhoneController.text = digits.substring(digits.length - 9);
      }
      if (AlimonyLocationCatalog.regions.contains(p.region)) {
        _claimantRegion = p.region;
        final dists = AlimonyLocationCatalog.districtsFor(p.region);
        if (dists.contains(p.district)) {
          _claimantDistrict = p.district;
        }
      }
      if (p.streetAddress.trim().isNotEmpty) {
        _claimantAddressController.text = p.streetAddress.trim();
      }
    });
  }

  Widget _buildClaimantStep() {
    return _StepPage(
      key: const ValueKey('claimant'),
      icon: Icons.person_outline_rounded,
      eyebrow: 'ARIZACHI',
      title: 'Avval siz haqingizda',
      description:
          'Arizani tayyorlash uchun shaxsiy maʼlumotlaringizni kiriting.',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fillFromProfile,
              style: OutlinedButton.styleFrom(
                backgroundColor: _primarySoft,
                foregroundColor: _primary,
                side: BorderSide(color: _primary.withValues(alpha: 0.28)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text(
                'Profil rekvizitlaridan avtomatik to‘ldirish',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        _Field(
          controller: _claimantNameController,
          label: 'Toʻliq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _claimantPhoneController,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _DropdownField(
          label: 'Viloyat / shahar',
          value: _claimantRegion,
          icon: Icons.location_on_outlined,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) {
            setState(() {
              _claimantRegion = value;
              _claimantDistrict = null;
            });
          },
        ),
        _DropdownField(
          label: 'Tuman',
          value: _claimantDistrict,
          icon: Icons.location_city_outlined,
          options: AlimonyLocationCatalog.districtsFor(_claimantRegion),
          onChanged: (value) => setState(() => _claimantDistrict = value),
        ),
        _Field(
          controller: _claimantAddressController,
          label: 'Yashash manzili',
          hint: 'MFY, ko‘cha, uy, xonadon',
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  // ===============================================================
  // STEP 2
  // ===============================================================

  Widget _buildRespondentStep() {
    return _StepPage(
      key: const ValueKey('respondent'),
      icon: Icons.person_search_outlined,
      eyebrow: 'JAVOBGAR',
      title: 'Endi javobgar haqida',
      description:
          'Aliment undirilishi soʻralayotgan shaxs maʼlumotlari.',
      children: [
        _Field(
          controller: _respondentNameController,
          label: 'Toʻliq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _respondentPhoneController,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _DropdownField(
          label: 'Viloyat / shahar',
          value: _respondentRegion,
          icon: Icons.location_on_outlined,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) {
            setState(() {
              _respondentRegion = value;
              _respondentDistrict = null;
            });
          },
        ),
        _DropdownField(
          label: 'Tuman (sud hududi)',
          value: _respondentDistrict,
          icon: Icons.location_city_outlined,
          options: AlimonyLocationCatalog.districtsFor(_respondentRegion),
          onChanged: (value) => setState(() => _respondentDistrict = value),
        ),
        if (_respondentDistrict != null)
          _InfoCard(
            icon: Icons.account_balance_outlined,
            title: 'Tegishli sud',
            text: '${AlimonyLocationCatalog.courtForDistrict(_respondentDistrict!)} sudi javobgar manzili boʻyicha tanlandi.',
          ),
        _Field(
          controller: _respondentAddressController,
          label: 'Javobgarning manzili',
          hint: 'Maʼlum boʻlgan manzil',
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  // ===============================================================
  // STEP 3
  // ===============================================================

  Widget _buildMarriageStep() {
    return _StepPage(
      key: const ValueKey('marriage'),
      icon: Icons.favorite_border_rounded,
      eyebrow: 'NIKOH',
      title: 'Nikoh maʼlumotlari',
      description:
          'Nikoh haqidagi maʼlumotlarni imkon qadar aniq kiriting.',
      children: [
        _DropdownField(
          label: 'FHDYO viloyati / shahri',
          value: _fhdyoRegion,
          icon: Icons.account_balance_outlined,
          options: AlimonyLocationCatalog.regions,
          onChanged: (value) => setState(() {
            _fhdyoRegion = value;
            _fhdyoDistrict = null;
          }),
        ),
        _DropdownField(
          label: 'FHDYO tumani / shahri',
          value: _fhdyoDistrict,
          icon: Icons.location_city_outlined,
          options: AlimonyLocationCatalog.districtsFor(_fhdyoRegion),
          onChanged: (value) => setState(() => _fhdyoDistrict = value),
        ),

        _DateField(
          label: 'Nikoh sanasi',
          value: _formatDate(_marriageDate),
          icon: Icons.calendar_month_outlined,
          onTap: _pickMarriageDate,
        ),

        _Field(
          controller: _marriageActNumberController,
          label: 'Dalolatnoma raqami',
          hint: 'Masalan: 125',
          icon: Icons.description_outlined,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 4),

        _InfoCard(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Aniq maʼlumot kiriting',
          text: 'FHDYO hududi, nikoh sanasi va dalolatnoma raqami ariza shabloniga kiritiladi.',
        ),
      ],
    );
  }

  // ===============================================================
  // STEP 4
  // ===============================================================

  Widget _buildChildrenStep() {
    return _StepPage(
      key: const ValueKey('children'),
      icon: Icons.child_care_rounded,
      eyebrow: 'FARZANDLAR',
      title: 'Farzandlaringiz',
      description:
          'Aliment undirilishi soʻralayotgan voyaga yetmagan farzandlarni qoʻshing.',
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: Column(
            children: List.generate(
              _children.length,
              (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ChildCard(
                    index: index,
                    data: _children[index],
                    canDelete: _children.length > 1,
                    onDelete: () => _removeChild(index),
                    onDateTap: () async {
                      final now = DateTime.now();

                      final date = await showDatePicker(
                        context: context,
                        initialDate: _children[index].birthDate ??
                            DateTime(now.year - 8),
                        firstDate: DateTime(1950),
                        lastDate: now,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: _primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: _navy,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (date != null) {
                        setState(() {
                          _children[index].birthDate = date;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),

        GestureDetector(
          onTap: _addChild,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primary.withValues(alpha: 0.30),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: _primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Yana farzand qoʻshish',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Aliment miqdori',
          text:
              'Oʻzbekiston Respublikasi Oila kodeksiga muvofiq '
              '1 bola uchun 1/4, 2 bola uchun 1/3, '
              '3 va undan ortiq bola uchun 1/2 qism miqdorida '
              'aliment undiriladi.',
        ),
      ],
    );
  }

  // ===============================================================
  // STEP 5 — REVIEW
  // ===============================================================

  Widget _buildReviewStep() {
    return _StepPage(
      key: const ValueKey('review'),
      icon: Icons.fact_check_outlined,
      eyebrow: 'YAKUNIY TEKSHIRUV',
      title: 'Hammasi tayyormi?',
      description:
          'Ariza tayyorlashdan oldin maʼlumotlaringizni tekshirib chiqing.',
      children: [
        _ReviewCard(
          icon: Icons.person_outline_rounded,
          title: 'Arizachi',
          rows: [
            _ReviewRow(
              'F.I.Sh.',
              _claimantNameController.text,
            ),
            _ReviewRow(
              'Telefon',
              _claimantPhoneController.text,
            ),
            _ReviewRow(
              'Manzil',
              _fullAddress(_claimantRegion, _claimantDistrict, _claimantAddressController.text),
            ),
          ],
        ),

        _ReviewCard(
          icon: Icons.person_search_outlined,
          title: 'Javobgar',
          rows: [
            _ReviewRow(
              'F.I.Sh.',
              _respondentNameController.text,
            ),
            _ReviewRow(
              'Telefon',
              _respondentPhoneController.text.isEmpty
                  ? 'Kiritilmagan'
                  : _respondentPhoneController.text,
            ),
            _ReviewRow(
              'Manzil',
              _fullAddress(_respondentRegion, _respondentDistrict, _respondentAddressController.text),
            ),
            _ReviewRow(
              'Sud',
              _respondentDistrict == null ? '' : '${AlimonyLocationCatalog.courtForDistrict(_respondentDistrict!)} sudi',
            ),
          ],
        ),

        _ReviewCard(
          icon: Icons.favorite_border_rounded,
          title: 'Nikoh',
          rows: [
            _ReviewRow(
              'Joy',
              _fhdyoDistrict ?? '',
            ),
            _ReviewRow(
              'Sana',
              _formatDate(_marriageDate),
            ),
            _ReviewRow(
              'FHDYO hududi',
              _fhdyoRegion ?? '',
            ),
            _ReviewRow(
              'Dalolatnoma',
              _marriageActNumberController.text.isEmpty
                  ? 'Kiritilmagan'
                  : _marriageActNumberController.text,
            ),
          ],
        ),

        _ReviewCard(
          icon: Icons.child_care_rounded,
          title: 'Farzandlar',
          rows: List.generate(
            _children.length,
            (index) {
              return _ReviewRow(
                '${index + 1}-farzand',
                '${_children[index].name.text} • ${_formatDate(_children[index].birthDate)}',
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _primary.withValues(alpha: 0.18),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _primary,
                size: 20,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Maʼlumotlaringiz rasmiy daʼvo arizasi (DOCX) hujjatini shakllantirish uchun ishlatiladi.',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // BOTTOM NAVIGATION
  // ===============================================================

  Widget _buildBottomNavigation() {
    final isLast = _currentStep == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: Color(0xFFE8EFF7)),
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
                size: 52,
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: _isSubmitting ? null : _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 52,
                decoration: BoxDecoration(
                  color: _isSubmitting
                      ? _primary.withValues(alpha: 0.7)
                      : _primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Arizani tayyorlash' : 'Davom etish',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
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

// ===================================================================
// STEP PAGE
// ===================================================================

class _StepPage extends StatelessWidget {
  const _StepPage({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6F2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08102B50),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1677D2).withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF1677D2),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: const TextStyle(
                              color: Color(0xFF1677D2),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF102B50),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ===================================================================
// INPUT FIELD
// ===================================================================

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102B50),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: Color(0xFF102B50),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF1677D2),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE6F2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF1677D2),
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// DROPDOWN FIELD
// ===================================================================

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final IconData icon;
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
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102B50),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: effectiveValue,
            isExpanded: true,
            dropdownColor: Colors.white,
            iconEnabledColor: const Color(0xFF64748B),
            borderRadius: BorderRadius.circular(16),
            style: const TextStyle(
              color: Color(0xFF102B50),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF1677D2),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE6F2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF1677D2),
                  width: 1.6,
                ),
              ),
            ),
            hint: const Text(
              'Tanlang',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            items: options
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102B50),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: options.isEmpty ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// DATE FIELD
// ===================================================================

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
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102B50),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFDCE6F2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF1677D2),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: hasValue
                            ? const Color(0xFF102B50)
                            : const Color(0xFF94A3B8),
                        fontSize: 14.5,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
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

// ===================================================================
// CHILD CARD
// ===================================================================

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.index,
    required this.data,
    required this.canDelete,
    required this.onDelete,
    required this.onDateTap,
  });

  final int index;
  final _ChildData data;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE6F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.child_friendly_rounded,
                  color: Color(0xFF1677D2),
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '${index + 1}-farzand',
                  style: const TextStyle(
                    color: Color(0xFF102B50),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canDelete)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Field(
            controller: data.name,
            label: 'Farzandning F.I.Sh.',
            hint: 'Toʻliq ism-familiyasi',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          _DateField(
            label: 'Tugʻilgan sanasi',
            value: data.birthDate == null
                ? 'Sanani tanlang'
                : '${data.birthDate!.day.toString().padLeft(2, '0')}.'
                  '${data.birthDate!.month.toString().padLeft(2, '0')}.'
                  '${data.birthDate!.year}',
            icon: Icons.cake_outlined,
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// REVIEW CARD
// ===================================================================

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_ReviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE6F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08102B50),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1677D2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102B50),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF3F9)),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.value.isEmpty ? '—' : row.value,
                      style: const TextStyle(
                        color: Color(0xFF102B50),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
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

// ===================================================================
// INFO CARD
// ===================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1677D2).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1677D2),
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102B50),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
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

// ===================================================================
// GLASS BUTTON (LIGHT SURFACE)
// ===================================================================

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
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
          color: const Color(0xFFF5F8FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFDCE6F2),
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF102B50),
          size: 19,
        ),
      ),
    );
  }
}

// ===================================================================
// DATA CLASSES
// ===================================================================

class _ChildData {
  final TextEditingController name = TextEditingController();
  DateTime? birthDate;

  void dispose() {
    name.dispose();
  }
}

class _AlimonyStep {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _AlimonyStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ReviewRow {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);
}