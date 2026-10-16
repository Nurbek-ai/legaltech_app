import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import 'alimony_claim_document_service.dart';
import 'alimony_location_catalog.dart';

enum FamilyClaimType { motherSupport, childResidence, childVisitation, divorce }

class FamilyClaimDocumentService {
  FamilyClaimDocumentService({GeneratedDocumentRepository? repository})
    : _repository = repository ?? GeneratedDocumentRepository.instance;

  final GeneratedDocumentRepository _repository;

  static final _definitions = <FamilyClaimType, _DocumentDefinition>{
    FamilyClaimType.motherSupport: const _DocumentDefinition(
      asset: 'assets/templates/ona_taminoti.docx',
      filenamePrefix: 'ona_taminoti',
      title: 'Ona ta’minoti uchun aliment undirish arizasi',
      requiredFields: <String>[..._commonFields, 'amount'],
      allowZeroChildren: false,
    ),
    FamilyClaimType.childResidence: const _DocumentDefinition(
      asset: 'assets/templates/bolaning_yashash_joyi.docx',
      filenamePrefix: 'bolaning_yashash_joyi',
      title: 'Bolaning yashash joyini belgilash arizasi',
      requiredFields: <String>[..._commonFields, 'living_sp_date', 'child_s'],
      allowZeroChildren: false,
    ),
    FamilyClaimType.childVisitation: const _DocumentDefinition(
      asset: 'assets/templates/bola_korishish.docx',
      filenamePrefix: 'bola_korishish',
      title: 'Bola bilan ko‘rishish tartibini belgilash arizasi',
      requiredFields: <String>[
        ..._commonFields,
        'disagreement_or_divorce',
        'meet_weekend',
        'meet_clock',
        'end_weekend',
        'end_clock',
      ],
      allowZeroChildren: false,
    ),
    FamilyClaimType.divorce: const _DocumentDefinition(
      asset: 'assets/templates/nikohdan_ajrashish.docx',
      filenamePrefix: 'nikohdan_ajrashish',
      title: 'Nikohdan ajrashish arizasi',
      requiredFields: <String>[..._commonFields, 'living_sp_date', 'child_s'],
      allowZeroChildren: true,
    ),
  };

  static const _commonFields = <String>[
    'court_name',
    'plaintiff_name',
    'plaintiff_address',
    'plaintiff_phone',
    'defendant_name',
    'defendant_address',
    'fhdyo_name',
    'marriage_date',
    'marriage_act_number',
    'children_count',
    'date',
  ];

  static const _uzbekMonths = <String>[
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentyabr',
    'oktyabr',
    'noyabr',
    'dekabr',
  ];

  static String formatUzbekDate(DateTime date) {
    return '${date.year}-yil ${date.day}-${_uzbekMonths[date.month - 1]}';
  }

  static String formatUzbekDateWithDa(DateTime date) {
    return '${formatUzbekDate(date)}da';
  }

  static String formatUzbekDateWithDan(DateTime date) {
    return '${formatUzbekDate(date)}dan';
  }

