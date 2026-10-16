import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/alimony_location_catalog.dart';
import '../../services/family_claim_document_service.dart';

class FamilyClaimPage extends StatefulWidget {
  const FamilyClaimPage({super.key, required this.type});

  final FamilyClaimType type;

  @override
  State<FamilyClaimPage> createState() => _FamilyClaimPageState();
}

class _FamilyClaimPageState extends State<FamilyClaimPage> {
  final _formKey = GlobalKey<FormState>();
  final _plaintiffName = TextEditingController();
  final _plaintiffStreet = TextEditingController();
  final _plaintiffPhone = TextEditingController();
  final _defendantName = TextEditingController();
  final _defendantStreet = TextEditingController();
  final _defendantPhone = TextEditingController();
  final _actNumber = TextEditingController();
  final _amount = TextEditingController();
  final _children = <_ChildData>[_ChildData()];

  String? _plaintiffRegion;
  String? _plaintiffDistrict;
  String? _defendantRegion;
  String? _defendantDistrict;
  String? _fhdyoRegion;
  String? _fhdyoDistrict;
  DateTime? _marriageDate;
  DateTime? _livingApartDate;
  String _reason = 'o‘zaro kelishmovchiliklar';
  String _startDay = 'Shanba';
  String _endDay = 'Yakshanba';
  String _startTime = '09:00';
  String _endTime = '18:00';
  bool _submitting = false;

  bool get _isMother => widget.type == FamilyClaimType.motherSupport;
  bool get _isResidence => widget.type == FamilyClaimType.childResidence;
  bool get _isVisitation => widget.type == FamilyClaimType.childVisitation;
  bool get _isDivorce => widget.type == FamilyClaimType.divorce;

  String get _title => switch (widget.type) {
        FamilyClaimType.motherSupport => 'Ona ta’minoti uchun aliment',
        FamilyClaimType.childResidence => 'Bolaning yashash joyi',
        FamilyClaimType.childVisitation => 'Bola bilan ko‘rishish',
        FamilyClaimType.divorce => 'Nikohdan ajrashish',
      };

