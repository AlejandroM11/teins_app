import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/material.dart';
import '../repositories/material_repository.dart';

class AddMaterialToVisit {
  const AddMaterialToVisit(this._repository);

  final MaterialRepository _repository;

  Future<Either<Failure, VisitMaterial>> call({
    required String visitId,
    required CatalogMaterial catalogMaterial,
    required double quantity,
    String? observations,
  }) =>
      _repository.addMaterial(
        visitId: visitId,
        catalogMaterial: catalogMaterial,
        quantity: quantity,
        observations: observations,
      );
}
