import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class GetVisit {
  const GetVisit(this._repository);

  final VisitRepository _repository;

  Future<Either<Failure, Visit>> call(String visitId) =>
      _repository.getVisit(visitId);
}