  @override
  void dispose() {
    for (final controller in [
      _plaintiffName,
      _plaintiffStreet,
      _plaintiffPhone,
      _defendantName,
      _defendantStreet,
      _defendantPhone,
      _actNumber,
      _amount,
    ]) {
      controller.dispose();
    }
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool marriage}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: marriage ? (_marriageDate ?? DateTime(2020)) : (_livingApartDate ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (marriage) {
          _marriageDate = picked;
        } else {
          _livingApartDate = picked;
        }
      });
    }
  }

  Future<void> _pickChildDate(_ChildData child) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: child.birthDate ?? DateTime(2020),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => child.birthDate = picked);
  }

  String _formatDate(DateTime? date, {bool withDan = false}) {
    if (date == null) return '';
    const months = [
      'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
      'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr',
    ];
    return '${date.year}-yil ${date.day}-${months[date.month - 1]}${withDan ? 'dan' : ''}';
  }

  String _address(String? region, String? district, String street) =>
      '$region, $district, ${street.trim()}';

  String _phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '' : '+998 $digits';
  }

  String? _validatePhone(String? raw, {required bool required}) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (required && digits.length != 9) return '9 raqamli telefon raqamini kiriting.';
    if (!required && digits.isNotEmpty && digits.length != 9) return '9 raqamli telefon raqamini kiriting.';
    return null;
  }

  bool _hasLocations() =>
      _plaintiffRegion != null && _plaintiffDistrict != null &&
      _defendantRegion != null && _defendantDistrict != null &&
      _fhdyoRegion != null && _fhdyoDistrict != null;

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasLocations()) {
      _error('Viloyat va tuman ma’lumotlarini to‘liq tanlang.');
      return;
    }
    if (_marriageDate == null) {
      _error('Nikoh sanasini tanlang.');
      return;
    }
    if ((_isResidence || _isDivorce) && _livingApartDate == null) {
      _error('Alohida yashash boshlangan sanani tanlang.');
      return;
    }
    if (!_isDivorce && _children.isEmpty) {
      _error('Kamida bitta farzand qo‘shing.');
      return;
    }
    for (final child in _children) {
      if (child.name.text.trim().isEmpty || child.birthDate == null) {
        _error('Har bir farzand uchun ism va tug‘ilgan sanani kiriting.');
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final court = AlimonyLocationCatalog.courtForDistrict(_defendantDistrict!);
      final children = _children.map((child) => {
        'full_name': child.name.text.trim(),
        'birth_date_formatted': _formatDate(child.birthDate),
      }).toList(growable: false);
      final benefits = children.map((child) =>
          '${child['birth_date_formatted']} da tug‘ilgan ${child['full_name']}').join(', ');
      final payload = <String, dynamic>{
        'court_name': court,
        'plaintiff_name': _plaintiffName.text.trim(),
        'plaintiff_address': _address(_plaintiffRegion, _plaintiffDistrict, _plaintiffStreet.text),
        'plaintiff_phone': _phone(_plaintiffPhone.text),
        'defendant_name': _defendantName.text.trim(),
        'defendant_address': _address(_defendantRegion, _defendantDistrict, _defendantStreet.text),
        'defendant_phone': _phone(_defendantPhone.text),
        'fhdyo_name': _fhdyoDistrict,
        'marriage_date': _formatDate(_marriageDate),
        'marriage_act_number': _actNumber.text.trim(),
        'children_count': children.length,
        'children_benefit_list': benefits,
        'children': children,
        'date': _formatDate(DateTime.now()),
        'amount': _amount.text.trim(),
        'living_sp_date': _formatDate(_livingApartDate, withDan: true),
        'child_s': children.isEmpty
            ? "farzandimiz yo'q"
            : children.length == 1
                ? 'farzandimiz'
                : 'farzandlarimiz',
        'disagreement_or_divorce': _reason,
        'divorce_note': '',
        'divorce_attachment': '',
        'meet_weekend': _startDay,
        'meet_clock': _startTime,
        'end_weekend': _endDay,
        'end_clock': _endTime,
      };
      await FamilyClaimDocumentService().create(widget.type, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DOCX hujjat Hujjatlar bo‘limiga saqlandi.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _error('Ariza hujjatini yaratib saqlashda xatolik yuz berdi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _error(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: const Color(0xFF7A3040), content: Text(message)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF071A2A),
        appBar: AppBar(title: Text(_title), backgroundColor: const Color(0xFF0D2940)),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                _intro(),
                _section('Arizachi', [
                  _locations(role: _LocationRole.plaintiff),
                  _field(_plaintiffStreet, 'MFY, ko‘cha, uy raqami'),
                  _field(_plaintiffName, 'To‘liq F.I.Sh.'),
                  _field(_plaintiffPhone, 'Telefon raqami', phone: true, required: true),
                ]),
                _section('Javobgar', [
                  _locations(role: _LocationRole.defendant),
                  _courtPreview(),
                  _field(_defendantStreet, 'MFY, ko‘cha, uy raqami'),
                  _field(_defendantName, 'To‘liq F.I.Sh.'),
                  _field(_defendantPhone, 'Telefon raqami ixtiyoriy', phone: true, required: false),
                ]),
                _section('Nikoh ma’lumotlari', [
                  _locations(role: _LocationRole.fhdyo),
                  _dateField('Nikoh tuzilgan sana', _marriageDate, () => _pickDate(marriage: true)),
                  _field(_actNumber, 'Nikoh dalolatnomasi raqami'),
                ]),
                if (_isMother) _section('Ona ta’minoti', [
                  _field(_amount, 'Har oylik so‘ralayotgan summa', keyboard: TextInputType.number),
                ]),
                if (_isResidence || _isDivorce) _section('Alohida yashash', [
                  _dateField('Alohida yashash boshlangan sana', _livingApartDate, () => _pickDate(marriage: false)),
                ]),
                if (_isVisitation) _visitationSection(),
                _childrenSection(),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.description_outlined),
                  label: Text(_submitting ? 'YARATILMOQDA...' : 'ARIZANI TAYYORLASH'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7460D8),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _intro() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text('Ma’lumotlar arizani tayyorlash uchun ishlatiladi. Sud javobgar manziliga qarab avtomatik belgilanadi.', style: TextStyle(color: Colors.blueGrey.shade200, height: 1.4)),
      );

  Widget _section(String title, List<Widget> children) => Card(
        color: const Color(0xFF102B41),
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  Widget _locations({required _LocationRole role}) {
    final region = switch (role) { _LocationRole.plaintiff => _plaintiffRegion, _LocationRole.defendant => _defendantRegion, _LocationRole.fhdyo => _fhdyoRegion };
    final district = switch (role) { _LocationRole.plaintiff => _plaintiffDistrict, _LocationRole.defendant => _defendantDistrict, _LocationRole.fhdyo => _fhdyoDistrict };
    void setRegion(String? value) => setState(() {
      switch (role) { case _LocationRole.plaintiff: _plaintiffRegion = value; _plaintiffDistrict = null; break; case _LocationRole.defendant: _defendantRegion = value; _defendantDistrict = null; break; case _LocationRole.fhdyo: _fhdyoRegion = value; _fhdyoDistrict = null; break; }
    });
    void setDistrict(String? value) => setState(() {
      switch (role) { case _LocationRole.plaintiff: _plaintiffDistrict = value; break; case _LocationRole.defendant: _defendantDistrict = value; break; case _LocationRole.fhdyo: _fhdyoDistrict = value; break; }
    });
    return Column(children: [
      _select('Viloyat', region, AlimonyLocationCatalog.districtsByRegion.keys.toList(), setRegion),
      _select('Tuman yoki shahar', district, region == null ? const [] : AlimonyLocationCatalog.districtsByRegion[region]!, setDistrict),
    ]);
  }

  Widget _select(String label, String? value, List<String> options, ValueChanged<String?> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: options.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: options.isEmpty ? null : onChanged,
          validator: (_) => value == null ? '$label tanlanishi shart.' : null,
        ),
      );

  Widget _field(TextEditingController controller, String label, {bool phone = false, bool required = true, TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: phone ? TextInputType.phone : keyboard,
          inputFormatters: phone ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))] : null,
          decoration: InputDecoration(labelText: label),
          validator: phone ? (value) => _validatePhone(value, required: required) : (value) => required && (value == null || value.trim().isEmpty) ? '$label kiritilishi shart.' : null,
        ),
      );

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value == null ? 'Tanlanmagan' : _formatDate(value)),
        trailing: const Icon(Icons.calendar_month),
        onTap: onTap,
      );

  Widget _courtPreview() {
    final court = _defendantDistrict == null ? null : AlimonyLocationCatalog.courtForDistrict(_defendantDistrict!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(court == null ? 'Tuman tanlangandan keyin sud avtomatik belgilanadi.' : 'Sud: $court sudi', style: TextStyle(color: court == null ? Colors.blueGrey.shade200 : const Color(0xFF9DE9D9))),
    );
  }

  Widget _visitationSection() => _section('Ko‘rishish tartibi', [
        _select('Birga yashamaslik sababi', _reason, const ['o‘zaro kelishmovchiliklar', 'nikoh bekor qilinganligi (ajrashganligimiz)'], (value) => setState(() => _reason = value!)),
        _select('Boshlanish kuni', _startDay, _days, (value) => setState(() => _startDay = value!)),
        _select('Boshlanish vaqti', _startTime, _times, (value) => setState(() => _startTime = value!)),
        _select('Qaytarish kuni', _endDay, _days, (value) => setState(() => _endDay = value!)),
        _select('Qaytarish vaqti', _endTime, _times, (value) => setState(() => _endTime = value!)),
      ]);

  Widget _childrenSection() => _section('Farzandlar', [
        ...List.generate(_children.length, (index) {
          final child = _children[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: const Color(0xFF17364E),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                Row(children: [Text('${index + 1}-farzand', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if (_children.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { final item = _children.removeAt(index); item.dispose(); }))]),
                _field(child.name, 'To‘liq F.I.Sh.'),
                _dateField('Tug‘ilgan sana', child.birthDate, () => _pickChildDate(child)),
              ]),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _children.length >= 15 ? null : () => setState(() => _children.add(_ChildData())),
          icon: const Icon(Icons.add),
          label: const Text('FARZAND QO‘SHISH'),
        ),
      ]);

  static const _days = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
  static const _times = ['06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'];
}

enum _LocationRole { plaintiff, defendant, fhdyo }

class _ChildData {
  final name = TextEditingController();
  DateTime? birthDate;
  void dispose() => name.dispose();
}
