import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../shared/user_profile.dart';

class GeneratedDocument {
  const GeneratedDocument({
    required this.title,
    required this.path,
    required this.createdAt,
  });

  final String title;
  final String path;
  final DateTime createdAt;
}

/// Local document library. A backend can replace this repository while keeping
/// the same form payload contract.
class GeneratedDocumentRepository {
  GeneratedDocumentRepository({
    Future<Directory> Function()? appDirectoryProvider,
  }) : _appDirectoryProvider =
           appDirectoryProvider ?? getApplicationDocumentsDirectory;

  static final instance = GeneratedDocumentRepository();
  final Future<Directory> Function() _appDirectoryProvider;
  final ValueNotifier<List<GeneratedDocument>> documents =
      ValueNotifier<List<GeneratedDocument>>(<GeneratedDocument>[]);

  Future<Directory> _directory() async {
    final appDirectory = await _appDirectoryProvider();
    final directory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}hujjatlar',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> createFile(String filename, List<int> bytes) async {
    final directory = await _directory();
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    await reload();
    return file;
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    await reload();
  }

  Future<void> reload() async {
    final directory = await _directory();
    final items = <GeneratedDocument>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.docx')) {
        continue;
      }
      final modified = await entity.lastModified();
      items.add(
        GeneratedDocument(
          title: _titleForFilename(entity.uri.pathSegments.last),
          path: entity.path,
          createdAt: modified,
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    documents.value = List.unmodifiable(items);
    if (userProfile.value.savedDocuments != items.length) {
      userProfile.value = userProfile.value.copyWith(
        savedDocuments: items.length,
      );
    }
  }

  String _titleForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.startsWith('ona_taminoti_')) {
      return 'Ona ta’minoti uchun aliment undirish arizasi';
    }
    if (lower.startsWith('bolaning_yashash_joyi_')) {
      return 'Bolaning yashash joyini belgilash arizasi';
    }
    if (lower.startsWith('bola_korishish_')) {
      return 'Bola bilan ko‘rishish tartibini belgilash arizasi';
    }
    if (lower.startsWith('nikohdan_ajrashish_')) {
      return 'Nikohdan ajrashish arizasi';
    }
    return 'Bolaga aliment undirish arizasi';
  }
}

/// Fills the supplied Project 2 DOCX template without changing its other ZIP
/// parts, and stores the result in the app's persistent Hujjatlar directory.
class AlimonyClaimDocumentService {
  AlimonyClaimDocumentService({GeneratedDocumentRepository? repository})
    : _repository = repository ?? GeneratedDocumentRepository.instance;

  final GeneratedDocumentRepository _repository;

  static const _templateAsset = 'assets/templates/aliment_undirish.docx';
  static const _requiredFields = <String>[
    'court_name',
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
  ];

  Future<GeneratedDocument> create(Map<String, dynamic> payload) async {
    final children = (payload['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (children.isEmpty) {
      throw const FormatException('At least one child is required.');
    }

    final values = <String, String>{};
    for (final key in _requiredFields) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isEmpty && key != 'defendant_phone') {
        throw FormatException('Missing required field: $key');
      }
      values[key] = value;
    }
    values['court_name'] = _cleanCourtName(values['court_name']!);
    values['fhdyo_name'] = _cleanFhdyoName(values['fhdyo_name']!);
    values['children_count'] = children.length.toString();
    values['children_benefit_list'] = children
        .map((child) {
          final name = child['full_name']?.toString().trim() ?? '';
          final birthDate =
              child['birth_date_formatted']?.toString().trim() ?? '';
          if (name.isEmpty || birthDate.isEmpty) {
            throw const FormatException(
              'Each child needs a name and birth date.',
            );
          }
          return '$birthDate da tug‘ilgan $name';
        })
        .join(', ');

    final childLines = children
        .map((child) {
          final name = child['full_name']!.toString().trim();
          final birthDate = child['birth_date_formatted']!.toString().trim();
          return '${children.indexOf(child) + 1}. $name – $birthDate da tug‘ilgan.';
        })
        .toList(growable: false);

    final template = await rootBundle.load(_templateAsset);
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
    xml = _replaceChildParagraph(xml, childLines);
    for (final entry in values.entries) {
      xml = xml.replaceAll('{{${entry.key}}}', _xmlEscape(entry.value));
    }
    final unresolved = RegExp(r'\{\{[^{}]+\}\}').firstMatch(xml);
    if (unresolved != null) {
      throw FormatException(
        'Unfilled template placeholder: ${unresolved.group(0)}',
      );
    }
    final updatedDocumentXml = utf8.encode(xml);
    archive.removeFile(documentXml);
    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        updatedDocumentXml.length,
        updatedDocumentXml,
      ),
    );

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The completed DOCX could not be packaged.');
    }
    final filename =
        'aliment_undirish_${DateTime.now().microsecondsSinceEpoch}.docx';
    final file = await _repository.createFile(filename, bytes);
    final createdAt = await file.lastModified();
    final generated = GeneratedDocument(
      title: 'Bolaga aliment undirish arizasi',
      path: file.path,
      createdAt: createdAt,
    );

    await ActivityHistoryRepository.instance.record(
      title: generated.title,
      description:
          'Fuqarolik ishlari bo‘yicha ${values['court_name']} sudiga • ${values['plaintiff_name']}',
      category: ActivityCategory.documents,
      statusLabel: 'Tayyor DOCX',
      filePath: file.path,
      createdAt: createdAt,
      metadata: <String, String>{
        'Xizmat turi': generated.title,
        'Tegishli sud':
            'Fuqarolik ishlari bo‘yicha ${values['court_name']} sudi',
        'Undiruvchi (Da’vogar)': values['plaintiff_name'] ?? '',
        'Qarzdor (Javobgar)': values['defendant_name'] ?? '',
        'Farzandlar soni': '${values['children_count']} nafar',
        'Fayl nomi': filename,
      },
    );

    return generated;
  }

  String _replaceChildParagraph(String xml, List<String> lines) {
    const placeholder = '{{children_list_full}}';
    final placeholderOffset = xml.indexOf(placeholder);
    if (placeholderOffset < 0) {
      throw const FormatException(
        'The template is missing children_list_full.',
      );
    }
    final starts = RegExp(r'<w:p(?:\s[^>]*)?>')
        .allMatches(xml)
        .where((match) => match.start < placeholderOffset)
        .toList(growable: false);
    if (starts.isEmpty) {
      throw const FormatException('Invalid child-list paragraph.');
    }
    final start = starts.last.start;
    final closing = xml.indexOf('</w:p>', placeholderOffset);
    if (closing < 0) {
      throw const FormatException('Invalid child-list paragraph.');
    }
    final end = closing + '</w:p>'.length;
    final paragraph = xml.substring(start, end);
    final replacement = lines
        .map((line) => paragraph.replaceAll(placeholder, _xmlEscape(line)))
        .join();
    return xml.replaceRange(start, end, replacement);
  }

  String _cleanCourtName(String value) =>
      value.replaceFirst(RegExp(r'\s+sudi.*', caseSensitive: false), '').trim();

  String _cleanFhdyoName(String value) {
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

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
