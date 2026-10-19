import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class UpdateVisit {
  const UpdateVisit(this._repository);

  final VisitRepository _repository;

  Future<Either<Failure, Visit>> call(Visit visit) =>
      _repository.updateVisit(
        visit.copyWith(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pendingSync,
        ),
      );
}
