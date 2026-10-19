import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/material.dart';
import '../repositories/material_repository.dart';

class UpdateMaterialQuantity {
  const UpdateMaterialQuantity(this._repository);

  final MaterialRepository _repository;

  Future<Either<Failure, VisitMaterial>> call({
    required String visitMaterialId,
    required double quantity,
  }) {
    if (quantity <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'La cantidad debe ser mayor a cero.'),
        ),
      );
    }
    return _repository.updateQuantity(
      visitMaterialId: visitMaterialId,
      quantity: quantity,
    );
  }
}
