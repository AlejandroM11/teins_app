import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/form_template.dart';
import '../repositories/form_repository.dart';

class SaveFormResponse {
  const SaveFormResponse(this._repository);

  final FormRepository _repository;

  Future<Either<Failure, FormResponse>> call(FormResponse response) =>
      _repository.saveResponse(
        response.copyWith(
          updatedAt: DateTime.now(),
          syncStatus: 'pendingSync',
        ),
      );
}
