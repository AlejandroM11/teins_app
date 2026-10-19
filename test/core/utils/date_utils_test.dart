import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    final testDate = DateTime(2025, 3, 15, 14, 30, 0);

    group('formatDate', () {
      test('formats as dd/MM/yyyy', () {
        expect(AppDateUtils.formatDate(testDate), '15/03/2025');
      });
    });

    group('formatDateTime', () {
      test('formats as dd/MM/yyyy HH:mm', () {
        expect(AppDateUtils.formatDateTime(testDate), '15/03/2025 14:30');
      });
    });

    group('formatTime', () {
      test('formats as HH:mm', () {
        expect(AppDateUtils.formatTime(testDate), '14:30');
      });
    });

    group('toIso', () {
      test('converts to UTC ISO 8601', () {
        final utcDate = DateTime.utc(2025, 3, 15, 14, 30, 0);
        expect(AppDateUtils.toIso(utcDate), '2025-03-15T14:30:00.000Z');
      });
    });

    group('parseIso', () {
      test('parses valid ISO string', () {
        final result = AppDateUtils.parseIso('2025-03-15T14:30:00.000Z');
        expect(result, isNotNull);
        expect(result!.year, 2025);
        expect(result.month, 3);
        expect(result.day, 15);
      });

      test('returns null for null input', () {
        expect(AppDateUtils.parseIso(null), isNull);
      });

      test('returns null for empty string', () {
        expect(AppDateUtils.parseIso(''), isNull);
      });

      test('returns null for invalid date string', () {
        expect(AppDateUtils.parseIso('not-a-date'), isNull);
      });
    });

    group('formatRelative', () {
      test('shows "Ahora mismo" for recent date', () {
        final now = DateTime.now();
        expect(AppDateUtils.formatRelative(now), 'Ahora mismo');
      });

      test('shows minutes for date < 1 hour ago', () {
        final thirtyMinutesAgo =
            DateTime.now().subtract(const Duration(minutes: 30));
        final result = AppDateUtils.formatRelative(thirtyMinutesAgo);
        expect(result, contains('min'));
      });

      test('shows hours for date < 24 hours ago', () {
        final threeHoursAgo =
            DateTime.now().subtract(const Duration(hours: 3));
        final result = AppDateUtils.formatRelative(threeHoursAgo);
        expect(result, contains('h'));
      });
    });
  });
}
