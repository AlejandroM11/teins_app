import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/features/visits/domain/entities/visit.dart';

void main() {
  group('Visit entity', () {
    late Visit assignedVisit;
    late Visit inProgressVisit;

    setUp(() {
      final now = DateTime(2025, 1, 15, 10, 0);
      assignedVisit = Visit(
        id: 'visit-001',
        technicianId: 'tech-001',
        title: 'Inspección planta norte',
        visitType: 'infraestructura',
        status: VisitStatus.assigned,
        syncStatus: SyncStatus.local,
        createdAt: now,
      );
      inProgressVisit = assignedVisit.copyWith(
        status: VisitStatus.inProgress,
        startedAt: now.add(const Duration(hours: 1)),
      );
    });

    // ── Máquina de estados ──────────────────────────────────────────────

    group('state machine', () {
      test('assigned → inProgress is valid', () {
        final updated = assignedVisit.transitionTo(VisitStatus.inProgress);
        expect(updated.status, VisitStatus.inProgress);
        expect(updated.startedAt, isNotNull);
        expect(updated.syncStatus, SyncStatus.pendingSync);
      });

      test('inProgress → completed is valid', () {
        final updated = inProgressVisit.transitionTo(VisitStatus.completed);
        expect(updated.status, VisitStatus.completed);
        expect(updated.completedAt, isNotNull);
        expect(updated.syncStatus, SyncStatus.pendingSync);
      });

      test('assigned → completed throws ArgumentError', () {
        expect(
          () => assignedVisit.transitionTo(VisitStatus.completed),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('completed → inProgress throws ArgumentError', () {
        final completed = inProgressVisit.transitionTo(VisitStatus.completed);
        expect(
          () => completed.transitionTo(VisitStatus.inProgress),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('synced → any throws ArgumentError', () {
        final synced = assignedVisit.copyWith(status: VisitStatus.synced);
        for (final status in VisitStatus.values) {
          if (status != VisitStatus.synced) {
            expect(
              () => synced.transitionTo(status),
              throwsA(isA<ArgumentError>()),
              reason: 'synced → ${status.name} should be invalid',
            );
          }
        }
      });

      test('startedAt is preserved if already set when transitioning', () {
        final alreadyStarted = assignedVisit.copyWith(
          status: VisitStatus.assigned,
          startedAt: DateTime(2025, 1, 15, 9, 0),
        );
        final updated = alreadyStarted.transitionTo(VisitStatus.inProgress);
        expect(updated.startedAt, DateTime(2025, 1, 15, 9, 0));
      });
    });

    // ── Propiedades derivadas ────────────────────────────────────────────

    group('derived properties', () {
      test('isEditable is true for assigned status', () {
        expect(assignedVisit.isEditable, isTrue);
      });

      test('isEditable is true for inProgress status', () {
        expect(inProgressVisit.isEditable, isTrue);
      });

      test('isEditable is false for completed', () {
        final completed = inProgressVisit.transitionTo(VisitStatus.completed);
        expect(completed.isEditable, isFalse);
      });

      test('hasPendingSync is true for local syncStatus', () {
        expect(assignedVisit.hasPendingSync, isTrue);
      });

      test('hasPendingSync is true for pendingSync status', () {
        final pending = assignedVisit.copyWith(syncStatus: SyncStatus.pendingSync);
        expect(pending.hasPendingSync, isTrue);
      });

      test('hasPendingSync is false for synced', () {
        final synced = assignedVisit.copyWith(syncStatus: SyncStatus.synced);
        expect(synced.hasPendingSync, isFalse);
      });

      test('hasPendingSync is true for syncError', () {
        final error = assignedVisit.copyWith(syncStatus: SyncStatus.syncError);
        expect(error.hasPendingSync, isTrue);
      });
    });

    // ── Serialización ─────────────────────────────────────────────────────

    group('VisitStatus', () {
      test('fromString returns correct status', () {
        expect(VisitStatus.fromString('inProgress'), VisitStatus.inProgress);
        expect(VisitStatus.fromString('assigned'), VisitStatus.assigned);
        expect(VisitStatus.fromString('completed'), VisitStatus.completed);
      });

      test('fromString falls back to assigned for unknown value', () {
        expect(VisitStatus.fromString('unknown_xyz'), VisitStatus.assigned);
      });

      test('displayName is not empty for all statuses', () {
        for (final status in VisitStatus.values) {
          expect(status.displayName, isNotEmpty);
        }
      });
    });

    group('SyncStatus', () {
      test('fromString returns correct status', () {
        expect(SyncStatus.fromString('synced'), SyncStatus.synced);
        expect(SyncStatus.fromString('pendingSync'), SyncStatus.pendingSync);
        expect(SyncStatus.fromString('syncError'), SyncStatus.syncError);
      });

      test('fromString falls back to local for unknown value', () {
        expect(SyncStatus.fromString('garbage'), SyncStatus.local);
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────

    group('copyWith', () {
      test('produces new instance with updated fields', () {
        final updated = assignedVisit.copyWith(
          title: 'Nuevo título',
          address: 'Calle 123',
        );
        expect(updated.title, 'Nuevo título');
        expect(updated.address, 'Calle 123');
        // Campos no modificados conservados
        expect(updated.id, assignedVisit.id);
        expect(updated.technicianId, assignedVisit.technicianId);
      });

      test('original is not mutated', () {
        assignedVisit.copyWith(title: 'Cambiado');
        expect(assignedVisit.title, 'Inspección planta norte');
      });
    });

    // ── Equatable ────────────────────────────────────────────────────────

    group('equality', () {
      test('two visits with same id are equal', () {
        final other = assignedVisit.copyWith(title: 'Diferente título');
        expect(assignedVisit, isNot(equals(other))); // title no está en props
        // pero sí tienen el mismo id en props
        final sameId = assignedVisit.copyWith();
        expect(assignedVisit, equals(sameId));
      });
    });
  });
}
