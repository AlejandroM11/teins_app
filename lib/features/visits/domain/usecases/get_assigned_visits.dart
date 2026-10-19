import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class GetAssignedVisits {
  const GetAssignedVisits(this._repository);

  final VisitRepository _repository;

  Stream<Either<Failure, List<Visit>>> call(String technicianId) =>
      _repository.watchAssignedVisits(technicianId);
}
