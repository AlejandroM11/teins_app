import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/form_template.dart';
import '../repositories/form_repository.dart';

class GetFormResponse {
  const GetFormResponse(this._repository);

  final FormRepository _repository;

  Future<Either<Failure, FormResponse?>> call(String visitId) =>
      _repository.getResponse(visitId);

  Stream<Either<Failure, FormResponse?>> watch(String visitId) =>
      _repository.watchResponse(visitId);
}
