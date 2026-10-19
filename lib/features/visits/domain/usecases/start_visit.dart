import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

/// Inicia una visita: assigned → inProgress.
class StartVisit {
  const StartVisit(this._repository);

  final VisitRepository _repository;

  Future<Either<Failure, Visit>> call(String visitId) =>
      _repository.transitionStatus(visitId, VisitStatus.inProgress);
}
