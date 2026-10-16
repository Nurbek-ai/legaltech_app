import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import 'alimony_claim_document_service.dart';

enum FamilyClaimType { motherSupport, childResidence, childVisitation, divorce }

class FamilyClaimDocumentService {
  FamilyClaimDocumentService({GeneratedDocumentRepository? repository})
      : _repository = repository ?? GeneratedDocumentRepository.instance;

  final GeneratedDocumentRepository _repository;

  static final _definitions = <FamilyClaimType, _DocumentDefinition>{
    FamilyClaimType.motherSupport: _DocumentDefinition(
      asset: 'assets/templates/ona_taminoti.docx',
      filenamePrefix: 'ona_taminoti',
      title: 'Ona ta’minoti uchun aliment undirish arizasi',
      requiredFields: [..._commonFields, 'amount'],
    ),
    FamilyClaimType.childResidence: _DocumentDefinition(
      asset: 'assets/templates/bolaning_yashash_joyi.docx',
      filenamePrefix: 'bolaning_yashash_joyi',
      title: 'Bolaning yashash joyini belgilash arizasi',
      requiredFields: [..._commonFields, 'living_sp_date', 'child_s'],
    ),
    FamilyClaimType.childVisitation: _DocumentDefinition(
      asset: 'assets/templates/bola_korishish.docx',
      filenamePrefix: 'bola_korishish',
      title: 'Bola bilan ko‘rishish tartibini belgilash arizasi',
      requiredFields: [
        ..._commonFields,
        'disagreement_or_divorce',
        'meet_weekend',
        'meet_clock',
        'end_weekend',
        'end_clock',
      ],
    ),
    FamilyClaimType.divorce: _DocumentDefinition(
      asset: 'assets/templates/nikohdan_ajrashish.docx',
      filenamePrefix: 'nikohdan_ajrashish',
      title: 'Nikohdan ajrashish arizasi',
      requiredFields: [..._commonFields, 'living_sp_date', 'child_s'],
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
    'children_benefit_list',
    'date',
  ];

  Future<GeneratedDocument> create(
    FamilyClaimType type,
    Map<String, dynamic> payload,
  ) async {
    final definition = _definitions[type]!;
    final values = <String, String>{};
    for (final key in definition.requiredFields) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw FormatException('Missing required field: $key');
      }
      values[key] = value;
    }

    // These fields are optional in the Project 2 forms but still appear in
    // some templates. Empty values remove the template token without adding
    // legal assertions that the user did not provide.
    for (final key in const [
      'defendant_phone',
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
    values['court_name'] = values['court_name']!
        .replaceFirst(RegExp(r'\s+sudi.*', caseSensitive: false), '')
        .trim();

    final children = (payload['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final childLines = <String>[];
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final name = child['full_name']?.toString().trim() ?? '';
      final birthDate = child['birth_date_formatted']?.toString().trim() ?? '';
      if (name.isEmpty || birthDate.isEmpty) {
        throw const FormatException('Each child needs a name and birth date.');
      }
      childLines.add('${index + 1}. $name – $birthDate da tug‘ilgan.');
    }

    final template = await rootBundle.load(definition.asset);
    final archive = ZipDecoder().decodeBytes(
      template.buffer.asUint8List(template.offsetInBytes, template.lengthInBytes),
    );
    final documentXml = archive.findFile('word/document.xml');
    if (documentXml == null) {
      throw const FormatException('The DOCX template has no Word document body.');
    }

    var xml = utf8.decode(documentXml.content as List<int>);
    if (xml.contains('{{children_list_full}}')) {
      xml = _replaceChildParagraph(xml, childLines);
    }
    for (final entry in values.entries) {
      xml = xml.replaceAll('{{${entry.key}}}', _xmlEscape(entry.value));
    }
    final unresolved = RegExp(r'\{\{[^{}]+\}\}').firstMatch(xml);
    if (unresolved != null) {
      throw FormatException('Unfilled template placeholder: ${unresolved.group(0)}');
    }

    final updated = utf8.encode(xml);
    archive.removeFile(documentXml);
    archive.addFile(ArchiveFile('word/document.xml', updated.length, updated));
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The completed DOCX could not be packaged.');
    }

    final filename = '${definition.filenamePrefix}_${DateTime.now().microsecondsSinceEpoch}.docx';
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
    final paragraph = xml.substring(start, closing + '</w:p>'.length);
    return xml.replaceRange(
      start,
      closing + '</w:p>'.length,
      lines.map((line) => paragraph.replaceAll(placeholder, _xmlEscape(line))).join(),
    );
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
  });

  final String asset;
  final String filenamePrefix;
  final String title;
  final List<String> requiredFields;
}
