import 'package:flutter/material.dart';

/// ===============================================================
/// BOLANING YASHASH JOYINI BELGILASH
/// ===============================================================
/// Frontend-only implementation.
///
/// Reference-project service type:
///   bolaning_yashash_joyi
///
/// Reference-project price:
///   4,990,000 so'm
///
/// The page intentionally stops at a backend-ready payload.
/// Payment, API calls and DOCX generation are NOT implemented here.
///
/// The payload keys mirror the placeholders used by the reference
/// project's bolaning_yashash_joyi.docx template:
///
/// court_name
/// plaintiff_name
/// plaintiff_address
/// plaintiff_phone
/// defendant_name
/// defendant_address
/// defendant_phone
/// fhdyo_name
/// marriage_date
/// marriage_act_number
/// children_count
/// children_benefit_list
/// child_s
/// living_sp_date
/// date
/// ===============================================================

class ChildLivingPlacePage extends StatefulWidget {
  const ChildLivingPlacePage({
    super.key,
    this.onSubmit,
  });

  /// Future backend hook.
  ///
  /// Example later:
  /// onSubmit: (payload) => api.createLegalDocument(payload),
  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<ChildLivingPlacePage> createState() => _ChildLivingPlacePageState();
}

class _ChildLivingPlacePageState extends State<ChildLivingPlacePage>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Visual system
  // ---------------------------------------------------------------------------

  static const Color _bg = Color(0xFF061827);
  static const Color _bg2 = Color(0xFF0B2236);
  static const Color _primary = Color(0xFF4D8DFF);
  static const Color _primary2 = Color(0xFF75B7FF);
  static const Color _cyan = Color(0xFF62DDEB);
  static const Color _green = Color(0xFF69D8B1);
  static const Color _white = Colors.white;
  static const Color _muted = Color(0xFF9DB1C4);

  // ---------------------------------------------------------------------------
  // Step model
  // ---------------------------------------------------------------------------

  static const List<_FormStep> _steps = [
    _FormStep(
      number: '01',
      title: 'Siz haqingizda',
      subtitle: 'Daʼvogar maʼlumotlari',
      icon: Icons.person_outline_rounded,
    ),
    _FormStep(
      number: '02',
      title: 'Javobgar haqida',
      subtitle: 'Ikkinchi ota-ona maʼlumotlari',
      icon: Icons.person_search_outlined,
    ),
    _FormStep(
      number: '03',
      title: 'Nikoh maʼlumotlari',
      subtitle: 'FHDYO va nikoh tafsilotlari',
      icon: Icons.favorite_border_rounded,
    ),
    _FormStep(
      number: '04',
      title: 'Farzandlar',
      subtitle: 'Birgalikdagi farzandlar',
      icon: Icons.child_care_rounded,
    ),
    _FormStep(
      number: '05',
      title: 'Nizo haqida',
      subtitle: 'Alohida yashash holati',
      icon: Icons.home_work_outlined,
    ),
    _FormStep(
      number: '06',
      title: 'Tekshirish',
      subtitle: 'Arizani yuborishdan oldin',
      icon: Icons.fact_check_outlined,
    ),
  ];

  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // ---------------------------------------------------------------------------
  // Plaintiff
  // ---------------------------------------------------------------------------

  final _courtName = TextEditingController();
  final _plaintiffName = TextEditingController();
  final _plaintiffAddress = TextEditingController();
  final _plaintiffPhone = TextEditingController();

  // ---------------------------------------------------------------------------
  // Defendant
  // ---------------------------------------------------------------------------

  final _defendantName = TextEditingController();
  final _defendantAddress = TextEditingController();
  final _defendantPhone = TextEditingController();

  // ---------------------------------------------------------------------------
  // Marriage
  // ---------------------------------------------------------------------------

  final _fhdyoName = TextEditingController();
  final _marriageActNumber = TextEditingController();

  DateTime? _marriageDate;

  // ---------------------------------------------------------------------------
  // Children
  // ---------------------------------------------------------------------------

  final List<_ChildData> _children = [_ChildData()];

  // ---------------------------------------------------------------------------
  // Living arrangement
  // ---------------------------------------------------------------------------

  DateTime? _livingSpDate;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _pageController.dispose();

    _courtName.dispose();
    _plaintiffName.dispose();
    _plaintiffAddress.dispose();
    _plaintiffPhone.dispose();

    _defendantName.dispose();
    _defendantAddress.dispose();
    _defendantPhone.dispose();

    _fhdyoName.dispose();
    _marriageActNumber.dispose();

    for (final child in _children) {
      child.dispose();
    }

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> _goToStep(int step) async {
    if (step < 0 || step >= _steps.length) return;

    setState(() {
      _currentStep = step;
    });

    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _steps.length - 1) {
      await _goToStep(_currentStep + 1);
    } else {
      await _submit();
    }
  }

  Future<void> _back() async {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    await _goToStep(_currentStep - 1);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_courtName.text.trim().isEmpty) {
          _showError('Sud nomini kiriting.');
          return false;
        }
        if (_plaintiffName.text.trim().isEmpty) {
          _showError('Daʼvogarning toʻliq ismini kiriting.');
          return false;
        }
        if (_plaintiffAddress.text.trim().isEmpty) {
          _showError('Daʼvogarning manzilini kiriting.');
          return false;
        }
        if (_plaintiffPhone.text.trim().isEmpty) {
          _showError('Daʼvogarning telefon raqamini kiriting.');
          return false;
        }
        return true;

      case 1:
        if (_defendantName.text.trim().isEmpty) {
          _showError('Javobgarning toʻliq ismini kiriting.');
          return false;
        }
        if (_defendantAddress.text.trim().isEmpty) {
          _showError('Javobgarning manzilini kiriting.');
          return false;
        }
        if (_defendantPhone.text.trim().isEmpty) {
          _showError('Javobgarning telefon raqamini kiriting.');
          return false;
        }
        return true;

      case 2:
        if (_fhdyoName.text.trim().isEmpty) {
          _showError('FHDYO nomini kiriting.');
          return false;
        }
        if (_marriageDate == null) {
          _showError('Nikoh sanasini tanlang.');
          return false;
        }
        if (_marriageActNumber.text.trim().isEmpty) {
          _showError('Nikoh dalolatnoma raqamini kiriting.');
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
            _showError('Har bir farzandning toʻliq ismini kiriting.');
            return false;
          }
        }
        return true;

      case 4:
        if (_livingSpDate == null) {
          _showError('Alohida yashash boshlangan sanani tanlang.');
          return false;
        }
        return true;

      case 5:
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
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          backgroundColor: const Color(0xFF351F2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF91A8),
              ),
              const SizedBox(width: 11),
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

  // ---------------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 5),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Color(0xFF102B42),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Sanani tanlang';

    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
  }

  // ---------------------------------------------------------------------------
  // Children
  // ---------------------------------------------------------------------------

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

    final child = _children.removeAt(index);
    child.dispose();

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Payload
  // ---------------------------------------------------------------------------

  /// Backend-ready payload.
  ///
  /// These keys deliberately mirror the reference DOCX placeholders.
  Map<String, dynamic> buildPayload() {
    final childNames = _children
        .map((child) => child.name.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return {
      'type': 'bolaning_yashash_joyi',

      'court_name': _courtName.text.trim(),

      'plaintiff_name': _plaintiffName.text.trim(),
      'plaintiff_address': _plaintiffAddress.text.trim(),
      'plaintiff_phone': _plaintiffPhone.text.trim(),

      'defendant_name': _defendantName.text.trim(),
      'defendant_address': _defendantAddress.text.trim(),
      'defendant_phone': _defendantPhone.text.trim(),

      'fhdyo_name': _fhdyoName.text.trim(),
      'marriage_date': _date(_marriageDate),
      'marriage_act_number': _marriageActNumber.text.trim(),

      'children_count': childNames.length,
      'children_benefit_list': childNames.join(', '),
      'child_s': childNames.length == 1 ? 'farzandni' : 'farzandlarni',

      'living_sp_date': _date(_livingSpDate),

      'date': _date(DateTime.now()),

      // Structured data is kept as well so the future backend does not
      // have to parse a display string back into individual children.
      'children': _children
          .map(
            (child) => {
              'full_name': child.name.text.trim(),
            },
          )
          .toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = buildPayload();

      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      } else {
        // FRONTEND ONLY.
        // Replace this block with the API call later.
        await Future<void>.delayed(
          const Duration(milliseconds: 1300),
        );
      }

      if (!mounted) return;
      _showReadySheet();
    } catch (_) {
      if (!mounted) return;
      _showError('Maʼlumotlarni yuborishda xatolik yuz berdi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Ready sheet
  // ---------------------------------------------------------------------------

  void _showReadySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
              const SizedBox(height: 27),

              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      _primary,
                      _cyan,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.34),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 43,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Maʼlumotlar tayyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Ariza tayyorlash uchun barcha kerakli '
                'maʼlumotlar yigʻildi. Keyingi bosqichda '
                'backend orqali hujjat shakllantiriladi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('TAYYOR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _steps.length;
    final last = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: _bg,
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
                      _buildPlaintiff(),
                      _buildDefendant(),
                      _buildMarriage(),
                      _buildChildren(),
                      _buildLivingSituation(),
                      _buildReview(),
                    ],
                  ),
                ),

                _buildBottomBar(last),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -110,
          right: -100,
          child: _Glow(
            color: _primary,
            size: 280,
          ),
        ),
        Positioned(
          top: 310,
          left: -125,
          child: _Glow(
            color: _cyan,
            size: 240,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -90,
          child: _Glow(
            color: _green,
            size: 220,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
      child: Row(
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _back,
          ),
          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bolaning yashash joyi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  Widget _buildProgress(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
              valueColor: const AlwaysStoppedAnimation(_primary),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Plaintiff
  // ---------------------------------------------------------------------------

  Widget _buildPlaintiff() {
    return _StepPage(
      key: const ValueKey('plaintiff'),
      icon: Icons.person_outline_rounded,
      eyebrow: 'DAʼVOGAR',
      title: 'Siz haqingizda',
      description:
          'Bolaning yashash joyi siz bilan belgilanishi uchun '
          'daʼvogar maʼlumotlarini kiriting.',
      children: [
        _Field(
          controller: _courtName,
          label: 'Sud nomi',
          hint: 'Masalan: Chilonzor tumanlararo sudi',
          icon: Icons.account_balance_outlined,
          textCapitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _plaintiffName,
          label: 'Toʻliq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _plaintiffPhone,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _Field(
          controller: _plaintiffAddress,
          label: 'Hozirgi yashash manzili',
          hint: 'Viloyat, tuman, MFY, ko‘cha, uy...',
          icon: Icons.home_outlined,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Defendant
  // ---------------------------------------------------------------------------

  Widget _buildDefendant() {
    return _StepPage(
      key: const ValueKey('defendant'),
      icon: Icons.person_search_outlined,
      eyebrow: 'JAVOBGAR',
      title: 'Ikkinchi ota-ona',
      description:
          'Javobgarning arizada ko‘rsatiladigan asosiy '
          'maʼlumotlarini kiriting.',
      children: [
        _Field(
          controller: _defendantName,
          label: 'Toʻliq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _defendantPhone,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _Field(
          controller: _defendantAddress,
          label: 'Yashash manzili',
          hint: 'Maʼlum bo‘lgan manzil',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Maʼlumotni imkon qadar aniq kiriting',
          text:
              'Reference hujjatda daʼvogar va javobgarning '
              'manzili hamda telefon raqami alohida ko‘rsatiladi.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Marriage
  // ---------------------------------------------------------------------------

  Widget _buildMarriage() {
    return _StepPage(
      key: const ValueKey('marriage'),
      icon: Icons.favorite_border_rounded,
      eyebrow: 'NIKOH',
      title: 'Nikoh maʼlumotlari',
      description:
          'Nikoh qaydi haqidagi maʼlumotlar daʼvo arizasining '
          'asosiy qismida ishlatiladi.',
      children: [
        _Field(
          controller: _fhdyoName,
          label: 'FHDYO nomi',
          hint: 'Masalan: Muborak tumani',
          icon: Icons.apartment_outlined,
          textCapitalization: TextCapitalization.sentences,
        ),
        _DateField(
          label: 'Nikoh sanasi',
          value: _date(_marriageDate),
          icon: Icons.calendar_month_outlined,
          onTap: () => _pickDate(
            current: _marriageDate,
            onSelected: (value) {
              setState(() {
                _marriageDate = value;
              });
            },
          ),
        ),
        _Field(
          controller: _marriageActNumber,
          label: 'Nikoh dalolatnoma raqami',
          hint: 'Masalan: 125',
          icon: Icons.description_outlined,
          keyboardType: TextInputType.number,
        ),
        const _InfoCard(
          icon: Icons.auto_awesome_outlined,
          title: 'Keyinroq avtomatlashtiramiz',
          text:
              'Kelajakdagi backend ulanishida FHDYO va boshqa '
              'maʼlumotlarni avtomatik to‘ldirish imkonini qo‘shish mumkin.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Children
  // ---------------------------------------------------------------------------

  Widget _buildChildren() {
    return _StepPage(
      key: const ValueKey('children'),
      icon: Icons.child_care_rounded,
      eyebrow: 'FARZANDLAR',
      title: 'Birgalikdagi farzandlar',
      description:
          'Bolaning yashash joyi belgilanadigan farzand(lar)ni kiriting.',
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: Column(
            children: List.generate(
              _children.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: _ChildCard(
                  index: index,
                  data: _children[index],
                  canDelete: _children.length > 1,
                  onDelete: () => _removeChild(index),
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _addChild,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _primary.withOpacity(0.34),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: _primary2,
                ),
                SizedBox(width: 9),
                Text(
                  'Yana farzand qoʻshish',
                  style: TextStyle(
                    color: _primary2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.family_restroom_outlined,
          title: 'Bir nechta farzand',
          text:
              'Bir nechta farzand bo‘lsa, ularning barchasini '
              'alohida qo‘shishingiz mumkin. Yakuniy payload '
              'ularni ham ro‘yxat, ham umumiy ism satri sifatida saqlaydi.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5 — Living situation
  // ---------------------------------------------------------------------------

  Widget _buildLivingSituation() {
    return _StepPage(
      key: const ValueKey('living'),
      icon: Icons.home_work_outlined,
      eyebrow: 'NIZO',
      title: 'Alohida yashash',
      description:
          'Reference ariza oilaviy munosabatlar qachondan '
          'to‘xtagani haqida alohida maʼlumot oladi.',
      children: [
        _DateField(
          label: 'Alohida yashash boshlangan sana',
          value: _date(_livingSpDate),
          icon: Icons.event_outlined,
          onTap: () => _pickDate(
            current: _livingSpDate,
            onSelected: (value) {
              setState(() {
                _livingSpDate = value;
              });
            },
          ),
        ),
        const _LegalContextCard(),
        const SizedBox(height: 4),
        const _InfoCard(
          icon: Icons.shield_outlined,
          title: 'Bolaning manfaatlari',
          text:
              'Reference loyihadagi maʼlumot sahifasida bunday '
              'nizolar bolaning ustun manfaatidan kelib chiqib '
              'hal qilinishi taʼkidlangan.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 6 — Review
  // ---------------------------------------------------------------------------

  Widget _buildReview() {
    final childNames = _children
        .map((child) => child.name.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return _StepPage(
      key: const ValueKey('review'),
      icon: Icons.fact_check_outlined,
      eyebrow: 'YAKUNIY TEKSHIRUV',
      title: 'Arizangizga nazar',
      description:
          'Maʼlumotlarni tekshiring. Hammasi to‘g‘ri bo‘lsa, '
          'ariza maʼlumotlarini tayyorlang.',
      children: [
        _ReviewCard(
          icon: Icons.account_balance_outlined,
          title: 'Sud',
          rows: [
            _ReviewRow('Sud', _courtName.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.person_outline_rounded,
          title: 'Daʼvogar',
          rows: [
            _ReviewRow('F.I.Sh.', _plaintiffName.text),
            _ReviewRow('Telefon', _plaintiffPhone.text),
            _ReviewRow('Manzil', _plaintiffAddress.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.person_search_outlined,
          title: 'Javobgar',
          rows: [
            _ReviewRow('F.I.Sh.', _defendantName.text),
            _ReviewRow('Telefon', _defendantPhone.text),
            _ReviewRow('Manzil', _defendantAddress.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.favorite_border_rounded,
          title: 'Nikoh',
          rows: [
            _ReviewRow('FHDYO', _fhdyoName.text),
            _ReviewRow('Sana', _date(_marriageDate)),
            _ReviewRow('Dalolatnoma', _marriageActNumber.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.child_care_rounded,
          title: 'Farzandlar',
          rows: [
            _ReviewRow('Soni', '${childNames.length} nafar'),
            _ReviewRow(
              'Ismlar',
              childNames.isEmpty
                  ? 'Kiritilmagan'
                  : childNames.join(', '),
            ),
          ],
        ),
        _ReviewCard(
          icon: Icons.home_work_outlined,
          title: 'Alohida yashash',
          rows: [
            _ReviewRow('Boshlangan', _date(_livingSpDate)),
          ],
        ),
        const SizedBox(height: 4),
        const _SecurityCard(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(bool last) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bg.withOpacity(0),
            _bg.withOpacity(0.97),
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
                    colors: last
                        ? const [
                            Color(0xFF4D8DFF),
                            Color(0xFF50CFE0),
                          ]
                        : const [
                            Color(0xFF4D8DFF),
                            Color(0xFF6A72FF),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.28),
                      blurRadius: 26,
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
                              last
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
                              last
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

// ============================================================================
// STEP PAGE
// ============================================================================

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
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 22 * (1 - value)),
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
                      colors: [
                        Color(0xFF4D8DFF),
                        Color(0xFF50CFE0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: _ChildLivingPlacePageState._primary
                            .withOpacity(0.28),
                        blurRadius: 25,
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
                          color: _ChildLivingPlacePageState._primary2,
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
              color: _ChildLivingPlacePageState._muted,
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

// ============================================================================
// FIELD
// ============================================================================

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
            cursorColor: _ChildLivingPlacePageState._primary2,
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
                  color: _ChildLivingPlacePageState._primary,
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

// ============================================================================
// DATE
// ============================================================================

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

// ============================================================================
// CHILD CARD
// ============================================================================

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.index,
    required this.data,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final _ChildData data;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
                  color: _ChildLivingPlacePageState._cyan
                      .withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: _ChildLivingPlacePageState._cyan,
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
            hint: 'Familiya, ism, otasining ismi',
            icon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REVIEW
// ============================================================================

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
                color: _ChildLivingPlacePageState._primary2,
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
                    width: 84,
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

// ============================================================================
// INFO CARD
// ============================================================================

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
        color: _ChildLivingPlacePageState._cyan.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ChildLivingPlacePageState._cyan.withOpacity(0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _ChildLivingPlacePageState._cyan,
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

// ============================================================================
// LEGAL CONTEXT CARD
// ============================================================================

class _LegalContextCard extends StatelessWidget {
  const _LegalContextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF163A57),
            Color(0xFF10283D),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF75B7FF).withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D8DFF).withOpacity(0.10),
            blurRadius: 25,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.balance_rounded,
                color: _ChildLivingPlacePageState._primary2,
                size: 21,
              ),
              SizedBox(width: 10),
              Text(
                'Nizo qanday ko‘riladi?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 11),
          Text(
            'Reference loyihadagi maʼlumotga ko‘ra, ota-ona '
            'kelisha olmasa, masala bolaning ustun manfaatlari '
            'asosida ko‘riladi. Unda bolaning yoshi, ota-onaning '
            'shaxsiy fazilatlari va tarbiyalash uchun sharoit '
            'yaratish imkoniyati kabi holatlar hisobga olinishi '
            'ko‘rsatilgan.',
            style: TextStyle(
              color: Color(0xFFA6B9CA),
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECURITY CARD
// ============================================================================

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ChildLivingPlacePageState._green.withOpacity(0.055),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _ChildLivingPlacePageState._green.withOpacity(0.13),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: _ChildLivingPlacePageState._green,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Maʼlumotlar tekshirilgach, ular backendga '
              'yuborish uchun tayyor JSON payload sifatida '
              'shakllantiriladi. Hozircha to‘lov va hujjat '
              'yaratish ulanmagan.',
              style: TextStyle(
                color: Color(0xFF91A8BA),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GLASS BUTTON
// ============================================================================

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

// ============================================================================
// GLOW
// ============================================================================

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

// ============================================================================
// DATA
// ============================================================================

class _FormStep {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ChildData {
  final TextEditingController name = TextEditingController();

  void dispose() {
    name.dispose();
  }
}

class _ReviewRow {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);
}
