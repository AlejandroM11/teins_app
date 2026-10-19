import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/material_repository.dart';

class RemoveMaterialFromVisit {
  const RemoveMaterialFromVisit(this._repository);

  final MaterialRepository _repository;

  Future<Either<Failure, void>> call(String visitMaterialId) =>
      _repository.removeMaterial(visitMaterialId);
}
