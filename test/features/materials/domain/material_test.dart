import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:teins_app/core/errors/failures.dart';
import 'package:teins_app/features/materials/data/models/material_model.dart';
import 'package:teins_app/features/materials/domain/entities/material.dart';
import 'package:teins_app/features/materials/domain/repositories/material_repository.dart';
import 'package:teins_app/features/materials/domain/usecases/add_material_to_visit.dart';
import 'package:teins_app/features/materials/domain/usecases/remove_material_from_visit.dart';
import 'package:teins_app/features/materials/domain/usecases/update_material_quantity.dart';

@GenerateMocks([MaterialRepository])
import 'material_test.mocks.dart';

void main() {
  late MockMaterialRepository mockRepo;

  final sampleMaterial = const CatalogMaterial(
    id: 'mat-001',
    code: 'CABLE-UTP-CAT6',
    name: 'Cable UTP Cat6',
    unit: 'metro',
    category: 'Cableado',
  );

  final sampleVisitMaterial = VisitMaterial(
    id: 'vm-001',
    visitId: 'visit-001',
    materialId: 'mat-001',
    materialCode: 'CABLE-UTP-CAT6',
    materialName: 'Cable UTP Cat6',
    unit: 'metro',
    quantity: 50.0,
    syncStatus: 'pendingSync',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepo = MockMaterialRepository();
  });

  // ── CatalogMaterial ────────────────────────────────────────────────────────

  group('CatalogMaterial entity', () {
    test('creates correctly with required fields', () {
      expect(sampleMaterial.id, 'mat-001');
      expect(sampleMaterial.code, 'CABLE-UTP-CAT6');
      expect(sampleMaterial.isActive, isTrue);
    });

    test('inactive material has isActive false', () {
      const inactive = CatalogMaterial(
        id: 'mat-999',
        code: 'DISCO',
        name: 'Discontinued',
        unit: 'unidad',
        isActive: false,
      );
      expect(inactive.isActive, isFalse);
    });
  });

  // ── VisitMaterial ──────────────────────────────────────────────────────────

  group('VisitMaterial entity', () {
    test('copyWith updates only specified fields', () {
      final updated = sampleVisitMaterial.copyWith(
        quantity: 75.0,
        observations: 'Cable extra para rack 2',
      );
      expect(updated.quantity, 75.0);
      expect(updated.observations, 'Cable extra para rack 2');
      expect(updated.id, sampleVisitMaterial.id);
      expect(updated.materialCode, sampleVisitMaterial.materialCode);
    });
  });

  // ── Model serialization ────────────────────────────────────────────────────

  group('VisitMaterialModel serialization', () {
    test('fromRow creates correct model', () {
      final row = <String, dynamic>{
        'id': 'vm-001',
        'visit_id': 'visit-001',
        'material_id': 'mat-001',
        'material_code': 'CABLE-UTP-CAT6',
        'material_name': 'Cable UTP Cat6',
        'unit': 'metro',
        'quantity': 50.0,
        'observations': 'Para rack principal',
        'sync_status': 'pendingSync',
        'created_at': '2025-01-15T10:00:00.000Z',
        'updated_at': null,
      };

      final model = VisitMaterialModel.fromRow(row);
      expect(model.quantity, 50.0);
      expect(model.observations, 'Para rack principal');
      expect(model.syncStatus, 'pendingSync');
    });

    test('toEntity maps to domain entity correctly', () {
      final row = <String, dynamic>{
        'id': 'vm-001',
        'visit_id': 'visit-001',
        'material_id': 'mat-001',
        'material_code': 'CABLE-UTP-CAT6',
        'material_name': 'Cable UTP Cat6',
        'unit': 'metro',
        'quantity': 30.5,
        'observations': null,
        'sync_status': 'synced',
        'created_at': '2025-01-15T10:00:00.000Z',
        'updated_at': null,
      };
      final model = VisitMaterialModel.fromRow(row);
      final entity = model.toEntity();

      expect(entity.quantity, 30.5);
      expect(entity.syncStatus, 'synced');
      expect(entity.observations, isNull);
    });

    test('fromEntity round-trip preserves all data', () {
      final model = VisitMaterialModel.fromEntity(sampleVisitMaterial);
      final entity = model.toEntity();

      expect(entity.id, sampleVisitMaterial.id);
      expect(entity.visitId, sampleVisitMaterial.visitId);
      expect(entity.quantity, sampleVisitMaterial.quantity);
      expect(entity.materialCode, sampleVisitMaterial.materialCode);
    });
  });

  // ── Use cases ─────────────────────────────────────────────────────────────

  group('AddMaterialToVisit', () {
    test('adds material and returns VisitMaterial', () async {
      when(mockRepo.addMaterial(
        visitId: anyNamed('visitId'),
        catalogMaterial: anyNamed('catalogMaterial'),
        quantity: anyNamed('quantity'),
        observations: anyNamed('observations'),
      )).thenAnswer((_) async => Right(sampleVisitMaterial));

      final result = await AddMaterialToVisit(mockRepo)(
        visitId: 'visit-001',
        catalogMaterial: sampleMaterial,
        quantity: 50.0,
      );

      expect(result.isRight(), isTrue);
      verify(mockRepo.addMaterial(
        visitId: 'visit-001',
        catalogMaterial: sampleMaterial,
        quantity: 50.0,
        observations: null,
      )).called(1);
    });
  });

  group('UpdateMaterialQuantity', () {
    test('succeeds with positive quantity', () async {
      when(mockRepo.updateQuantity(
        visitMaterialId: anyNamed('visitMaterialId'),
        quantity: anyNamed('quantity'),
      )).thenAnswer((_) async => Right(sampleVisitMaterial));

      final result = await UpdateMaterialQuantity(mockRepo)(
        visitMaterialId: 'vm-001',
        quantity: 100.0,
      );
      expect(result.isRight(), isTrue);
    });

    test('returns ValidationFailure for zero quantity', () async {
      final result = await UpdateMaterialQuantity(mockRepo)(
        visitMaterialId: 'vm-001',
        quantity: 0.0,
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(mockRepo.updateQuantity(
        visitMaterialId: anyNamed('visitMaterialId'),
        quantity: anyNamed('quantity'),
      ));
    });

    test('returns ValidationFailure for negative quantity', () async {
      final result = await UpdateMaterialQuantity(mockRepo)(
        visitMaterialId: 'vm-001',
        quantity: -5.0,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('RemoveMaterialFromVisit', () {
    test('calls repository with correct id', () async {
      when(mockRepo.removeMaterial(any))
          .thenAnswer((_) async => const Right(null));

      await RemoveMaterialFromVisit(mockRepo)('vm-001');
      verify(mockRepo.removeMaterial('vm-001')).called(1);
    });

    test('propagates failure', () async {
      when(mockRepo.removeMaterial(any))
          .thenAnswer((_) async => const Left(DatabaseFailure()));

      final result = await RemoveMaterialFromVisit(mockRepo)('vm-001');
      expect(result.isLeft(), isTrue);
    });
  });
}
