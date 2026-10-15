import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legaltech_app/services/alimony_claim_document_service.dart';
import 'package:legaltech_app/services/alimony_location_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alimony location catalog', () {
    test('every Project 2 district has an explicit court mapping', () {
      final districts = AlimonyLocationCatalog.districtsByRegion.values
          .expand((items) => items)
          .toSet();

      expect(AlimonyLocationCatalog.districtsByRegion, hasLength(14));
      expect(districts, hasLength(208));
      expect(AlimonyLocationCatalog.courtByDistrict.keys.toSet(), districts);
      expect(
        AlimonyLocationCatalog.courtForDistrict('Muborak tumani'),
        'Koson tumanlararo',
      );
      expect(
        () => AlimonyLocationCatalog.courtForDistrict('Unknown district'),
        throwsArgumentError,
      );
    });
  });

  group('Alimony DOCX generation', () {
    late Directory tempDirectory;
    late GeneratedDocumentRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'alimony-docx-test-',
      );
      repository = GeneratedDocumentRepository(
        appDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'fills the supplied template and persists a Hujjatlar entry',
      () async {
        final document =
            await AlimonyClaimDocumentService(repository: repository).create({
              'court_name': 'Koson tumanlararo',
              'plaintiff_name': 'Applicant Person',
              'plaintiff_address': 'Qashqadaryo viloyati, Muborak tumani, 1-uy',
              'plaintiff_phone': '+998 90 123 45 67',
              'defendant_name': 'Respondent Person',
              'defendant_address': 'Qashqadaryo viloyati, Koson tumani, 2-uy',
              'defendant_phone': '',
              'fhdyo_name': 'Muborak tumani',
              'marriage_date': '2020-yil 5-may',
              'marriage_act_number': '125',
              'children_count': '2',
              'children_benefit_list': '2021-yil 2-mart da tug‘ilgan Child One',
              'date': '2026-yil 15-oktyabr',
              'children': [
                {
                  'full_name': 'Child One',
                  'birth_date_formatted': '2021-yil 2-mart',
                },
                {
                  'full_name': 'Child Two',
                  'birth_date_formatted': '2023-yil 10-iyun',
                },
              ],
            });

        final file = File(document.path);
        expect(await file.exists(), isTrue);
        expect(file.path, contains('hujjatlar'));

        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final xmlFile = archive.findFile('word/document.xml');
        expect(xmlFile, isNotNull);
        final xml = utf8.decode(xmlFile!.content as List<int>);
        expect(xml, contains('Koson tumanlararo'));
        expect(xml, contains('Applicant Person'));
        expect(xml, contains('Respondent Person'));
        expect(xml, contains('1. Child One'));
        expect(xml, contains('2. Child Two'));
        expect(xml, isNot(contains('{{')));
        expect(repository.documents.value, hasLength(1));
        expect(repository.documents.value.single.path, document.path);
      },
    );
  });
}
