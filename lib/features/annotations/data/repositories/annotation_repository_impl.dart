import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';
import '../datasources/annotation_local_datasource.dart';
import '../models/annotation_model.dart';

class AnnotationRepositoryImpl implements AnnotationRepository {
  const AnnotationRepositoryImpl({
    required AnnotationLocalDatasource localDatasource,
  }) : _local = localDatasource;

  final AnnotationLocalDatasource _local;

  @override
  Stream<Either<Failure, VisitAnnotation?>> watchAnnotation(String visitId) {
    return _local
        .watchByVisit(visitId)
        .map<Either<Failure, VisitAnnotation?>>(
          (model) => Right(model?.toEntity()),
        )
        .handleError((e) {
      AppLogger.e('watchAnnotation error', error: e);
      return Left<Failure, VisitAnnotation?>(DatabaseFailure(originalError: e));
    });
  }

  @override
  Future<Either<Failure, VisitAnnotation?>> getAnnotation(
    String visitId,
  ) async {
    try {
      final model = await _local.getByVisit(visitId);
      return Right(model?.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, VisitAnnotation>> saveAnnotation(
    VisitAnnotation annotation,
  ) async {
    try {
      final model = AnnotationModel.fromEntity(annotation);
      await _local.upsert(model);
      AppLogger.d('Annotation saved: ${annotation.visitId}');
      return Right(annotation);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAnnotation(String visitId) async {
    try {
      await _local.deleteByVisit(visitId);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  /// Crea una anotación vacía si no existe para la visita.
  Future<VisitAnnotation> getOrCreate(String visitId) async {
    final existing = await _local.getByVisit(visitId);
    if (existing != null) return existing.toEntity();

    final now = DateTime.now();
    final newAnnotation = VisitAnnotation(
      id: UuidGenerator.generate(),
      visitId: visitId,
      elements: const [],
      syncStatus: 'local',
      createdAt: now,
    );
    final model = AnnotationModel.fromEntity(newAnnotation);
    await _local.upsert(model);
    return newAnnotation;
  }
}
