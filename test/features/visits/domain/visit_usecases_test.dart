import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:teins_app/core/errors/failures.dart';
import 'package:teins_app/features/visits/domain/entities/visit.dart';
import 'package:teins_app/features/visits/domain/repositories/visit_repository.dart';
import 'package:teins_app/features/visits/domain/usecases/complete_visit.dart';
import 'package:teins_app/features/visits/domain/usecases/create_visit.dart';
import 'package:teins_app/features/visits/domain/usecases/get_visit.dart';
import 'package:teins_app/features/visits/domain/usecases/start_visit.dart';
import 'package:teins_app/features/visits/domain/usecases/update_visit.dart';

@GenerateMocks([VisitRepository])
import 'visit_usecases_test.mocks.dart';

void main() {
  late MockVisitRepository mockRepo;
  late Visit sampleVisit;

  setUp(() {
    mockRepo = MockVisitRepository();
    sampleVisit = Visit(
      id: 'visit-001',
      technicianId: 'tech-001',
      title: 'Test Visit',
      visitType: 'infraestructura',
      status: VisitStatus.assigned,
      syncStatus: SyncStatus.local,
      createdAt: DateTime.now(),
    );
  });

  // ── GetVisit ──────────────────────────────────────────────────────────────

  group('GetVisit', () {
    test('returns visit on success', () async {
      when(mockRepo.getVisit('visit-001'))
          .thenAnswer((_) async => Right(sampleVisit));

      final result = await GetVisit(mockRepo)('visit-001');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (v) => expect(v.id, 'visit-001'),
      );
      verify(mockRepo.getVisit('visit-001')).called(1);
    });

    test('returns DatabaseFailure when not found', () async {
      when(mockRepo.getVisit(any)).thenAnswer(
        (_) async => const Left(DatabaseFailure(message: 'Visita no encontrada.')),
      );

      final result = await GetVisit(mockRepo)('nonexistent');
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<DatabaseFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ── CreateVisit ───────────────────────────────────────────────────────────

  group('CreateVisit', () {
    test('creates visit with UUID and local syncStatus', () async {
      when(mockRepo.createVisit(any))
          .thenAnswer((inv) async => Right(inv.positionalArguments[0] as Visit));

      final result = await CreateVisit(mockRepo)(
        const CreateVisitParams(
          technicianId: 'tech-001',
          title: 'Nueva visita',
          visitType: 'energia',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (v) {
          expect(v.id, isNotEmpty);
          expect(v.id.length, 36); // UUID v4 format
          expect(v.status, VisitStatus.assigned);
          expect(v.syncStatus, SyncStatus.local);
          expect(v.technicianId, 'tech-001');
          expect(v.title, 'Nueva visita');
          expect(v.visitType, 'energia');
        },
      );
    });

    test('propagates failure from repository', () async {
      when(mockRepo.createVisit(any)).thenAnswer(
        (_) async => const Left(DatabaseFailure()),
      );

      final result = await CreateVisit(mockRepo)(
        const CreateVisitParams(
          technicianId: 'tech-001',
          title: 'Test',
          visitType: 'datos',
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('each call generates a different UUID', () async {
      final ids = <String>[];
      when(mockRepo.createVisit(any)).thenAnswer((inv) async {
        final v = inv.positionalArguments[0] as Visit;
        ids.add(v.id);
        return Right(v);
      });

      final params = const CreateVisitParams(
        technicianId: 'tech-001',
        title: 'Test',
        visitType: 'datos',
      );
      await CreateVisit(mockRepo)(params);
      await CreateVisit(mockRepo)(params);

      expect(ids.length, 2);
      expect(ids[0], isNot(equals(ids[1])));
    });
  });

  // ── UpdateVisit ───────────────────────────────────────────────────────────

  group('UpdateVisit', () {
    test('sets syncStatus to pendingSync on update', () async {
      Visit? captured;
      when(mockRepo.updateVisit(any)).thenAnswer((inv) async {
        captured = inv.positionalArguments[0] as Visit;
        return Right(captured!);
      });

      await UpdateVisit(mockRepo)(sampleVisit);

      expect(captured?.syncStatus, SyncStatus.pendingSync);
      expect(captured?.updatedAt, isNotNull);
    });
  });

  // ── StartVisit ────────────────────────────────────────────────────────────

  group('StartVisit', () {
    test('calls transitionStatus with inProgress', () async {
      when(mockRepo.transitionStatus('visit-001', VisitStatus.inProgress))
          .thenAnswer((_) async => Right(sampleVisit.copyWith(
                status: VisitStatus.inProgress,
              )));

      final result = await StartVisit(mockRepo)('visit-001');

      expect(result.isRight(), isTrue);
      verify(mockRepo.transitionStatus(
        'visit-001',
        VisitStatus.inProgress,
      )).called(1);
    });
  });

  // ── CompleteVisit ─────────────────────────────────────────────────────────

  group('CompleteVisit', () {
    test('calls transitionStatus with completed', () async {
      when(mockRepo.transitionStatus('visit-001', VisitStatus.completed))
          .thenAnswer((_) async => Right(sampleVisit.copyWith(
                status: VisitStatus.completed,
              )));

      final result = await CompleteVisit(mockRepo)('visit-001');

      expect(result.isRight(), isTrue);
      verify(mockRepo.transitionStatus(
        'visit-001',
        VisitStatus.completed,
      )).called(1);
    });
  });
}
