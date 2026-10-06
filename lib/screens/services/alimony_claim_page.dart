import 'package:flutter/material.dart';

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

  static const Color _background = Color(0xFF061827);
  static const Color _background2 = Color(0xFF0B2236);

  static const Color _primary = Color(0xFF7B61FF);
  static const Color _primaryLight = Color(0xFF9B87FF);

  static const Color _pink = Color(0xFFD95C9E);
  static const Color _cyan = Color(0xFF56D8E8);

  static const Color _white = Colors.white;
  static const Color _muted = Color(0xFF9FB1C3);

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

  final _marriagePlaceController = TextEditingController();
  final _marriageActNumberController = TextEditingController();

  DateTime? _marriageDate;

  String? _claimantRegion;
  String? _claimantDistrict;

  String? _respondentRegion;
  String? _respondentDistrict;

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

    _marriagePlaceController.dispose();
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

        return true;

      case 2:
        if (_marriagePlaceController.text.trim().isEmpty) {
          _showError('Nikoh qayd etilgan joyni kiriting.');
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
            _showError('Farzandning ismini kiriting.');
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
          backgroundColor: const Color(0xFF331D2B),
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

  // ===============================================================
  // CHILDREN
  // ===============================================================

  void _addChild() {
    if (_children.length >= 10) {
      _showError('10 nafargacha farzand qoʻshish mumkin.');
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
            colorScheme: const ColorScheme.dark(
              primary: _primary,
              surface: Color(0xFF122B41),
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

  // ===============================================================
  // BACKEND-READY PAYLOAD
  // ===============================================================

  Map<String, dynamic> buildPayload() {
    return {
      'type': 'aliment_undirish_new',

      'claimant': {
        'full_name': _claimantNameController.text.trim(),
        'phone': _claimantPhoneController.text.trim(),
        'region': _claimantRegion,
        'district': _claimantDistrict,
        'address': _claimantAddressController.text.trim(),
      },

      'respondent': {
        'full_name': _respondentNameController.text.trim(),
        'phone': _respondentPhoneController.text.trim(),
        'region': _respondentRegion,
        'district': _respondentDistrict,
        'address': _respondentAddressController.text.trim(),
      },

      'marriage': {
        'place': _marriagePlaceController.text.trim(),
        'date': _marriageDate?.toIso8601String(),
        'act_number': _marriageActNumberController.text.trim(),
      },

      'children': _children.map((child) {
        return {
          'full_name': child.name.text.trim(),
          'birth_date': child.birthDate?.toIso8601String(),
        };
      }).toList(),
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
        // FRONTEND ONLY FOR NOW.
        //
        // Backend integration will be added here later.
        await Future<void>.delayed(
          const Duration(milliseconds: 1200),
        );
      }

      if (!mounted) return;

      _showSuccess();
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Maʼlumotlarni yuborishda xatolik yuz berdi.',
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
          decoration: const BoxDecoration(
            color: Color(0xFF10283D),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
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
              const SizedBox(height: 28),

              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B61FF),
                      Color(0xFFD95C9E),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
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
                'Ariza maʼlumotlari tayyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Frontend qismi muvaffaqiyatli yakunlandi. '
                'Keyingi bosqichda maʼlumotlar backendga yuboriladi.',
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
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
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -90,
          child: _Glow(
            color: _primary,
            size: 260,
          ),
        ),
        Positioned(
          top: 280,
          left: -120,
          child: _Glow(
            color: _pink,
            size: 240,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: _Glow(
            color: _cyan,
            size: 220,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // TOP BAR
  // ===============================================================

  Widget _buildTopBar() {
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
                const Text(
                  'Bolaga aliment undirish',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _steps[_currentStep].subtitle,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Text(
              '${_currentStep + 1}/${_steps.length}',
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

  // ===============================================================
  // PROGRESS
  // ===============================================================

  Widget _buildProgress(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          _primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // STEP 1
  // ===============================================================

  Widget _buildClaimantStep() {
    return _StepPage(
      key: const ValueKey('claimant'),
      icon: Icons.person_outline_rounded,
      eyebrow: 'ARIZACHI',
      title: 'Avval siz haqingizda',
      description:
          'Arizani tayyorlash uchun shaxsiy maʼlumotlaringizni kiriting.',
      children: [
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
          options: const [
            'Toshkent shahri',
            'Toshkent viloyati',
            'Samarqand viloyati',
            'Buxoro viloyati',
            'Fargʻona viloyati',
            'Andijon viloyati',
            'Namangan viloyati',
            'Qashqadaryo viloyati',
            'Surxondaryo viloyati',
            'Xorazm viloyati',
            'Navoiy viloyati',
            'Jizzax viloyati',
            'Sirdaryo viloyati',
            'Qoraqalpogʻiston Respublikasi',
          ],
          onChanged: (value) {
            setState(() {
              _claimantRegion = value;
            });
          },
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
          options: const [
            'Toshkent shahri',
            'Toshkent viloyati',
            'Samarqand viloyati',
            'Buxoro viloyati',
            'Fargʻona viloyati',
            'Andijon viloyati',
            'Namangan viloyati',
            'Qashqadaryo viloyati',
            'Surxondaryo viloyati',
            'Xorazm viloyati',
            'Navoiy viloyati',
            'Jizzax viloyati',
            'Sirdaryo viloyati',
            'Qoraqalpogʻiston Respublikasi',
          ],
          onChanged: (value) {
            setState(() {
              _respondentRegion = value;
            });
          },
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
        _Field(
          controller: _marriagePlaceController,
          label: 'Nikoh qayd etilgan joy',
          hint: 'FHDYO bo‘limi nomi',
          icon: Icons.account_balance_outlined,
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
          title: 'Aniq bilmasangiz',
          text:
              'Maydonni hozircha boʻsh qoldirishingiz mumkin. '
              'Keyinroq tahrirlash imkoniyati boʻladi.',
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
                              colorScheme: const ColorScheme.dark(
                                primary: _primary,
                                surface: Color(0xFF122B41),
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
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _primary.withOpacity(0.35),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: _primaryLight,
                ),
                SizedBox(width: 9),
                Text(
                  'Yana farzand qoʻshish',
                  style: TextStyle(
                    color: _primaryLight,
                    fontWeight: FontWeight.w800,
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
              'Reference loyihadagi huquqiy maʼlumotlarda '
              '1 bola uchun 1/4, 2 bola uchun 1/3, '
              '3 va undan ortiq bola uchun 1/2 daromad '
              'koʻrsatilgan.',
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
              _claimantAddressController.text,
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
              _respondentAddressController.text,
            ),
          ],
        ),

        _ReviewCard(
          icon: Icons.favorite_border_rounded,
          title: 'Nikoh',
          rows: [
            _ReviewRow(
              'Joy',
              _marriagePlaceController.text,
            ),
            _ReviewRow(
              'Sana',
              _formatDate(_marriageDate),
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
                _children[index].name.text,
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: _cyan,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Maʼlumotlaringiz ariza tayyorlash uchun '
                  'ishlatiladi. Backend ulanishi keyingi bosqichda qoʻshiladi.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.45,
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _background.withOpacity(0.0),
            _background.withOpacity(0.97),
            _background,
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
                    colors: isLast
                        ? const [
                            Color(0xFFD95C9E),
                            Color(0xFF7B61FF),
                          ]
                        : const [
                            Color(0xFF7B61FF),
                            Color(0xFF5B8CFF),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.25),
                      blurRadius: 25,
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
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast
                                  ? 'ARIZANI TAYYORLASH'
                                  : 'DAVOM ETISH',
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 25 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8C76FF),
                        Color(0xFF5D80FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF)
                            .withOpacity(0.28),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: Color(0xFF9B87FF),
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
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

// ===================================================================
// TEXT FIELD
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
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _AlimonyClaimPageState._primaryLight,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF6E8397),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF8499AC),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.055),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: _AlimonyClaimPageState._primary,
                  width: 1.2,
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
// DROPDOWN
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
            value: value,
            dropdownColor: const Color(0xFF102A40),
            iconEnabledColor: Colors.white54,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF8499AC),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.055),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: _AlimonyClaimPageState._primary,
                ),
              ),
            ),
            hint: const Text(
              'Tanlang',
              style: TextStyle(
                color: Color(0xFF6E8397),
                fontSize: 13,
              ),
            ),
            items: options
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: onChanged,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.055),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF8499AC),
                    size: 20,
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.075),
            Colors.white.withOpacity(0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _AlimonyClaimPageState._pink
                      .withOpacity(0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Color(0xFFFF9BCA),
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Farzand ${index + 1}',
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
            controller: data.name,
            label: 'Toʻliq ism',
            hint: 'Farzandning F.I.Sh.',
            icon: Icons.badge_outlined,
          ),

          _DateField(
            label: 'Tugʻilgan sana',
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
// REVIEW
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.075),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _AlimonyClaimPageState._primaryLight,
                size: 20,
              ),
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
                    width: 82,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFF71879B),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value.isEmpty
                          ? 'Kiritilmagan'
                          : row.value,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AlimonyClaimPageState._cyan.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _AlimonyClaimPageState._cyan.withOpacity(0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _AlimonyClaimPageState._cyan,
            size: 20,
          ),
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
                    color: Color(0xFF91A8BA),
                    fontSize: 11.5,
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
// GLASS BUTTON
// ===================================================================

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
          color: Colors.white.withOpacity(0.065),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

// ===================================================================
// GLOW
// ===================================================================

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
  });

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
              color: color.withOpacity(0.13),
              blurRadius: size * 0.65,
              spreadRadius: size * 0.05,
            ),
          ],
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