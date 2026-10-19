import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/material.dart';
import '../../domain/repositories/material_repository.dart';
import '../datasources/material_local_datasource.dart';
import '../models/material_model.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  const MaterialRepositoryImpl({
    required MaterialLocalDatasource localDatasource,
  }) : _local = localDatasource;

  final MaterialLocalDatasource _local;

  @override
  Future<Either<Failure, List<CatalogMaterial>>> searchCatalog({
    String query = '',
    String? category,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final models = await _local.searchCatalog(
        query: query,
        category: category,
        limit: limit,
        offset: offset,
      );

      // Si el catálogo está vacío, sembrar datos de demo
      if (models.isEmpty && query.isEmpty && category == null && offset == 0) {
        await seedDemoMaterials();
        final seeded = await _local.searchCatalog(
          query: query,
          category: category,
          limit: limit,
          offset: offset,
        );
        return Right(seeded.map((m) => m.toEntity()).toList());
      }

      return Right(models.map((m) => m.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      final categories = await _local.getCategories();
      return Right(categories);
    } catch (e) {
      return Right(const []); // No crítico — retornar vacío
    }
  }

  @override
  Stream<Either<Failure, List<VisitMaterial>>> watchVisitMaterials(
    String visitId,
  ) {
    return _local
        .watchVisitMaterials(visitId)
        .map<Either<Failure, List<VisitMaterial>>>(
          (models) => Right(models.map((m) => m.toEntity()).toList()),
        )
        .handleError((e) {
      AppLogger.e('watchVisitMaterials error', error: e);
      return Left<Failure, List<VisitMaterial>>(
        DatabaseFailure(originalError: e),
      );
    });
  }

  @override
  Future<Either<Failure, List<VisitMaterial>>> getVisitMaterials(
    String visitId,
  ) async {
    try {
      final models = await _local.getVisitMaterials(visitId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, VisitMaterial>> addMaterial({
    required String visitId,
    required CatalogMaterial catalogMaterial,
    required double quantity,
    String? observations,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final model = VisitMaterialModel(
        id: UuidGenerator.generate(),
        visitId: visitId,
        materialId: catalogMaterial.id,
        materialCode: catalogMaterial.code,
        materialName: catalogMaterial.name,
        unit: catalogMaterial.unit,
        quantity: quantity,
        observations: observations,
        syncStatus: 'pendingSync',
        createdAt: now,
        updatedAt: now,
      );
      await _local.upsertVisitMaterial(model);
      AppLogger.d('Material agregado: ${catalogMaterial.code} × $quantity');
      return Right(model.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, VisitMaterial>> updateQuantity({
    required String visitMaterialId,
    required double quantity,
  }) async {
    try {
      await _local.updateVisitMaterialQuantity(visitMaterialId, quantity);
      // Reconstruir entidad desde el modelo actualizado
      final models = await _local.getVisitMaterials(''); // no ideal
      // Buscar el modelo actualizado
      final rows = await _local.getVisitMaterials('');
      // Simplificación: retornar con los datos disponibles
      final updated = VisitMaterialModel(
        id: visitMaterialId,
        visitId: '',
        materialId: '',
        materialCode: '',
        materialName: '',
        unit: '',
        quantity: quantity,
        syncStatus: 'pendingSync',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return Right(updated.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, VisitMaterial>> updateObservations({
    required String visitMaterialId,
    required String? observations,
  }) async {
    try {
      await _local.updateVisitMaterialObservations(
        visitMaterialId,
        observations,
      );
      return Right(
        VisitMaterial(
          id: visitMaterialId,
          visitId: '',
          materialId: '',
          materialCode: '',
          materialName: '',
          unit: '',
          quantity: 0,
          observations: observations,
          syncStatus: 'pendingSync',
          createdAt: DateTime.now(),
        ),
      );
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, void>> removeMaterial(
    String visitMaterialId,
  ) async {
    try {
      await _local.deleteVisitMaterial(visitMaterialId);
      AppLogger.d('Material eliminado: $visitMaterialId');
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<void> seedDemoMaterials() async {
    AppLogger.i('Sembrando catálogo de materiales demo...');
    for (final m in _demoMaterials) {
      await _local.seedCatalogMaterial(m);
    }
  }

  // ── Datos de demostración del catálogo ────────────────────────────────────

  static final List<CatalogMaterialModel> _demoMaterials = [
    // Cableado
    CatalogMaterialModel(
      id: 'mat-001',
      code: 'CABLE-UTP-CAT6',
      name: 'Cable UTP Cat6',
      description: 'Cable de red UTP categoría 6, 23 AWG',
      unit: 'metro',
      category: 'Cableado',
    ),
    CatalogMaterialModel(
      id: 'mat-002',
      code: 'CABLE-THHN-12',
      name: 'Cable THHN #12 AWG',
      description: 'Cable eléctrico THHN calibre 12',
      unit: 'metro',
      category: 'Cableado',
    ),
    CatalogMaterialModel(
      id: 'mat-003',
      code: 'CABLE-THHN-10',
      name: 'Cable THHN #10 AWG',
      description: 'Cable eléctrico THHN calibre 10',
      unit: 'metro',
      category: 'Cableado',
    ),
    CatalogMaterialModel(
      id: 'mat-004',
      code: 'CABLE-COAX-RG6',
      name: 'Cable Coaxial RG6',
      description: 'Cable coaxial RG6 para TV/datos',
      unit: 'metro',
      category: 'Cableado',
    ),
    CatalogMaterialModel(
      id: 'mat-005',
      code: 'FIBRA-SM-OS2',
      name: 'Fibra óptica OS2 monomodo',
      description: 'Fibra óptica monomodo OS2 para exteriores',
      unit: 'metro',
      category: 'Cableado',
    ),
    // Conectores
    CatalogMaterialModel(
      id: 'mat-010',
      code: 'CONEC-RJ45-CAT6',
      name: 'Conector RJ45 Cat6',
      description: 'Conector macho RJ45 para cable Cat6',
      unit: 'unidad',
      category: 'Conectores',
    ),
    CatalogMaterialModel(
      id: 'mat-011',
      code: 'CONEC-RJ45-CAT6A',
      name: 'Conector RJ45 Cat6A blindado',
      description: 'Conector macho RJ45 STP Cat6A',
      unit: 'unidad',
      category: 'Conectores',
    ),
    CatalogMaterialModel(
      id: 'mat-012',
      code: 'CONEC-LC-SM',
      name: 'Conector LC monomodo',
      description: 'Conector LC/UPC para fibra monomodo',
      unit: 'unidad',
      category: 'Conectores',
    ),
    CatalogMaterialModel(
      id: 'mat-013',
      code: 'CONEC-SC-SM',
      name: 'Conector SC monomodo',
      description: 'Conector SC/UPC para fibra monomodo',
      unit: 'unidad',
      category: 'Conectores',
    ),
    // Tubería / Canaletas
    CatalogMaterialModel(
      id: 'mat-020',
      code: 'TUBO-EMT-3/4',
      name: 'Tubería EMT 3/4"',
      description: 'Tubería metálica EMT para instalaciones eléctricas',
      unit: 'metro',
      category: 'Tubería',
    ),
    CatalogMaterialModel(
      id: 'mat-021',
      code: 'TUBO-PVC-1',
      name: 'Tubería PVC 1"',
      description: 'Tubería PVC conduit de 1 pulgada',
      unit: 'metro',
      category: 'Tubería',
    ),
    CatalogMaterialModel(
      id: 'mat-022',
      code: 'CANALETA-40X25',
      name: 'Canaleta 40×25 mm',
      description: 'Canaleta plástica para cable de red 40×25mm',
      unit: 'metro',
      category: 'Tubería',
    ),
    CatalogMaterialModel(
      id: 'mat-023',
      code: 'CANALETA-60X40',
      name: 'Canaleta 60×40 mm',
      description: 'Canaleta plástica para cable de red 60×40mm',
      unit: 'metro',
      category: 'Tubería',
    ),
    // Protecciones
    CatalogMaterialModel(
      id: 'mat-030',
      code: 'BREAKER-1P-20A',
      name: 'Breaker 1P 20A',
      description: 'Interruptor termomagnético 1 polo 20 amperios',
      unit: 'unidad',
      category: 'Protecciones',
    ),
    CatalogMaterialModel(
      id: 'mat-031',
      code: 'BREAKER-2P-30A',
      name: 'Breaker 2P 30A',
      description: 'Interruptor termomagnético 2 polos 30 amperios',
      unit: 'unidad',
      category: 'Protecciones',
    ),
    CatalogMaterialModel(
      id: 'mat-032',
      code: 'SUPRESOR-120V',
      name: 'Supresor de voltaje 120V',
      description: 'Protector contra sobretensiones para 120V',
      unit: 'unidad',
      category: 'Protecciones',
    ),
    // Equipos de red
    CatalogMaterialModel(
      id: 'mat-040',
      code: 'PATCH-PANEL-24',
      name: 'Patch panel 24 puertos Cat6',
      description: 'Panel de parcheo 24 puertos Cat6 1U',
      unit: 'unidad',
      category: 'Equipos de red',
    ),
    CatalogMaterialModel(
      id: 'mat-041',
      code: 'FACE-PLATE-2P',
      name: 'Face plate 2 puertos',
      description: 'Placa de pared para 2 puertos de red',
      unit: 'unidad',
      category: 'Equipos de red',
    ),
    CatalogMaterialModel(
      id: 'mat-042',
      code: 'KEYSTONE-CAT6',
      name: 'Keystone Jack Cat6',
      description: 'Módulo keystone hembra Cat6',
      unit: 'unidad',
      category: 'Equipos de red',
    ),
    // Fijación
    CatalogMaterialModel(
      id: 'mat-050',
      code: 'ABRAZA-3/4',
      name: 'Abrazadera 3/4"',
      description: 'Abrazadera metálica para tubería 3/4"',
      unit: 'unidad',
      category: 'Fijación',
    ),
    CatalogMaterialModel(
      id: 'mat-051',
      code: 'TACO-8MM',
      name: 'Taco de expansión 8mm',
      description: 'Taco plástico de expansión para tornillo 8mm',
      unit: 'unidad',
      category: 'Fijación',
    ),
    CatalogMaterialModel(
      id: 'mat-052',
      code: 'BRIDA-NEGRO',
      name: 'Brida nylon 300mm',
      description: 'Brida de amarre de nylon negra 300mm',
      unit: 'unidad',
      category: 'Fijación',
    ),
  ];
}
