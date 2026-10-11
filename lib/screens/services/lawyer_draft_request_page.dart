import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LawyerDraftRequestPage extends StatefulWidget {
  const LawyerDraftRequestPage({super.key, this.onSubmit});

  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<LawyerDraftRequestPage> createState() =>
      _LawyerDraftRequestPageState();
}

const _bg = Color(0xFF071927);
const _panel = Color(0xFF10283B);
const _blue = Color(0xFF4D8DFF);
const _mint = Color(0xFF67D6BD);
const _gold = Color(0xFFE5BE78);
const _muted = Color(0xFFA5B7C7);

class _Category {
  const _Category(
    this.id,
    this.title,
    this.description,
    this.price,
    this.icon,
    this.accent,
  );

  final String id;
  final String title;
  final String description;
  final int price;
  final IconData icon;
  final Color accent;
}

const _categories = <_Category>[
  _Category(
    'oilaviy',
    'Oilaviy masalalar',
    'Nikoh, aliment, farzandlar va oilaviy nizolar',
    149000,
    Icons.family_restroom_rounded,
    Color(0xFFFFB5C8),
  ),
  _Category(
    'mehnat',
    'Mehnat munosabatlari',
    'Ish haqi, mehnat shartnomasi va ish joyidagi nizolar',
    199000,
    Icons.work_outline_rounded,
    Color(0xFF8EC7FF),
  ),
  _Category(
    'uyjoy',
    'Uy-joy munosabatlari',
    'Uy-joy, ijara va foydalanish bilan bog‘liq masalalar',
    199000,
    Icons.home_work_outlined,
    Color(0xFFFFD18B),
  ),
  _Category(
    'fuqarolik',
    'Fuqarolik munosabatlari',
    'Shartnomalar, qarzlar va boshqa fuqarolik nizolari',
    199000,
    Icons.account_balance_outlined,
    Color(0xFFBDAAFF),
  ),
];

