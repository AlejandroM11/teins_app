import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/form_template.dart';
import '../../domain/repositories/form_repository.dart';
import '../datasources/form_local_datasource.dart';
import '../models/form_models.dart';

class FormRepositoryImpl implements FormRepository {
  const FormRepositoryImpl({required FormLocalDatasource localDatasource})
      : _local = localDatasource;

  final FormLocalDatasource _local;

  @override
  Future<Either<Failure, FormTemplate?>> getTemplateByVisitType(
    String visitType,
  ) async {
    try {
      var model = await _local.getTemplateByVisitType(visitType);

      // Si no está en SQLite, cargar desde assets y sembrar
      if (model == null) {
        AppLogger.i('Template para $visitType no en DB — cargando desde assets');
        final templates = await _local.loadFromAssets();
        final matching = templates.where((t) => t.visitType == visitType);
        if (matching.isEmpty) return const Right(null);

        model = matching.first;
        await _local.seedTemplate(model);
      }

      return Right(model.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      AppLogger.e('getTemplateByVisitType error', error: e);
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, FormTemplate?>> getTemplateById(
    String templateId,
    int version,
  ) async {
    try {
      final model = await _local.getTemplateById(templateId, version);
      return Right(model?.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, FormResponse?>> getResponse(String visitId) async {
    try {
      final model = await _local.getResponse(visitId);
      return Right(model?.toEntity());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, FormResponse>> saveResponse(
    FormResponse response,
  ) async {
    try {
      final model = FormResponseModel.fromEntity(response);
      await _local.upsertResponse(model);
      AppLogger.d('FormResponse guardado: ${response.visitId}');
      return Right(response);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Stream<Either<Failure, FormResponse?>> watchResponse(String visitId) {
    return _local
        .watchResponse(visitId)
        .map<Either<Failure, FormResponse?>>(
          (model) => Right(model?.toEntity()),
        )
        .handleError((e) {
      AppLogger.e('watchResponse error', error: e);
      return Left<Failure, FormResponse?>(DatabaseFailure(originalError: e));
    });
  }

  @override
  Future<Either<Failure, List<FormTemplate>>> loadTemplatesFromAssets() async {
    try {
      final models = await _local.loadFromAssets();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  /// Crea una nueva respuesta vacía para una visita si no existe.
  Future<FormResponse> getOrCreateResponse({
    required String visitId,
    required String templateId,
    required int templateVersion,
  }) async {
    final existing = await _local.getResponse(visitId);
    if (existing != null) return existing.toEntity();

    final now = DateTime.now().toUtc().toIso8601String();
    final newModel = FormResponseModel(
      id: UuidGenerator.generate(),
      visitId: visitId,
      templateId: templateId,
      templateVersion: templateVersion,
      responsesJson: '{}',
      syncStatus: 'local',
      createdAt: now,
    );
    await _local.upsertResponse(newModel);
    return newModel.toEntity();
  }
}
