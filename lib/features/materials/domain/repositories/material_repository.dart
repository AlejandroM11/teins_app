import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/material.dart';

abstract interface class MaterialRepository {
  /// Busca materiales en el catálogo local con filtro incremental.
  /// [query] se normaliza para búsqueda insensible a tildes y mayúsculas.
  Future<Either<Failure, List<CatalogMaterial>>> searchCatalog({
    String query = '',
    String? category,
    int limit = 30,
    int offset = 0,
  });

  /// Obtiene todas las categorías disponibles en el catálogo.
  Future<Either<Failure, List<String>>> getCategories();

  /// Stream reactivo de materiales usados en una visita.
  Stream<Either<Failure, List<VisitMaterial>>> watchVisitMaterials(
    String visitId,
  );

  /// Obtiene los materiales de una visita (snapshot).
  Future<Either<Failure, List<VisitMaterial>>> getVisitMaterials(
    String visitId,
  );

  /// Agrega un material a la visita.
  Future<Either<Failure, VisitMaterial>> addMaterial({
    required String visitId,
    required CatalogMaterial catalogMaterial,
    required double quantity,
    String? observations,
  });

  /// Actualiza la cantidad de un material en la visita.
  Future<Either<Failure, VisitMaterial>> updateQuantity({
    required String visitMaterialId,
    required double quantity,
  });

  /// Actualiza las observaciones de un material en la visita.
  Future<Either<Failure, VisitMaterial>> updateObservations({
    required String visitMaterialId,
    required String? observations,
  });

  /// Elimina un material de la visita.
  Future<Either<Failure, void>> removeMaterial(String visitMaterialId);

  /// Siembra el catálogo de materiales de demo en SQLite.
  Future<void> seedDemoMaterials();
}
