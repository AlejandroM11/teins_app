import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/core/utils/uuid_generator.dart';

void main() {
  group('UuidGenerator', () {
    test('generates non-empty string', () {
      final id = UuidGenerator.generate();
      expect(id, isNotEmpty);
    });

    test('generates UUID v4 format (36 chars with 4 dashes)', () {
      final id = UuidGenerator.generate();
      expect(id.length, 36);
      final parts = id.split('-');
      expect(parts.length, 5);
      expect(parts[0].length, 8);
      expect(parts[1].length, 4);
      expect(parts[2].length, 4);
      expect(parts[3].length, 4);
      expect(parts[4].length, 12);
    });

    test('generates unique IDs on consecutive calls', () {
      final ids = List.generate(100, (_) => UuidGenerator.generate());
      final uniqueIds = ids.toSet();
      // All 100 should be unique
      expect(uniqueIds.length, 100);
    });

    test('generated ID contains only valid UUID characters', () {
      final id = UuidGenerator.generate();
      final validPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(validPattern.hasMatch(id), isTrue,
          reason: 'UUID does not match v4 pattern: $id');
    });
  });
}
