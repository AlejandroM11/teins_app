import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/material.dart';
import '../repositories/material_repository.dart';

class GetVisitMaterials {
  const GetVisitMaterials(this._repository);

  final MaterialRepository _repository;

  Stream<Either<Failure, List<VisitMaterial>>> call(String visitId) =>
      _repository.watchVisitMaterials(visitId);
}
