import 'package:flutter/material.dart';

/// YAN360 lawyer services: live consultation + court representation.
/// Frontend preview only. Replace preview slots with backend availability.
class AdvokatYollashPage extends StatefulWidget {
  const AdvokatYollashPage({
    super.key,
    this.onSubmit,
    this.availableSlots,
    this.initialRepresentation = false,
    this.lawyerName = "Shohruh Jo'rayev",
    this.lawyerTitle = 'BOSH ADVOKAT · YAN LEGAL FIRM',
    this.biography =
        '"YAN Legal Firm" yuridik kompaniyasi asoschisi, yetakchi mutaxassis. '
        'Toshkent Davlat Yuridik Universitetining faxrli bitiruvchilaridan biri.',
  });

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;
  final bool initialRepresentation;
  /// Example: {'2026-10-12': ['10:00', '10:20']}. Null means preview slots.
  final Map<String, List<String>>? availableSlots;
  final String lawyerName;
  final String lawyerTitle;
  final String biography;

  @override
  State<AdvokatYollashPage> createState() => _AdvokatYollashPageState();
}

enum _Service { consultation, representation }

class _AdvokatYollashPageState extends State<AdvokatYollashPage> {
  static const bg = Color(0xFF071321);
  static const panel = Color(0xFF112238);
  static const cyan = Color(0xFF62D9E8);
  static const blue = Color(0xFF6595FF);
  static const violet = Color(0xFF9B91FF);
  static const ink = Color(0xFFF2F7FC);
  static const muted = Color(0xFFA2B4C8);
  static const line = Color(0x28C5D9EF);

  final _caseController = TextEditingController();
  late _Service _service =
      widget.initialRepresentation ? _Service.representation : _Service.consultation;
  DateTime _day = _dateOnly(DateTime.now());
  String? _time;
  bool _review = false;
  bool _busy = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _caseController.dispose();
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateText(DateTime d) {
    const days = ['DUSH', 'SESH', 'CHOR', 'PAY', 'JUMA', 'SHAN', 'YAK'];
    const months = ['yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _monthText(DateTime d) {
    const months = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];
    return '${months[d.month - 1]} ${d.year}';
  }

  List<DateTime> get _days => List.generate(7, (i) => _dateOnly(DateTime.now()).add(Duration(days: i)));

  List<String> get _slots => widget.availableSlots == null
      ? const ['09:00', '09:20', '09:40', '10:00', '10:20', '10:40', '11:00', '11:20', '11:40', '14:00', '14:20', '14:40', '15:00', '15:20']
      : (widget.availableSlots![_iso(_day)] ?? const <String>[]);

  Map<String, dynamic> get _payload => _service == _Service.consultation
      ? {'type': 'book_consultation', 'date': _iso(_day), 'time': _time, 'duration_minutes': 20, 'timezone': 'Asia/Tashkent'}
      : {'type': 'hire_lawyer', 'case_description': _caseController.text.trim()};