  static String formatAmount(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw.trim();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String cleanCourtName(String value) {
    return value
        .replaceFirst(RegExp(r'\s+sudi.*$', caseSensitive: false), '')
        .trim();
  }

  static String cleanFhdyoName(String value) {
    var cleaned = value.replaceAll(
      RegExp(r"(?:FHDYo|FHDYO|Fhdyo)\s*bo['‘`’]?limi", caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:FHDYo|FHDYO|Fhdyo)', caseSensitive: false),
      '',
    );
    return cleaned.trim();
  }

  Future<GeneratedDocument> create(
    FamilyClaimType type,
    Map<String, dynamic> payload,
  ) async {
    final definition = _definitions[type]!;
    final children = (payload['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (!definition.allowZeroChildren && children.isEmpty) {
      throw const FormatException('At least one child is required.');
    }

    final childLines = <String>[];
    final childBenefitsWithDa = <String>[];
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final name = child['full_name']?.toString().trim() ?? '';
      var birthNormal = child['birth_date_formatted']?.toString().trim() ?? '';
      var birthWithDa =
          child['birth_date_da_formatted']?.toString().trim() ?? '';

      if (birthNormal.isEmpty && child['birth_date'] != null) {
        final parsed = DateTime.tryParse(child['birth_date'].toString());
        if (parsed != null) {
          birthNormal = formatUzbekDate(parsed);
          birthWithDa = formatUzbekDateWithDa(parsed);
        }
      }
      if (birthWithDa.isEmpty && birthNormal.isNotEmpty) {
        birthWithDa = birthNormal.endsWith('da')
            ? birthNormal
            : '${birthNormal}da';
      }

      if (name.isEmpty || birthNormal.isEmpty) {
        throw const FormatException('Each child needs a name and birth date.');
      }
      childLines.add('${index + 1}. $name – $birthNormal da tug‘ilgan.');
      childBenefitsWithDa.add('$birthWithDa tug‘ilgan $name');
    }

    final values = <String, String>{};

    var rawCourt = payload['court_name']?.toString().trim() ?? '';
    if (rawCourt.isEmpty) {
      final district = payload['defendant_district']?.toString().trim() ?? '';
      if (district.isNotEmpty) {
        rawCourt = AlimonyLocationCatalog.courtForDistrict(district);
      }
    }

    for (final key in const <String>[
      'plaintiff_name',
      'plaintiff_address',
      'plaintiff_phone',
      'defendant_name',
      'defendant_address',
      'defendant_phone',
      'fhdyo_name',
      'marriage_date',
      'marriage_act_number',
      'children_count',
      'children_benefit_list',
      'date',
      'amount',
      'living_sp_date',
      'child_s',
      'disagreement_or_divorce',
      'divorce_note',
      'divorce_attachment',
      'meet_weekend',
      'meet_clock',
      'end_weekend',
      'end_clock',
    ]) {
      values[key] = payload[key]?.toString().trim() ?? '';
    }

    values['court_name'] = cleanCourtName(rawCourt);
    values['fhdyo_name'] = cleanFhdyoName(values['fhdyo_name']!);

    if (values['children_count']!.isEmpty) {
      values['children_count'] = children.length.toString();
    }

    if (values['children_benefit_list']!.isEmpty &&
        childBenefitsWithDa.isNotEmpty) {
      values['children_benefit_list'] = childBenefitsWithDa.join(', ');
    }

    if (values['child_s']!.isEmpty) {
      final count = int.tryParse(values['children_count']!) ?? children.length;
      values['child_s'] = count == 0
          ? "farzandimiz yo'q"
          : (count == 1 ? 'farzandimiz' : 'farzandlarimiz');
    }

    if (values['date']!.isEmpty) {
      values['date'] = formatUzbekDate(DateTime.now());
    }

    if (type == FamilyClaimType.motherSupport &&
        values['amount']!.isNotEmpty) {
      values['amount'] = formatAmount(values['amount']!);
    }

    if (type == FamilyClaimType.childResidence &&
        values['living_sp_date']!.isNotEmpty) {
      if (!values['living_sp_date']!.endsWith('dan')) {
        values['living_sp_date'] = '${values['living_sp_date']}dan';
      }
    }

    if (type == FamilyClaimType.divorce &&
        values['living_sp_date']!.isNotEmpty) {
      values['living_sp_date'] = values['living_sp_date']!.replaceFirst(
        RegExp(r'dan$', caseSensitive: false),
        '',
      );
    }

    if (type == FamilyClaimType.childVisitation) {
      final reason = values['disagreement_or_divorce']!;
      final isDivorced = reason.toLowerCase().contains('nikoh bekor');
      if (isDivorced) {
        if (values['divorce_note']!.isEmpty) {
          values['divorce_note'] =
              '(nikoh bekor qilinganligi dalolatnomasi ilova qilinadi)';
        }
        if (values['divorce_attachment']!.isEmpty) {
          values['divorce_attachment'] =
              '5. Nikoh bekor qilinganligi yuzasidan dalolatnoma.';
        }
      } else {
        values['divorce_note'] = '';
        values['divorce_attachment'] = '';
      }
      values['meet_weekend'] = values['meet_weekend']!.toLowerCase();
      values['end_weekend'] = values['end_weekend']!.toLowerCase();
    }

    for (final key in definition.requiredFields) {
      if ((values[key] ?? '').isEmpty) {
        throw FormatException('Missing required field: $key');
      }
    }

    final countInt = int.tryParse(values['children_count']!) ?? children.length;
    if (countInt > 0 && (values['children_benefit_list'] ?? '').isEmpty) {
      throw const FormatException(
        'Missing required field: children_benefit_list',
      );
    }

    final template = await rootBundle.load(definition.asset);
    final archive = ZipDecoder().decodeBytes(
      template.buffer.asUint8List(
        template.offsetInBytes,
        template.lengthInBytes,
      ),
    );
    final documentXml = archive.findFile('word/document.xml');
    if (documentXml == null) {
      throw const FormatException(
        'The DOCX template has no Word document body.',
      );
    }

    var xml = utf8.decode(documentXml.content as List<int>);
    if (xml.contains('{{children_list_full}}')) {
      xml = _replaceChildParagraph(xml, childLines);
    }

    if (type == FamilyClaimType.divorce && countInt == 0) {
      xml = _replaceParagraphText(
        xml,
        '{{child_s}}',
        'Birgalikda turmushimizdan farzandimiz yo‘q.',
      );
    }

    if (type == FamilyClaimType.childVisitation) {
      if (values['divorce_note']!.isEmpty) {
        xml = xml.replaceAll(
          RegExp(
            r'<w:r>(?:(?!</w:r>).)*<w:t xml:space="preserve"> </w:t></w:r>'
            r'<w:r>(?:(?!</w:r>).)*<w:t>\{\{divorce_note\}\}</w:t></w:r>',
          ),
          '',
        );
      }
      if (values['divorce_attachment']!.isEmpty) {
        xml = _removeParagraphWithPlaceholder(xml, '{{divorce_attachment}}');
      }
    }

    for (final entry in values.entries) {
      xml = xml.replaceAll('{{${entry.key}}}', _xmlEscape(entry.value));
    }

    final unresolved = RegExp(r'\{\{[^{}]+\}\}').firstMatch(xml);
    if (unresolved != null) {
      throw FormatException(
        'Unfilled template placeholder: ${unresolved.group(0)}',
      );
    }

    final updated = utf8.encode(xml);
    archive.removeFile(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', updated.length, updated));
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The completed DOCX could not be packaged.');
    }

    final filename =
        '${definition.filenamePrefix}_${DateTime.now().microsecondsSinceEpoch}.docx';
    final file = await _repository.createFile(filename, bytes);
    return GeneratedDocument(
      title: definition.title,
      path: file.path,
      createdAt: await file.lastModified(),
    );
  }

  String _replaceChildParagraph(String xml, List<String> lines) {
    const placeholder = '{{children_list_full}}';
    final offset = xml.indexOf(placeholder);
    if (offset < 0) return xml;
    final starts = RegExp(r'<w:p(?:\s[^>]*)?>')
        .allMatches(xml)
        .where((match) => match.start < offset)
        .toList(growable: false);
    if (starts.isEmpty) {
      throw const FormatException('Invalid child-list paragraph.');
    }
    final start = starts.last.start;
    final closing = xml.indexOf('</w:p>', offset);
    if (closing < 0) {
      throw const FormatException('Invalid child-list paragraph.');
    }
    final end = closing + '</w:p>'.length;
    final paragraph = xml.substring(start, end);
    return xml.replaceRange(
      start,
      end,
      lines
          .map((line) => paragraph.replaceAll(placeholder, _xmlEscape(line)))
          .join(),
    );
  }

  String _replaceParagraphText(
    String xml,
    String placeholder,
    String replacementText,
  ) {
    final offset = xml.indexOf(placeholder);
    if (offset < 0) return xml;
    final starts = RegExp(r'<w:p(?:\s[^>]*)?>')
        .allMatches(xml)
        .where((match) => match.start < offset)
        .toList(growable: false);
    if (starts.isEmpty) return xml;
    final start = starts.last.start;
    final closing = xml.indexOf('</w:p>', offset);
    if (closing < 0) return xml;
    final end = closing + '</w:p>'.length;
    final paragraph = xml.substring(start, end);
    final pPrMatch = RegExp(r'<w:pPr>.*?</w:pPr>').firstMatch(paragraph);
    final pPr = pPrMatch?.group(0) ?? '';
    final replacementParagraph =
        '<w:p>$pPr<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" '
        'w:hAnsi="Times New Roman"/><w:sz w:val="28"/></w:rPr>'
        '<w:t>${_xmlEscape(replacementText)}</w:t></w:r></w:p>';
    return xml.replaceRange(start, end, replacementParagraph);
  }

  String _removeParagraphWithPlaceholder(String xml, String placeholder) {
    final offset = xml.indexOf(placeholder);
    if (offset < 0) return xml;
    final starts = RegExp(r'<w:p(?:\s[^>]*)?>')
        .allMatches(xml)
        .where((match) => match.start < offset)
        .toList(growable: false);
    if (starts.isEmpty) {
      return xml.replaceAll(placeholder, '');
    }
    final start = starts.last.start;
    final closing = xml.indexOf('</w:p>', offset);
    if (closing < 0) {
      return xml.replaceAll(placeholder, '');
    }
    return xml.replaceRange(start, closing + '</w:p>'.length, '');
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

class _DocumentDefinition {
  const _DocumentDefinition({
    required this.asset,
    required this.filenamePrefix,
    required this.title,
    required this.requiredFields,
    required this.allowZeroChildren,
  });

  final String asset;
  final String filenamePrefix;
  final String title;
  final List<String> requiredFields;
  final bool allowZeroChildren;
}
