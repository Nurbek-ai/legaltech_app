import 'package:flutter/material.dart';

/// ===============================================================
/// NIKОHDAN AJRASHISH
/// ===============================================================
/// Project-2 reference contract:
///
/// type: nikoh_ajrashish
/// generator: DivorceClaimGenerator
/// template: nikohdan_ajrashish.docx
/// price: 9,990,000 UZS
///
/// The fields below are limited to the data actually consumed by the
/// reference project's divorce template/generator:
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
///
/// Payment, API transport and DOCX generation remain outside this page.
/// The page exposes a backend-ready payload through onSubmit.
/// ===============================================================

class DivorceClaimPage extends StatefulWidget {
  const DivorceClaimPage({
    super.key,
    this.onSubmit,
  });

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<DivorceClaimPage> createState() => _DivorceClaimPageState();
}

const _divorceBg = Color(0xFF061827);
const _divorcePrimary = Color(0xFF4D8DFF);
const _divorceCyan = Color(0xFF61DDEB);
const _divorceGreen = Color(0xFF69D8B1);
const _divorceMuted = Color(0xFF9DB1C4);

class _DivorceClaimPageState extends State<DivorceClaimPage> {

  static const _steps = <_StepInfo>[
    _StepInfo(
      '01',
      'Daʼvogar',
      'Siz haqingizda',
      Icons.person_outline_rounded,
    ),
    _StepInfo(
      '02',
      'Javobgar',
      'Turmush o‘rtog‘ingiz',
      Icons.person_search_outlined,
    ),
    _StepInfo(
      '03',
      'Nikoh',
      'FHDYO maʼlumotlari',
      Icons.favorite_border_rounded,
    ),
    _StepInfo(
      '04',
      'Farzandlar',
      'Birgalikdagi farzandlar',
      Icons.child_care_rounded,
    ),
    _StepInfo(
      '05',
      'Alohida yashash',
      'Oilaviy munosabatlar',
      Icons.home_work_outlined,
    ),
    _StepInfo(
      '06',
      'Tekshirish',
      'Arizani yakunlash',
      Icons.fact_check_outlined,
    ),
  ];

  final _pageController = PageController();

  int _step = 0;
  bool _busy = false;

  final _court = TextEditingController();

  final _plaintiffName = TextEditingController();
  final _plaintiffAddress = TextEditingController();
  final _plaintiffPhone = TextEditingController();

  final _defendantName = TextEditingController();
  final _defendantAddress = TextEditingController();
  final _defendantPhone = TextEditingController();

  final _fhdyo = TextEditingController();
  final _actNumber = TextEditingController();

  DateTime? _marriageDate;
  DateTime? _livingApartDate;

  final List<_Child> _children = [_Child()];

  @override
  void dispose() {
    _pageController.dispose();

    _court.dispose();

    _plaintiffName.dispose();
    _plaintiffAddress.dispose();
    _plaintiffPhone.dispose();

    _defendantName.dispose();
    _defendantAddress.dispose();
    _defendantPhone.dispose();

    _fhdyo.dispose();
    _actNumber.dispose();

    for (final child in _children) {
      child.dispose();
    }

    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Sanani tanlang';
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();

    final value = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 5),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _divorcePrimary,
              onPrimary: Colors.white,
              surface: Color(0xFF10283D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (value != null) {
      onPicked(value);
    }
  }

  bool _required(
    TextEditingController controller,
    String message,
  ) {
    if (controller.text.trim().isEmpty) {
      _error(message);
      return false;
    }
    return true;
  }

