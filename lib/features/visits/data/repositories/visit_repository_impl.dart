import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/visit.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_local_datasource.dart';
import '../models/visit_model.dart';

class VisitRepositoryImpl implements VisitRepository {
  const VisitRepositoryImpl({required VisitLocalDatasource localDatasource})
      : _local = localDatasource;

  final VisitLocalDatasource _local;

  @override
  Stream<Either<Failure, List<Visit>>> watchAssignedVisits(
    String technicianId,
  ) {
    return _local.watchByTechnician(technicianId).map<Either<Failure, List<Visit>>>(
      (models) => Right(models.map((m) => m.toEntity()).toList()),
    ).handleError((e) {
      AppLogger.e('watchAssignedVisits error', error: e);
      return Left<Failure, List<Visit>>(DatabaseFailure(originalError: e));
    });
  }

  @override
  Future<Either<Failure, List<Visit>>> getAssignedVisits(
    String technicianId,
  ) async {
    try {
      final models = await _local.getByTechnician(technicianId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      AppLogger.e('getAssignedVisits error', error: e);
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, Visit>> getVisit(String visitId) async {
    try {
      final model = await _local.getById(visitId);
      if (model == null) {
        return const Left(
          DatabaseFailure(message: 'Visita no encontrada.'),
        );
      }
      return Right(model.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, Visit>> createVisit(Visit visit) async {
    try {
      final model = VisitModel.fromEntity(visit);
      await _local.upsert(model);
      AppLogger.i('Visita creada localmente: ${visit.id}');
      return Right(visit);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, Visit>> updateVisit(Visit visit) async {
    try {
      final model = VisitModel.fromEntity(visit);
      await _local.upsert(model);
      AppLogger.d('Visita actualizada localmente: ${visit.id}');
      return Right(visit);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, Visit>> transitionStatus(
    String visitId,
    VisitStatus newStatus,
  ) async {
    try {
      final model = await _local.getById(visitId);
      if (model == null) {
        return const Left(DatabaseFailure(message: 'Visita no encontrada.'));
      }

      final entity = model.toEntity();

      // Validar la transición en el dominio
      final updated = entity.transitionTo(newStatus);

      await _local.updateStatus(
        visitId,
        updated.status.name,
        updated.syncStatus.name,
      );

      // Actualizar timestamps si los cambió la transición
      if (updated.startedAt != null || updated.completedAt != null) {
        await _local.upsert(VisitModel.fromEntity(updated));
      }

      AppLogger.i('Visita $visitId → ${newStatus.name}');
      return Right(updated);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(message: e.message.toString()));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }
}