  void _toast(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF263A50)));
  }

  void _switch(_Service s) => setState(() { _service = s; _review = false; });

  void _next() {
    FocusScope.of(context).unfocus();
    if (_service == _Service.consultation && _time == null) {
      _toast('Davom etish uchun vaqtni tanlang.');
      return;
    }
    if (_service == _Service.representation && _caseController.text.trim().length < 30) {
      _toast('Ish holatini kamida 30 ta belgi bilan tushuntiring.');
      return;
    }
    setState(() => _review = true);
  }

  Future<void> _submitPreview() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(_payload);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _Glass(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline_rounded, color: cyan, size: 56),
              const SizedBox(height: 14),
              const Text('Frontend ko‘rinishi tayyor', textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Text(widget.onSubmit == null
                  ? 'Haqiqiy bron, advokatga yuborish yoki to‘lov amalga oshirilmadi. Backend ulangach bu jarayonlar ishlaydi.'
                  : 'So‘rov integratsiyaga topshirildi. Haqiqiy bron yoki to‘lov holatini backend tasdiqlashi kerak.',
                  textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12.5, height: 1.55)),
              const SizedBox(height: 20),
              _ActionButton(label: 'YOPISH', icon: Icons.done_rounded, onTap: () { Navigator.pop(ctx); Navigator.pop(context); }),
            ]),
          ),
        ),
      );
    } catch (_) {
      if (mounted) _toast('Xatolik yuz berdi. Qayta urinib ko‘ring.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: Stack(children: [
      const _Atmosphere(),
      SafeArea(child: Column(children: [
        _header(),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(a), child: child)),
          child: SingleChildScrollView(
            key: ValueKey('${_service.name}-$_review'),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _profile(),
              const SizedBox(height: 21),
              _selector(),
              const SizedBox(height: 22),
              if (_service == _Service.consultation)
                (_review ? _consultationReview() : _consultationForm())
              else
                (_review ? _representationReview() : _representationForm()),
            ]),
          ),
        )),
        _bottomBar(),
      ])),
    ]),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
    child: Row(children: [
      _IconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Advokat yollash', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Yuridik xizmatlar markazi', style: TextStyle(color: muted, fontSize: 11)),
      ])),
      Container(width: 38, height: 38, decoration: BoxDecoration(color: cyan.withValues(alpha: .08), borderRadius: BorderRadius.circular(13), border: Border.all(color: cyan.withValues(alpha: .2))), child: const Icon(Icons.verified_user_outlined, color: cyan, size: 19)),
    ]),
  );

  Widget _profile() => _Glass(
    padding: const EdgeInsets.all(17),
    child: Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 76, height: 76, padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [cyan, blue, violet])),
          child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: panel), child: const Icon(Icons.person_rounded, color: Color(0xFFD8E7F7), size: 40))),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.lawyerName, style: const TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(widget.lawyerTitle, style: const TextStyle(color: cyan, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Row(children: [Icon(Icons.verified_rounded, color: cyan, size: 14), SizedBox(width: 5), Text('Yuridik mutaxassis', style: TextStyle(color: muted, fontSize: 10.5))]),
        ])),
      ]),
      const SizedBox(height: 15),
      Container(height: 1, color: line),
      const SizedBox(height: 13),
      const Row(children: [Icon(Icons.workspace_premium_outlined, color: violet, size: 17), SizedBox(width: 8), Text('Yurist biografiyasi', style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      Text(widget.biography, style: const TextStyle(color: muted, fontSize: 12, height: 1.55)),
    ]),
  );

  Widget _selector() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Eyebrow('XIZMAT TURINI TANLANG'),
    const SizedBox(height: 9),
    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFF0B1A2B), borderRadius: BorderRadius.circular(19), border: Border.all(color: line), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 18, offset: const Offset(0, 7))]),
      child: Row(children: [
        Expanded(child: _Tab(selected: _service == _Service.consultation, icon: Icons.video_camera_front_rounded, title: 'Jonli maslahat', subtitle: '20 daqiqa', accent: cyan, onTap: () => _switch(_Service.consultation))),
        const SizedBox(width: 5),
        Expanded(child: _Tab(selected: _service == _Service.representation, icon: Icons.balance_rounded, title: 'Sud himoyasi', subtitle: 'Advokat yollash', accent: violet, onTap: () => _switch(_Service.representation))),
      ]),
    ),
  ]);

  Widget _consultationForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Heading(eyebrow: 'ONLAYN UCHRASHUV', title: 'Sizga qulay vaqtni tanlang.', description: 'Advokat bilan 20 daqiqalik jonli maslahat uchun kun va vaqtni belgilang.', accent: cyan),
    const SizedBox(height: 17),
    _Glass(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.calendar_month_rounded, color: cyan, size: 19), const SizedBox(width: 8), const Expanded(child: Text('Sana tanlang', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14))), Text(_monthText(_day), style: const TextStyle(color: muted, fontSize: 10))]),
      const SizedBox(height: 13),
      SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _days.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, i) {
        final d = _days[i]; const wd = ['DU', 'SE', 'CH', 'PA', 'JU', 'SH', 'YA'];
        return _DateChip(weekday: wd[d.weekday - 1], day: '${d.day}', selected: _dateOnly(d) == _day, onTap: () => setState(() { _day = d; _time = null; }));
      })),
      const SizedBox(height: 19),
      Row(children: const [Icon(Icons.schedule_rounded, color: cyan, size: 18), SizedBox(width: 8), Expanded(child: Text('Vaqtni tanlang', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14))), Text('Toshkent vaqti', style: TextStyle(color: muted, fontSize: 10))]),
      const SizedBox(height: 11),
      _Notice(text: widget.availableSlots == null ? 'Namuna vaqtlar. Haqiqiy bo‘sh vaqtlar backend ulangach ko‘rsatiladi.' : 'Ko‘rsatilgan vaqtlar integratsiya bergan ro‘yxatdan olindi.'),
      const SizedBox(height: 10),
      if (_slots.isEmpty) const _Notice(text: 'Bu sana uchun bo‘sh vaqt yo‘q. Boshqa kunni tanlang.'),
      if (_slots.isNotEmpty) GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _slots.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 43), itemBuilder: (_, i) => _TimeChip(time: _slots[i], selected: _time == _slots[i], onTap: () => setState(() => _time = _slots[i]))),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: cyan.withValues(alpha: .055), borderRadius: BorderRadius.circular(15), border: Border.all(color: cyan.withValues(alpha: .13))),
        child: const Row(children: [Icon(Icons.timelapse_rounded, color: cyan, size: 20), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('20 daqiqalik maslahat', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Narxi: 99 000 so‘m', style: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.w800))]))])),
    ])),
    const SizedBox(height: 12),
    const _TrustNote(text: 'Vaqtni tanlash hali bron emas. Yakuniy bron backend mavjudlikni tasdiqlagach va to‘lov yakunlangach kuchga kiradi.'),
  ]);

  Widget _consultationReview() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Heading(eyebrow: 'UCHRASHUVNI TEKSHIRISH', title: 'Rejangizni tasdiqlang.', description: 'Tanlangan sana va vaqtni yana bir bor tekshiring.', accent: cyan),
    const SizedBox(height: 17),
    _Glass(padding: const EdgeInsets.all(18), child: Column(children: [
      _ReviewLine(icon: Icons.calendar_month_rounded, label: 'Sana', value: _dateText(_day)),
      const SizedBox(height: 15),
      _ReviewLine(icon: Icons.schedule_rounded, label: 'Toshkent vaqti', value: _time ?? 'Tanlanmagan'),
      const SizedBox(height: 15),
      const _ReviewLine(icon: Icons.timelapse_rounded, label: 'Davomiyligi', value: '20 daqiqa'),
      const SizedBox(height: 15),
      Container(height: 1, color: line),
      const SizedBox(height: 15),
      const _ReviewLine(icon: Icons.payments_outlined, label: 'Ko‘rsatilgan narx', value: '99 000 so‘m', accent: cyan),
    ])),
    const SizedBox(height: 12),
    const _TrustNote(text: 'Frontend sinovi: bu tugma real bron yaratmaydi va to‘lov olmaydi. Backend ulanishi slot mavjudligini qayta tekshirishi kerak.'),
  ]);

  Widget _representationForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Heading(eyebrow: 'SUD ISHI BO‘YICHA HIMOYA', title: 'Ishingiz haqida gapirib bering.', description: 'Advokat vaziyatni o‘rganishi uchun asosiy faktlar, muhim sanalar va siz kutayotgan natijani yozing.', accent: violet),
    const SizedBox(height: 17),
    _Glass(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.description_outlined, color: violet, size: 19), SizedBox(width: 9), Text('Ishning mohiyati', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 7),
      const Text('Faqat ishga tegishli maʼlumotlarni kiriting.', style: TextStyle(color: muted, fontSize: 11.5)),
      const SizedBox(height: 13),
      TextField(controller: _caseController, minLines: 8, maxLines: 14, maxLength: 5000, textCapitalization: TextCapitalization.sentences, cursorColor: violet, style: const TextStyle(color: ink, fontSize: 13, height: 1.6),
        decoration: InputDecoration(hintText: 'Assalomu alaykum. Mening masalam shundan iboratki...\n\nVoqealar ketma-ketligi, sud jarayoni boshlanganmi, mavjud hujjatlar va qanday yordam kutayotganingizni yozing.', hintStyle: const TextStyle(color: Color(0xFF7F92A8), fontSize: 12, height: 1.55), filled: true, fillColor: const Color(0xFF091727), contentPadding: const EdgeInsets.all(15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: line)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: violet, width: 1.25)), counterStyle: const TextStyle(color: muted, fontSize: 10))),
      const SizedBox(height: 4),
      const _TrustNote(text: 'Parol, bank karta PIN-kodi yoki ishga aloqasi bo‘lmagan maxfiy maʼlumotlarni kiritmang.'),
    ])),
    const SizedBox(height: 12),
    _Glass(padding: const EdgeInsets.all(15), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.receipt_long_outlined, color: violet, size: 21), SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Narx ish o‘rganilgach belgilanadi', style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w800)),
        SizedBox(height: 5),
        Text('Advokat ishni ko‘rib chiqadi va shartnoma summasini belgilaydi. To‘lov shartlari keyin taqdim etiladi.', style: TextStyle(color: muted, fontSize: 11.5, height: 1.5)),
      ])),
    ])),
  ]);

  Widget _representationReview() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Heading(eyebrow: 'YAKUNIY TEKSHIRUV', title: 'Murojaatni ko‘rib chiqing.', description: 'Ish bayonini tekshiring yoki tahrirlash uchun orqaga qayting.', accent: violet),
    const SizedBox(height: 17),
    _Glass(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.description_outlined, color: violet, size: 19), SizedBox(width: 9), Text('Ishning mohiyati', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 13),
      SelectableText(_caseController.text.trim(), style: const TextStyle(color: Color(0xFFD4DFEC), fontSize: 12.5, height: 1.65)),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _review = false), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Tahrirlash'), style: TextButton.styleFrom(foregroundColor: violet))),
    ])),
    const SizedBox(height: 12),
    const _TrustNote(text: 'Frontend sinovi: murojaat hozircha advokatga yuborilmaydi. Backend ulangach, mijoz maʼlumotlari va ish bayoni xavfsiz uzatiladi.'),
  ]);

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(18, 11, 18, 15),
    decoration: BoxDecoration(color: bg.withValues(alpha: .97), border: const Border(top: BorderSide(color: line)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, -7))]),
    child: SafeArea(top: false, child: Row(children: [
      if (_review) ...[_IconButton(icon: Icons.arrow_back_rounded, onTap: () => setState(() => _review = false), size: 52), const SizedBox(width: 10)],
      Expanded(child: _ActionButton(
        label: _busy ? 'KUTILMOQDA...' : _review ? (_service == _Service.consultation ? 'UCHRASHUVNI TASDIQLASH' : 'MUROJAATNI TAYYORLASH') : 'DAVOM ETISH',
        icon: _review ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded,
        accent: _service == _Service.consultation ? cyan : violet,
        busy: _busy,
        onTap: _busy ? null : () { if (_review) { _submitPreview(); } else { _next(); } },
      )),
    ])),
  );
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();
  @override
  Widget build(BuildContext context) => IgnorePointer(child: Stack(children: [
    Positioned(top: -130, right: -115, child: _Glow(color: const Color(0xFF4E8FFF).withValues(alpha: .20), size: 340)),
    Positioned(top: 340, left: -180, child: _Glow(color: const Color(0xFF4DD7DB).withValues(alpha: .09), size: 360)),
    Positioned(bottom: -150, right: -110, child: _Glow(color: const Color(0xFF9B91FF).withValues(alpha: .11), size: 310)),
  ]));
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF1B3047).withValues(alpha: .91), const Color(0xFF101F32).withValues(alpha: .97), const Color(0xFF0C1A2A).withValues(alpha: .96)]),
      border: Border.all(color: Colors.white.withValues(alpha: .105)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .17), blurRadius: 25, offset: const Offset(0, 12)), BoxShadow(color: const Color(0xFF9BD8FF).withValues(alpha: .025), blurRadius: 1, spreadRadius: 1)],
    ),
    child: child,
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.size = 44});
  final IconData icon; final VoidCallback onTap; final double size;
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(height: size, width: size, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: .10))), child: Icon(icon, color: const Color(0xFFD7E6F5), size: 20))));
}

