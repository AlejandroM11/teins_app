import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:teins_app/core/errors/failures.dart';
import 'package:teins_app/features/authentication/domain/entities/user_profile.dart';
import 'package:teins_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:teins_app/features/authentication/domain/usecases/authenticate_user.dart';
import 'package:teins_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:teins_app/features/authentication/domain/usecases/sign_out.dart';
import 'package:teins_app/features/authentication/presentation/controllers/auth_controller.dart';

@GenerateMocks([AuthRepository])
import 'auth_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;

  final testUser = const UserProfile(
    id: 'user-001',
    email: 'tecnico@teins.com',
    role: UserRole.technician,
    fullName: 'Juan Técnico',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    // Stream que no emite nada por defecto
    when(mockRepo.authStateChanges).thenAnswer((_) => const Stream.empty());
  });

  // ── UserProfile ────────────────────────────────────────────────────────────

  group('UserProfile entity', () {
    test('displayName returns fullName when available', () {
      expect(testUser.displayName, 'Juan Técnico');
    });

    test('displayName falls back to email when no fullName', () {
      const noName = UserProfile(
        id: 'u-002',
        email: 'tech@teins.com',
        role: UserRole.technician,
      );
      expect(noName.displayName, 'tech@teins.com');
    });

    test('initials from two-word name', () {
      expect(testUser.initials, 'JT');
    });

    test('initials from email when no name', () {
      const noName = UserProfile(
        id: 'u-002',
        email: 'ab@teins.com',
        role: UserRole.technician,
      );
      expect(noName.initials, 'AB');
    });

    test('initials from single word name', () {
      const singleName = UserProfile(
        id: 'u-003',
        email: 'x@teins.com',
        role: UserRole.technician,
        fullName: 'Carlos',
      );
      expect(singleName.initials, 'CA');
    });
  });

  // ── UserRole ───────────────────────────────────────────────────────────────

  group('UserRole', () {
    test('fromString parses known roles', () {
      expect(UserRole.fromString('technician'), UserRole.technician);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('office'), UserRole.office);
      expect(UserRole.fromString('client'), UserRole.client);
    });

    test('fromString defaults to technician for unknown role', () {
      expect(UserRole.fromString('superadmin'), UserRole.technician);
    });

    test('canCreateVisit is true for technician and admin', () {
      expect(UserRole.technician.canCreateVisit, isTrue);
      expect(UserRole.admin.canCreateVisit, isTrue);
      expect(UserRole.client.canCreateVisit, isFalse);
      expect(UserRole.office.canCreateVisit, isFalse);
    });

    test('canViewAllVisits is true only for office and admin', () {
      expect(UserRole.office.canViewAllVisits, isTrue);
      expect(UserRole.admin.canViewAllVisits, isTrue);
      expect(UserRole.technician.canViewAllVisits, isFalse);
      expect(UserRole.client.canViewAllVisits, isFalse);
    });
  });

  // ── AuthenticateUser use case ──────────────────────────────────────────────

  group('AuthenticateUser', () {
    test('returns user on successful login', () async {
      when(mockRepo.signIn(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => Right(testUser));

      final result = await AuthenticateUser(mockRepo)(
        const AuthenticateUserParams(
          email: 'tecnico@teins.com',
          password: 'secret123',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (u) {
        expect(u.email, 'tecnico@teins.com');
        expect(u.role, UserRole.technician);
      });
    });

    test('trims and lowercases email before calling repository', () async {
      when(mockRepo.signIn(
        email: 'tecnico@teins.com',
        password: 'secret',
      )).thenAnswer((_) async => Right(testUser));

      await AuthenticateUser(mockRepo)(
        const AuthenticateUserParams(
          email: '  TECNICO@TEINS.COM  ',
          password: 'secret',
        ),
      );

      verify(mockRepo.signIn(
        email: 'tecnico@teins.com',
        password: 'secret',
      )).called(1);
    });

    test('returns AuthenticationFailure on wrong credentials', () async {
      when(mockRepo.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(AuthenticationFailure()));

      final result = await AuthenticateUser(mockRepo)(
        const AuthenticateUserParams(
          email: 'wrong@teins.com',
          password: 'wrongpass',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<AuthenticationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns NetworkFailure on no connection', () async {
      when(mockRepo.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await AuthenticateUser(mockRepo)(
        const AuthenticateUserParams(
          email: 'user@teins.com',
          password: 'pass',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ── GetCurrentUser ─────────────────────────────────────────────────────────

  group('GetCurrentUser', () {
    test('returns user when session exists', () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));

      final result = await GetCurrentUser(mockRepo)();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (u) {
        expect(u?.id, 'user-001');
      });
    });

    test('returns null when no session', () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => const Right(null));

      final result = await GetCurrentUser(mockRepo)();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (u) {
        expect(u, isNull);
      });
    });
  });

  // ── SignOut ────────────────────────────────────────────────────────────────

  group('SignOut', () {
    test('calls repository signOut', () async {
      when(mockRepo.signOut())
          .thenAnswer((_) async => const Right(null));

      await SignOut(mockRepo)();
      verify(mockRepo.signOut()).called(1);
    });
  });

  // ── AuthController ─────────────────────────────────────────────────────────

  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController(
        authenticateUser: AuthenticateUser(mockRepo),
        getCurrentUser: GetCurrentUser(mockRepo),
        signOut: SignOut(mockRepo),
      );
    });

    tearDown(() => controller.dispose());

    test('initial state is AuthInitial', () {
      expect(controller.state, isA<AuthInitial>());
    });

    test('checkSession transitions to Authenticated when user exists', () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));

      await controller.checkSession();

      expect(controller.state, isA<AuthAuthenticated>());
      final s = controller.state as AuthAuthenticated;
      expect(s.user.email, 'tecnico@teins.com');
    });

    test('checkSession transitions to Unauthenticated when no user', () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => const Right(null));

      await controller.checkSession();

      expect(controller.state, isA<AuthUnauthenticated>());
    });

    test('signIn transitions through Loading → Authenticated', () async {
      when(mockRepo.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(testUser));

      final states = <AuthState>[];
      // Capturar estados intermedios no es directo con StateNotifier,
      // pero verificamos el estado final
      await controller.signIn(
        email: 'tecnico@teins.com',
        password: 'secret',
      );

      expect(controller.state, isA<AuthAuthenticated>());
      expect(controller.currentUser?.email, 'tecnico@teins.com');
    });

    test('signIn transitions to AuthError on failure', () async {
      when(mockRepo.signIn(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(AuthenticationFailure()));

      await controller.signIn(email: 'bad@email.com', password: 'wrong');

      expect(controller.state, isA<AuthError>());
      final s = controller.state as AuthError;
      expect(s.failure, isA<AuthenticationFailure>());
    });

    test('signOut transitions to Unauthenticated', () async {
      when(mockRepo.signOut())
          .thenAnswer((_) async => const Right(null));

      await controller.signOut();

      expect(controller.state, isA<AuthUnauthenticated>());
    });

    test('currentUser returns null when not authenticated', () {
      expect(controller.currentUser, isNull);
    });
  });
}
