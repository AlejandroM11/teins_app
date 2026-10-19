import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/features/visits/data/models/visit_model.dart';
import 'package:teins_app/features/visits/domain/entities/visit.dart';

void main() {
  group('VisitModel serialization', () {
    final testRow = <String, dynamic>{
      'id': 'visit-abc-123',
      'technician_id': 'tech-001',
      'client_id': 'client-001',
      'client_name': 'Empresa ABC',
      'title': 'Revisión red LAN',
      'description': 'Inspección completa',
      'visit_type': 'datos',
      'address': 'Av. Principal 456',
      'status': 'inProgress',
      'sync_status': 'pendingSync',
      'form_template_id': 'datos_v1',
      'form_template_version': 1,
      'observations': null,
      'created_at': '2025-01-15T10:00:00.000Z',
      'updated_at': '2025-01-15T11:00:00.000Z',
      'started_at': '2025-01-15T10:30:00.000Z',
      'completed_at': null,
      'latitude': -4.1234,
      'longitude': -79.5678,
    };

    test('fromRow creates correct VisitModel', () {
      final model = VisitModel.fromRow(testRow);

      expect(model.id, 'visit-abc-123');
      expect(model.technicianId, 'tech-001');
      expect(model.clientName, 'Empresa ABC');
      expect(model.status, 'inProgress');
      expect(model.syncStatus, 'pendingSync');
      expect(model.latitude, -4.1234);
      expect(model.longitude, -79.5678);
    });

    test('toEntity converts to domain Visit correctly', () {
      final model = VisitModel.fromRow(testRow);
      final entity = model.toEntity();

      expect(entity.id, 'visit-abc-123');
      expect(entity.status, VisitStatus.inProgress);
      expect(entity.syncStatus, SyncStatus.pendingSync);
      expect(entity.createdAt, DateTime.utc(2025, 1, 15, 10, 0, 0));
      expect(entity.startedAt, isNotNull);
      expect(entity.completedAt, isNull);
      expect(entity.latitude, -4.1234);
    });

    test('fromEntity creates correct VisitModel', () {
      final entity = Visit(
        id: 'visit-xyz',
        technicianId: 'tech-002',
        title: 'Test visit',
        visitType: 'energia',
        status: VisitStatus.assigned,
        syncStatus: SyncStatus.local,
        createdAt: DateTime.utc(2025, 2, 1),
      );

      final model = VisitModel.fromEntity(entity);
      expect(model.id, 'visit-xyz');
      expect(model.status, 'assigned');
      expect(model.syncStatus, 'local');
    });

    test('round-trip: entity → model → entity preserves data', () {
      final original = VisitModel.fromRow(testRow).toEntity();
      final roundTripped = VisitModel.fromEntity(original).toEntity();

      expect(roundTripped.id, original.id);
      expect(roundTripped.status, original.status);
      expect(roundTripped.syncStatus, original.syncStatus);
      expect(roundTripped.visitType, original.visitType);
      expect(roundTripped.latitude, original.latitude);
    });

    test('fromRow handles null sync_status with default local', () {
      final row = Map<String, dynamic>.from(testRow)
        ..['sync_status'] = null;
      final model = VisitModel.fromRow(row);
      expect(model.syncStatus, 'local');
    });

    test('toRow produces complete map with all keys', () {
      final model = VisitModel.fromRow(testRow);
      final row = model.toRow();

      expect(row.containsKey('id'), isTrue);
      expect(row.containsKey('technician_id'), isTrue);
      expect(row.containsKey('status'), isTrue);
      expect(row.containsKey('sync_status'), isTrue);
      expect(row.containsKey('created_at'), isTrue);
    });
  });
}