class _Tab extends StatelessWidget {
  const _Tab({required this.selected, required this.icon, required this.title, required this.subtitle, required this.accent, required this.onTap});
  final bool selected; final IconData icon; final String title; final String subtitle; final Color accent; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(milliseconds: 220), decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(15),
    gradient: selected ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: .20), accent.withValues(alpha: .075)]) : null,
    border: Border.all(color: selected ? accent.withValues(alpha: .36) : Colors.transparent),
    boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: .07), blurRadius: 14)] : const [],
  ), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13), child: Row(children: [
    Icon(icon, color: selected ? accent : const Color(0xFF8195AB), size: 21), const SizedBox(width: 7),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? _AdvokatYollashPageState.ink : const Color(0xFFB3C1D1), fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? accent : const Color(0xFF8294A8), fontSize: 9)),
    ])),
  ])))));
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.weekday, required this.day, required this.selected, required this.onTap});
  final String weekday; final String day; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(width: 57, decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: selected ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A7E9B), Color(0xFF254D75)]) : LinearGradient(colors: [Colors.white.withValues(alpha: .055), Colors.white.withValues(alpha: .025)]),
    border: Border.all(color: selected ? _AdvokatYollashPageState.cyan.withValues(alpha: .72) : _AdvokatYollashPageState.line),
    boxShadow: selected ? [BoxShadow(color: _AdvokatYollashPageState.cyan.withValues(alpha: .11), blurRadius: 16)] : const [],
  ), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(weekday, style: TextStyle(color: selected ? Colors.white : _AdvokatYollashPageState.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .6)),
    const SizedBox(height: 7),
    Text(day, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
    if (selected) ...[const SizedBox(height: 4), Container(width: 12, height: 3, decoration: BoxDecoration(color: _AdvokatYollashPageState.cyan, borderRadius: BorderRadius.circular(5)))],
  ]))));
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.selected, required this.onTap});
  final String time; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: selected ? _AdvokatYollashPageState.cyan.withValues(alpha: .13) : Colors.white.withValues(alpha: .035), border: Border.all(color: selected ? _AdvokatYollashPageState.cyan.withValues(alpha: .65) : _AdvokatYollashPageState.line)), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    if (selected) ...[const Icon(Icons.check_rounded, color: _AdvokatYollashPageState.cyan, size: 14), const SizedBox(width: 4)],
    Text(time, style: TextStyle(color: selected ? _AdvokatYollashPageState.cyan : const Color(0xFFDCE6F2), fontSize: 12, fontWeight: FontWeight.w800)),
  ])))));
}

