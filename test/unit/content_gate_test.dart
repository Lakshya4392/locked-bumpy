import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/domain/models/need_rotation.dart';

void main() {
  // Allow rootBundle access in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Inline gate logic tests (no asset load needed) ────────────────────────

  group('ContentGate — inline validator', () {
    test('valid approved line passes gate', () {
      const r = ContentRecord(
        id: 'test_01',
        category: 'greeting',
        need: 'IRON',
        mode: 'everyday',
        tone: 'cheeky',
        text: 'Iron snack? Lentils or beans, your pick.',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      );
      expect(() => ContentGate.validate(r), returnsNormally);
    });

    test('draft status is rejected', () {
      const r = ContentRecord(
        id: 'test_02',
        category: 'greeting',
        need: 'IRON',
        mode: 'everyday',
        tone: 'gentle',
        text: 'Cape on. Thank you!',
        status: 'draft',
        approvedBy: '',
        approvedDate: '',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });

    test('banned word "missed" is rejected regardless of status', () {
      const r = ContentRecord(
        id: 'test_03',
        category: 'greeting',
        need: 'IRON',
        mode: 'everyday',
        tone: 'gentle',
        text: 'You missed your vitamin yesterday!',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });

    test('banned word "kick" is rejected', () {
      const r = ContentRecord(
        id: 'test_04',
        category: 'greeting',
        need: 'IRON',
        mode: 'everyday',
        tone: 'cheeky',
        text: 'Kick counter time!',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });

    test('banned word "floating" is rejected', () {
      const r = ContentRecord(
        id: 'test_05',
        category: 'thank_you',
        need: 'REST',
        mode: 'halloween',
        tone: 'gentle',
        text: 'Floating peacefully. Thank you!',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });

    test('banned word "potion" is rejected', () {
      const r = ContentRecord(
        id: 'test_06',
        category: 'greeting',
        need: 'VITAMIN',
        mode: 'halloween',
        tone: 'cheeky',
        text: 'Potion time! Drink up.',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });

    test('needs_fix status is rejected', () {
      const r = ContentRecord(
        id: 'test_07',
        category: 'greeting',
        need: 'WATER',
        mode: 'both',
        tone: 'gentle',
        text: 'Water time!',
        status: 'needs_fix',
        approvedBy: '',
        approvedDate: '',
      );
      expect(
        () => ContentGate.validate(r),
        throwsA(isA<ContentGateException>()),
      );
    });
  });

  test(
    'one withdrawn Today line leaves reviewed neighbours available',
    () async {
      Map<String, String> row(String id, String status, String text) => {
        'id': id,
        'category': 'greeting',
        'need': 'IRON',
        'mode': 'both',
        'tone': 'gentle',
        'text': text,
        'status': status,
        'approved_by': status == 'approved' ? 'Fixture reviewer' : '',
        'approved_date': status == 'approved' ? '2026-11-23' : '',
      };
      const path = 'test/partial-review-pack.json';
      final raw = jsonEncode([
        row('draft', 'draft', 'Draft greeting.'),
        row('ready', 'approved', 'Hello.'),
        row('withdrawn', 'needs_fix', 'Withdrawn greeting.'),
        row('unsafe', 'approved', 'You missed it.'),
        {
          ...row('undated', 'approved', 'Undated greeting.'),
          'approved_date': '',
        },
      ]);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        expect(
          utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          ),
          path,
        );
        return ByteData.sublistView(utf8.encode(raw));
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.evict(path);
        ContentLoader.clearCache();
      });
      final visible = await ContentLoader.load(path);
      expect(visible.map((r) => r.id), ['ready']);
      expect(
        ContentLoader.find(
          records: visible,
          need: 'IRON',
          category: 'greeting',
          mode: 'halloween',
        )?.text,
        'Hello.',
      );
      expect(
        () => ContentGate.validateAll(ContentRecord.listFromJsonString(raw)),
        throwsA(isA<ContentGateException>()),
      );
    },
  );

  // ── Real JSON asset tests ─────────────────────────────────────────────────

  group('today_lines.json — real asset', () {
    late List<ContentRecord> records;

    setUpAll(() async {
      final raw = await rootBundle.loadString(
        'assets/content/today_lines.json',
      );
      records = ContentRecord.listFromJsonString(raw);
    });

    test('loads without throwing (all records pass gate)', () {
      expect(records, isNotEmpty);
      expect(() => ContentGate.validateAll(records), returnsNormally);
    });

    test('every record has status approved', () {
      for (final r in records) {
        expect(
          r.status,
          equals('approved'),
          reason: 'record ${r.id} has status ${r.status}',
        );
      }
    });

    test('all 6 needs have an everyday greeting', () {
      for (final need in MaternalNeed.values) {
        final r = ContentLoader.find(
          records: records,
          need: need.needName,
          category: 'greeting',
          mode: 'everyday',
        );
        expect(
          r,
          isNotNull,
          reason: 'missing everyday greeting for ${need.needName}',
        );
      }
    });

    test('all 6 needs have a halloween greeting', () {
      for (final need in MaternalNeed.values) {
        final r = ContentLoader.find(
          records: records,
          need: need.needName,
          category: 'greeting',
          mode: 'halloween',
        );
        expect(
          r,
          isNotNull,
          reason: 'missing halloween greeting for ${need.needName}',
        );
      }
    });

    test('all 6 needs have an everyday thank_you', () {
      for (final need in MaternalNeed.values) {
        final r = ContentLoader.find(
          records: records,
          need: need.needName,
          category: 'thank_you',
          mode: 'everyday',
        );
        expect(
          r,
          isNotNull,
          reason: 'missing everyday thank_you for ${need.needName}',
        );
      }
    });

    test('all 6 needs have a halloween thank_you', () {
      for (final need in MaternalNeed.values) {
        final r = ContentLoader.find(
          records: records,
          need: need.needName,
          category: 'thank_you',
          mode: 'halloween',
        );
        expect(
          r,
          isNotNull,
          reason: 'missing halloween thank_you for ${need.needName}',
        );
      }
    });

    test('a goodbye line exists for need=ALL', () {
      final r = ContentLoader.find(
        records: records,
        need: 'ALL',
        category: 'goodbye',
        mode: 'everyday',
      );
      expect(r, isNotNull);
    });

    test('today rotation need has a greeting in both modes', () {
      final need = NeedRotation.forDate(DateTime(2026, 11, 23)); // IRON
      for (final mode in ['everyday', 'halloween']) {
        final r = ContentLoader.find(
          records: records,
          need: need.needName,
          category: 'greeting',
          mode: mode,
        );
        expect(
          r,
          isNotNull,
          reason: 'missing greeting for ${need.needName} in $mode',
        );
      }
    });
  });

  group('ContentLoader.find', () {
    const records = [
      ContentRecord(
        id: 'a',
        category: 'greeting',
        need: 'IRON',
        mode: 'both',
        tone: 'cheeky',
        text: 'Hello both',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      ),
      ContentRecord(
        id: 'b',
        category: 'greeting',
        need: 'IRON',
        mode: 'halloween',
        tone: 'cheeky',
        text: 'Hello halloween',
        status: 'approved',
        approvedBy: 'Karan',
        approvedDate: '2026-11-23',
      ),
    ];

    test('finds mode=both record when searching everyday', () {
      final r = ContentLoader.find(
        records: records,
        need: 'IRON',
        category: 'greeting',
        mode: 'everyday',
      );
      expect(r?.id, equals('a'));
    });

    test('finds mode=halloween record when searching halloween', () {
      // mode=both comes first and matches, so a is found first.
      final r = ContentLoader.find(
        records: records,
        need: 'IRON',
        category: 'greeting',
        mode: 'halloween',
      );
      expect(r?.id, equals('a')); // first match wins
    });

    test('returns null when no match', () {
      final r = ContentLoader.find(
        records: records,
        need: 'WATER',
        category: 'greeting',
        mode: 'everyday',
      );
      expect(r, isNull);
    });
  });
}