  bool _validate() {
    switch (_step) {
      case 0:
        return _required(_court, 'Sud nomini kiriting.') &&
            _required(
              _plaintiffName,
              'Daʼvogarning to‘liq ismini kiriting.',
            ) &&
            _required(
              _plaintiffAddress,
              'Daʼvogarning manzilini kiriting.',
            ) &&
            _required(
              _plaintiffPhone,
              'Daʼvogarning telefon raqamini kiriting.',
            );

      case 1:
        return _required(
              _defendantName,
              'Javobgarning to‘liq ismini kiriting.',
            ) &&
            _required(
              _defendantAddress,
              'Javobgarning manzilini kiriting.',
            ) &&
            _required(
              _defendantPhone,
              'Javobgarning telefon raqamini kiriting.',
            );

      case 2:
        if (_fhdyo.text.trim().isEmpty) {
          _error('Nikoh qayd etilgan FHDYO maʼlumotini kiriting.');
          return false;
        }
        if (_marriageDate == null) {
          _error('Nikoh sanasini tanlang.');
          return false;
        }
        if (_actNumber.text.trim().isEmpty) {
          _error('Nikoh dalolatnomasi raqamini kiriting.');
          return false;
        }
        return true;

      case 3:
        if (_children.isEmpty) {
          _error('Kamida bitta farzand kiriting.');
          return false;
        }
        for (final child in _children) {
          if (child.name.text.trim().isEmpty) {
            _error(
              'Har bir farzandning to‘liq ismini kiriting.',
            );
            return false;
          }
        }
        return true;

      case 4:
        if (_livingApartDate == null) {
          _error(
            'Oilaviy munosabatlar to‘xtagan sanani tanlang.',
          );
          return false;
        }
        return true;

      case 5:
        return true;

      default:
        return true;
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          backgroundColor: const Color(0xFF3A2030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF91A8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _next() async {
    if (!_validate()) return;

    if (_step < _steps.length - 1) {
      await _go(_step + 1);
      return;
    }

    await _submit();
  }

  Future<void> _back() async {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }

    await _go(_step - 1);
  }

  Future<void> _go(int value) async {
    setState(() => _step = value);

    await _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _addChild() {
    if (_children.length >= 10) {
      _error('10 nafargacha farzand qo‘shish mumkin.');
      return;
    }

    setState(() {
      _children.add(_Child());
    });
  }

  void _removeChild(int index) {
    if (_children.length == 1) {
      _error('Kamida bitta farzand bo‘lishi kerak.');
      return;
    }

    final child = _children.removeAt(index);
    child.dispose();

    setState(() {});
  }

  /// Exact reference-project service identifier + template fields.
  Map<String, dynamic> buildPayload() {
    final names = _children
        .map((e) => e.name.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return {
      'type': 'nikoh_ajrashish',

      'court_name': _court.text.trim(),

      'plaintiff_name': _plaintiffName.text.trim(),
      'plaintiff_address': _plaintiffAddress.text.trim(),
      'plaintiff_phone': _plaintiffPhone.text.trim(),

      'defendant_name': _defendantName.text.trim(),
      'defendant_address': _defendantAddress.text.trim(),
      'defendant_phone': _defendantPhone.text.trim(),

      'fhdyo_name': _fhdyo.text.trim(),
      'marriage_date': _formatDate(_marriageDate),
      'marriage_act_number': _actNumber.text.trim(),

      'children_count': names.length,
      'children_benefit_list': names.join(', '),
      'child_s': names.length == 1
          ? 'farzand'
          : 'farzandlar',

      'living_sp_date': _formatDate(_livingApartDate),
      'date': _formatDate(DateTime.now()),

      // Extra structured representation for the future API.
      // The DOCX generator itself uses the fields above.
      'children': names
          .map((name) => {'full_name': name})
          .toList(),
    };
  }

  Future<void> _submit() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final payload = buildPayload();

      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      } else {
        // Frontend-only mode.
        // Replace with API call when the backend is connected.
        await Future<void>.delayed(
          const Duration(milliseconds: 1200),
        );
      }

      if (!mounted) return;
      _showCompleteSheet();
    } catch (_) {
      if (mounted) {
        _error(
          'Maʼlumotlarni yuborishda xatolik yuz berdi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showCompleteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            34,
          ),
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
              const SizedBox(height: 26),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_divorcePrimary, _divorceCyan],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _divorcePrimary.withOpacity(0.34),
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
              const SizedBox(height: 21),
              const Text(
                'Ariza maʼlumotlari tayyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Nikohdan ajrashish arizasi uchun kerakli '
                'maʼlumotlar yig‘ildi. Backend ulanganidan '
                'so‘ng shu payload asosida hujjat yaratiladi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _divorceMuted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  label: const Text('TAYYOR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _divorcePrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _steps.length;
    final last = _step == _steps.length - 1;

    return Scaffold(
      backgroundColor: _divorceBg,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _progress(progress),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      _plaintiffStep(),
                      _defendantStep(),
                      _marriageStep(),
                      _childrenStep(),
                      _livingApartStep(),
                      _reviewStep(),
                    ],
                  ),
                ),
                _bottomBar(last),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final current = _steps[_step];

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nikohdan ajrashish',
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
                  current.subtitle,
                  style: const TextStyle(
                    color: _divorceMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
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
              '${_step + 1}/${_steps.length}',
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

  Widget _progress(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation(_divorcePrimary),
            );
          },
        ),
      ),
    );
  }

  Widget _plaintiffStep() {
    return _Step(
      icon: Icons.person_outline_rounded,
      eyebrow: 'DAʼVOGAR',
      title: 'Siz haqingizda',
      description:
          'Nikohdan ajrashish arizasini topshiruvchi '
          'shaxsning maʼlumotlarini kiriting.',
      children: [
        _Field(
          controller: _court,
          label: 'Sud nomi',
          hint: 'Masalan: Chilonzor tumanlararo sudi',
          icon: Icons.account_balance_outlined,
          capitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _plaintiffName,
          label: 'To‘liq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          capitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _plaintiffAddress,
          label: 'Yashash manzili',
          hint: 'Viloyat, tuman, MFY, ko‘cha, uy...',
          icon: Icons.home_outlined,
          maxLines: 2,
          capitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _plaintiffPhone,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _defendantStep() {
    return _Step(
      icon: Icons.person_search_outlined,
      eyebrow: 'JAVOBGAR',
      title: 'Turmush o‘rtog‘ingiz',
      description:
          'Javobgarning arizada ko‘rsatiladigan '
          'asosiy maʼlumotlarini kiriting.',
      children: [
        _Field(
          controller: _defendantName,
          label: 'To‘liq ism',
          hint: 'Familiya, ism, otasining ismi',
          icon: Icons.badge_outlined,
          capitalization: TextCapitalization.words,
        ),
        _Field(
          controller: _defendantAddress,
          label: 'Yashash manzili',
          hint: 'Maʼlum bo‘lgan manzil',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          capitalization: TextCapitalization.sentences,
        ),
        _Field(
          controller: _defendantPhone,
          label: 'Telefon raqami',
          hint: '+998 90 123 45 67',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Javobgar maʼlumotlari',
          text:
              'Reference hujjatda javobgarning F.I.Sh., '
              'manzili va telefon raqami alohida ko‘rsatiladi.',
        ),
      ],
    );
  }

  Widget _marriageStep() {
    return _Step(
      icon: Icons.favorite_border_rounded,
      eyebrow: 'NIKOH',
      title: 'Nikoh maʼlumotlari',
      description:
          'Nikoh qayerda va qachon qayd etilgani hamda '
          'dalolatnoma raqamini kiriting.',
      children: [
        _Field(
          controller: _fhdyo,
          label: 'Nikoh qayd etilgan FHDYO',
          hint: 'Masalan: Muborak tumani',
          icon: Icons.apartment_outlined,
          capitalization: TextCapitalization.sentences,
        ),
        _DateField(
          label: 'Nikoh sanasi',
          value: _formatDate(_marriageDate),
          icon: Icons.calendar_month_outlined,
          onTap: () => _pickDate(
            current: _marriageDate,
            onPicked: (date) {
              setState(() => _marriageDate = date);
            },
          ),
        ),
        _Field(
          controller: _actNumber,
          label: 'Nikoh dalolatnomasi raqami',
          hint: 'Masalan: 125',
          icon: Icons.description_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _childrenStep() {
    return _Step(
      icon: Icons.child_care_rounded,
      eyebrow: 'FARZANDLAR',
      title: 'Birgalikdagi farzandlar',
      description:
          'Reference ajrashish arizasida birgalikdagi '
          'farzandlar soni va ismlari ko‘rsatiladi.',
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Column(
            children: List.generate(
              _children.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChildCard(
                  index: index,
                  child: _children[index],
                  canRemove: _children.length > 1,
                  onRemove: () => _removeChild(index),
                ),
              ),
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
              color: _divorcePrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _divorcePrimary.withOpacity(0.34),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF75B7FF),
                ),
                SizedBox(width: 9),
                Text(
                  'Yana farzand qo‘shish',
                  style: TextStyle(
                    color: Color(0xFF75B7FF),
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
          title: 'Farzandlar ro‘yxati',
          text:
              'Har bir farzand alohida kiritiladi. Yakuniy '
              'payloadda soni va ismlari reference template '
              'talab qilgan ko‘rinishda beriladi.',
        ),
      ],
    );
  }

  Widget _livingApartStep() {
    return _Step(
      icon: Icons.home_work_outlined,
      eyebrow: 'OILAVIY MUNOSABATLAR',
      title: 'Alohida yashash',
      description:
          'Reference ariza oilaviy munosabatlar qachondan '
          'to‘xtaganini alohida ko‘rsatadi.',
      children: [
        _DateField(
          label: 'Oilaviy munosabatlar to‘xtagan sana',
          value: _formatDate(_livingApartDate),
          icon: Icons.event_outlined,
          onTap: () => _pickDate(
            current: _livingApartDate,
            onPicked: (date) {
              setState(() => _livingApartDate = date);
            },
          ),
        ),
        const _LegalContext(
          title: 'Reference arizada nima asoslanadi?',
          body:
              'Shablonda o‘zaro kelishmovchiliklar, birga '
              'yashamaslik, umumiy ro‘zg‘or va byudjet yo‘qligi '
              'hamda oilani tiklashning imkoni bo‘lmagani '
              'haqidagi asoslantirish berilgan. Bu sahifa '
              'shu shablon uchun kerakli sanani yig‘adi.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.description_outlined,
          title: 'Hujjat tarkibi',
          text:
              'Reference template Oila kodeksining 38, 40, '
              '41 va 46-moddalari hamda Fuqarolik protsessual '
              'kodeksining 33, 34, 188, 189 va 191-moddalarini '
              'tilga oladi.',
        ),
      ],
    );
  }

  Widget _reviewStep() {
    final names = _children
        .map((e) => e.name.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _Step(
      icon: Icons.fact_check_outlined,
      eyebrow: 'YAKUNIY TEKSHIRUV',
      title: 'Hammasini tekshiring',
      description:
          'Maʼlumotlar to‘g‘ri bo‘lsa, ariza payloadini '
          'tayyorlashni yakunlang.',
      children: [
        _ReviewCard(
          icon: Icons.account_balance_outlined,
          title: 'Sud',
          rows: [
            _Row('Sud', _court.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.person_outline_rounded,
          title: 'Daʼvogar',
          rows: [
            _Row('F.I.Sh.', _plaintiffName.text),
            _Row('Manzil', _plaintiffAddress.text),
            _Row('Telefon', _plaintiffPhone.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.person_search_outlined,
          title: 'Javobgar',
          rows: [
            _Row('F.I.Sh.', _defendantName.text),
            _Row('Manzil', _defendantAddress.text),
            _Row('Telefon', _defendantPhone.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.favorite_border_rounded,
          title: 'Nikoh',
          rows: [
            _Row('FHDYO', _fhdyo.text),
            _Row('Nikoh sanasi', _formatDate(_marriageDate)),
            _Row('Dalolatnoma', _actNumber.text),
          ],
        ),
        _ReviewCard(
          icon: Icons.child_care_rounded,
          title: 'Farzandlar',
          rows: [
            _Row('Soni', '${names.length} nafar'),
            _Row(
              'Ismlar',
              names.isEmpty
                  ? 'Kiritilmagan'
                  : names.join(', '),
            ),
          ],
        ),
        _ReviewCard(
          icon: Icons.home_work_outlined,
          title: 'Alohida yashash',
          rows: [
            _Row(
              'Sana',
              _formatDate(_livingApartDate),
            ),
          ],
        ),
        const _SecurityCard(),
      ],
    );
  }

  Widget _bottomBar(bool last) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _divorceBg.withOpacity(0),
            _divorceBg.withOpacity(0.97),
            _divorceBg,
          ],
        ),
      ),
      child: Row(
        children: [
          if (_step > 0)
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
              onTap: _busy ? null : _next,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: last
                        ? const [_divorcePrimary, _divorceCyan]
                        : const [
                            _divorcePrimary,
                            Color(0xFF6A72FF),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: [
                    BoxShadow(
                      color: _divorcePrimary.withOpacity(0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              last
                                  ? 'ARIZANI TAYYORLASH'
                                  : 'DAVOM ETISH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
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
// STEP
// ============================================================================

class _Step extends StatelessWidget {
  const _Step({
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_divorcePrimary, _divorceCyan],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: _divorcePrimary.withOpacity(0.28),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xFF75B7FF),
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
              color: _divorceMuted,
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
    this.capitalization =
        TextCapitalization.none,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: 7,
            ),
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
            textCapitalization: capitalization,
            cursorColor: const Color(0xFF75B7FF),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: _divorcePrimary,
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
    final selected = value != 'Sanani tanlang';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: 7,
            ),
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
                        color: selected
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
// CHILD
// ============================================================================

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.index,
    required this.child,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _Child child;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        5,
      ),
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
                  color: _divorceCyan.withOpacity(0.13),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: _divorceCyan,
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
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
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
            controller: child.name,
            label: 'To‘liq ism',
            hint: 'Familiya, ism, otasining ismi',
            icon: Icons.badge_outlined,
            capitalization:
                TextCapitalization.words,
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
  final List<_Row> rows;

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
                color: const Color(0xFF75B7FF),
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
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
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

// ============================================================================
// INFO
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
        color: _divorceCyan.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _divorceCyan.withOpacity(0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _divorceCyan,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
// LEGAL CONTEXT
// ============================================================================

class _LegalContext extends StatelessWidget {
  const _LegalContext({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF163A57),
            Color(0xFF10283D),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF75B7FF)
              .withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.balance_rounded,
                color: Color(0xFF75B7FF),
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            body,
            style: const TextStyle(
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
// SECURITY
// ============================================================================

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _divorceGreen.withOpacity(0.055),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _divorceGreen.withOpacity(0.13),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: _divorceGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Maʼlumotlar tekshirilgach, ular '
              'nikoh_ajrashish service type bilan '
              'backendga yuborishga tayyor payloadga '
              'aylantiriladi. Hozircha to‘lov va DOCX '
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
// BACKGROUND
// ============================================================================

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -110,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _divorcePrimary.withOpacity(0.13),
                  blurRadius: 180,
                  spreadRadius: 15,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 330,
          left: -120,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _divorceCyan.withOpacity(0.10),
                  blurRadius: 150,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DATA
// ============================================================================

class _StepInfo {
  const _StepInfo(
    this.number,
    this.title,
    this.subtitle,
    this.icon,
  );

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _Child {
  final name = TextEditingController();

  void dispose() => name.dispose();
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String value;
}
