import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/core/errors/failures.dart';

void main() {
  group('Failure hierarchy', () {
    test('NetworkFailure has user-friendly message', () {
      const failure = NetworkFailure();
      expect(failure.message, contains('sin conexión'));
    });

    test('AuthenticationFailure has user-friendly message', () {
      const failure = AuthenticationFailure();
      expect(failure.message.toLowerCase(), contains('contraseña'));
    });

    test('DatabaseFailure has user-friendly message', () {
      const failure = DatabaseFailure();
      expect(failure.message, isNotEmpty);
    });

    test('SyncFailure message does not mention technical details', () {
      const failure = SyncFailure();
      expect(failure.message.toLowerCase(), isNot(contains('exception')));
      expect(failure.message.toLowerCase(), isNot(contains('stack')));
      expect(failure.message.toLowerCase(), isNot(contains('database')));
    });

    test('ValidationFailure uses provided message', () {
      const failure = ValidationFailure(message: 'Campo requerido');
      expect(failure.message, 'Campo requerido');
    });

    test('failures with same message and code are equal', () {
      const a = NetworkFailure(code: 'NET001');
      const b = NetworkFailure(code: 'NET001');
      expect(a, equals(b));
    });

    test('failures with different codes are not equal', () {
      const a = NetworkFailure(code: 'NET001');
      const b = NetworkFailure(code: 'NET002');
      expect(a, isNot(equals(b)));
    });

    test('originalError is not included in equality', () {
      const a = DatabaseFailure(originalError: 'error1');
      const b = DatabaseFailure(originalError: 'error2');
      // originalError is not in props, so they should be equal
      expect(a, equals(b));
    });

    test('all failure types are subtypes of Failure', () {
      expect(const NetworkFailure(), isA<Failure>());
      expect(const AuthenticationFailure(), isA<Failure>());
      expect(const DatabaseFailure(), isA<Failure>());
      expect(const SyncFailure(), isA<Failure>());
      expect(
        const ValidationFailure(message: 'test'),
        isA<Failure>(),
      );
      expect(const PermissionFailure(), isA<Failure>());
      expect(const StorageFailure(), isA<Failure>());
      expect(const UnknownFailure(), isA<Failure>());
    });
  });
}