class _Heading extends StatelessWidget {
  const _Heading({required this.eyebrow, required this.title, required this.description, required this.accent});
  final String eyebrow; final String title; final String description; final Color accent;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 5, height: 18, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 9), Text(eyebrow, style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.3))]),
    const SizedBox(height: 10),
    Text(title, style: const TextStyle(color: _AdvokatYollashPageState.ink, fontSize: 25, height: 1.16, fontWeight: FontWeight.w900, letterSpacing: -.55)),
    const SizedBox(height: 9),
    Text(description, style: const TextStyle(color: _AdvokatYollashPageState.muted, fontSize: 12.5, height: 1.55)),
  ]);
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text); final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _AdvokatYollashPageState.muted, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.45));
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text}); final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF8B9CB2).withValues(alpha: .065), borderRadius: BorderRadius.circular(12), border: Border.all(color: _AdvokatYollashPageState.line)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.info_outline_rounded, color: _AdvokatYollashPageState.muted, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: _AdvokatYollashPageState.muted, fontSize: 10.5, height: 1.45))),
  ]));
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.text}); final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.shield_outlined, color: _AdvokatYollashPageState.cyan, size: 16), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: _AdvokatYollashPageState.muted, fontSize: 10.5, height: 1.5))),
  ]));
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.icon, required this.label, required this.value, this.accent = _AdvokatYollashPageState.ink});
  final IconData icon; final String label; final String value; final Color accent;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 37, height: 37, decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent, size: 18)),
    const SizedBox(width: 11), Expanded(child: Text(label, style: const TextStyle(color: _AdvokatYollashPageState.muted, fontSize: 12))),
    const SizedBox(width: 10), Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800))),
  ]);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.accent = _AdvokatYollashPageState.cyan, this.busy = false});
  final String label; final IconData icon; final VoidCallback? onTap; final Color accent; final bool busy;
  @override
  Widget build(BuildContext context) => Container(height: 54, decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(17),
    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: .96), Color.lerp(accent, const Color(0xFF5279DF), .35)!]),
    border: Border.all(color: Colors.white.withValues(alpha: .24)),
    boxShadow: [BoxShadow(color: accent.withValues(alpha: .17), blurRadius: 20, offset: const Offset(0, 7)), BoxShadow(color: Colors.white.withValues(alpha: .07), blurRadius: 1, offset: const Offset(0, 1))],
  ), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Center(child: busy
    ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF061625)))
    : Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF061625), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .45))),
      const SizedBox(width: 8), Icon(icon, color: const Color(0xFF061625), size: 19),
    ]))))));
}