class _LawyerDraftRequestPageState
    extends State<LawyerDraftRequestPage> {
  final _problem = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _files = [];

  _Category? _category;
  int _step = 0;
  bool _busy = false;

  @override
  void dispose() {
    _problem.dispose();
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A2935),
        ),
      );
  }

  void _next() {
    if (_step == 0 && _category == null) {
      _error('Avval huquqiy yo‘nalishni tanlang.');
      return;
    }

    if (_step == 1 && _problem.text.trim().length < 20) {
      _error('Vaziyatni kamida 20 ta belgi bilan batafsil yozing.');
      return;
    }

    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final List<XFile> picked;

      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(imageQuality: 82);
      } else {
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 82,
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
      _error('Rasmni ochib bo‘lmadi. Qayta urinib ko‘ring.');
    }
  }

  void _attachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hujjat qo‘shish',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.photo_library_outlined,
                title: 'Galereyadan tanlash',
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
              _MenuTile(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera bilan suratga olish',
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> buildPayload() {
    return {
      'type': 'lawyer_draft_request',
      'category_id': _category!.id,
      'category_title': _category!.title,
      'starting_price_uzs': _category!.price,
      'problem_type': 'text',
      'problem_content': _problem.text.trim(),
      'attachments': _files
          .map(
            (file) => {
              'name': file.name,
              'local_path': file.path,
            },
          )
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
        // Frontend preview only. Connect the backend later.
        await Future<void>.delayed(
          const Duration(milliseconds: 650),
        );
      }

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
          decoration: const BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _mint,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Murojaat tayyorlandi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Maʼlumotlar frontendda tayyorlandi. '
                  'Yuristga haqiqiy yuborish va to‘lov '
                  'backend ulangandan keyin ishlaydi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('TAYYOR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _error('Murojaatni tayyorlashda xatolik yuz berdi.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Yo‘nalishni tanlang',
      'Vaziyatni tushuntiring',
      'Hujjatlarni qo‘shing',
      'Murojaatni tekshiring',
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 20, 12),
                  child: Row(
                    children: [
                      const _BackButton(),
                      const SizedBox(width: 12),
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advokatga ariza yozdirish',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Professional yuridik yordam',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'QADAM ${_step + 1} / 4',
                            style: const TextStyle(
                              color: _mint,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_step + 1) * 25}%',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / 4,
                          minHeight: 4,
                          backgroundColor: Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation(_mint),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.025, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        2,
                        20,
                        24,
                      ),
                      child: _stepBody(labels[_step]),
                    ),
                  ),
                ),
                const _BottomSpace(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Row(
            children: [
              if (_step > 0) ...[
                SizedBox(
                  width: 50,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _back,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                _step == 3
                                    ? 'MUROJAATNI TAYYORLASH'
                                    : 'DAVOM ETISH',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .4,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Icon(
                                _step == 3
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(String label) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('SIZGA QANDAY YORDAM KERAK?'),
            const SizedBox(height: 9),
            const Text(
              'Masalangiz qaysi\nyo‘nalishga tegishli?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Yo‘nalishni tanlang. Murojaatingiz professional '
              'yuristga ko‘rib chiqish uchun tayyorlanadi.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ..._categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _CategoryCard(
                  category: category,
                  selected: _category?.id == category.id,
                  onTap: () => setState(
                    () => _category = category,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const _Note(
              text: 'Boshlang‘ich narxlar. Yakuniy xizmat narxi '
                  'yurist murojaatni ko‘rib chiqqach aniqlanadi.',
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('VAZIYAT BAYONI'),
            const SizedBox(height: 9),
            const Text(
              'Nima sodir\nbo‘lganini ayting.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 29,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Muhim sanalar, ishtirokchilar va nimaga '
              'erishmoqchi ekanligingizni yozing. Hozircha '
              'bilmagan maʼlumotlarni taxmin qilib kiritishingiz '
              'shart emas.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D2233),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .10),
                ),
              ),
              child: TextField(
                controller: _problem,
                minLines: 8,
                maxLines: 14,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                ),
                cursorColor: _mint,
                decoration: const InputDecoration(
                  hintText:
                      'Masalan: Muammo qachon boshlandi, '
                      'kimlar ishtirok etgan, qanday hujjatlar '
                      'bor va qanday yechim kutyapsiz...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6F879A),
                    height: 1.5,
                  ),
                  contentPadding: EdgeInsets.all(18),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _TipRow(
              icon: Icons.lightbulb_outline_rounded,
              text: 'Aniq va xolis yozing. Parol yoki bank karta '
                  'PIN-kodi kabi maxfiy maʼlumotlarni kiritmang.',
            ),
            const SizedBox(height: 14),
            _SelectedCategory(category: _category!),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('DALILLAR VA HUJJATLAR'),
            const SizedBox(height: 9),
            const Text(
              'Hujjatlaringizni\ntartib bilan qo‘shing.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pasport, shartnoma, yozishmalar yoki ishga '
              'tegishli hujjatlarning rasmlarini qo‘shishingiz '
              'mumkin. Hujjat bo‘lmasa, o‘tkazib yuboring.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            InkWell(
              onTap: _attachmentMenu,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 27,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _blue.withValues(alpha: .45),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _blue,
                      size: 34,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Hujjat qo‘shish',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Galereya yoki kamera · 10 tagacha rasm',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'QO‘SHILGAN HUJJATLAR  ${_files.length}/10',
                style: const TextStyle(
                  color: _mint,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(
                _files.length,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .045),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          File(_files[index].path),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.description_outlined,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _files[index].name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _files.removeAt(index));
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const _Note(
              text: 'Tanlangan rasmlar hozircha qurilmada qoladi. '
                  'Ularni yuristga uzatish backend integratsiyasidan '
                  'keyin ulanadi.',
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('YUBORISHDAN OLDIN'),
            const SizedBox(height: 9),
            const Text(
              'Murojaatingizni\ntekshirib chiqing.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 20),
            _ReviewCard(
              title: 'Huquqiy yo‘nalish',
              icon: _category!.icon,
              onEdit: () => setState(() => _step = 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _category!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _category!.description,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Boshlang‘ich narx: '
                    '${_money(_category!.price)} so‘m',
                    style: const TextStyle(
                      color: _mint,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            _ReviewCard(
              title: 'Vaziyat bayoni',
              icon: Icons.notes_rounded,
              onEdit: () => setState(() => _step = 1),
              child: Text(
                _problem.text.trim(),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 11),
            _ReviewCard(
              title: 'Hujjatlar',
              icon: Icons.attach_file_rounded,
              onEdit: () => setState(() => _step = 2),
              child: Text(
                _files.isEmpty
                    ? 'Hujjat qo‘shilmagan'
                    : '${_files.length} ta rasm tanlangan',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _Note(
              text: 'Hozircha hech qanday to‘lov yoki haqiqiy '
                  'yuborish amalga oshmaydi. Backend ulangach, '
                  'murojaat yuristga uzatiladi.',
            ),
          ],
        );
    }
  }
}

String _money(int amount) {
  final digits = amount.toString();
  final result = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    result.write(digits[i]);

    if (digits.length - i > 1 &&
        (digits.length - i - 1) % 3 == 0) {
      result.write(' ');
    }
  }

  return result.toString();
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected
                ? category.accent.withValues(alpha: .09)
                : _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? category.accent.withValues(alpha: .7)
                  : Colors.white.withValues(alpha: .075),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: category.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: category.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_money(category.price)} so‘mdan',
                      style: TextStyle(
                        color: category.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? category.accent : Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCategory extends StatelessWidget {
  const _SelectedCategory({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: category.accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: category.accent.withValues(alpha: .2),
        ),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: category.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: _mint,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _mint, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Tahrirlash'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: _mint,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _mint,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _gold, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white70,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: _mint),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white38,
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _blue.withValues(alpha: .16),
                    _blue.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -150,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _mint.withValues(alpha: .08),
                    _mint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSpace extends StatelessWidget {
  const _BottomSpace();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 1);
  }
}