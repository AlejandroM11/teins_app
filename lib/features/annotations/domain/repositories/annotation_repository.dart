import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/annotation.dart';

abstract interface class AnnotationRepository {
  /// Stream reactivo de la anotación de una visita.
  Stream<Either<Failure, VisitAnnotation?>> watchAnnotation(String visitId);

  /// Obtiene la anotación (snapshot).
  Future<Either<Failure, VisitAnnotation?>> getAnnotation(String visitId);

  /// Guarda (upsert) la anotación completa.
  Future<Either<Failure, VisitAnnotation>> saveAnnotation(
    VisitAnnotation annotation,
  );

  /// Elimina la anotación de una visita.
  Future<Either<Failure, void>> deleteAnnotation(String visitId);
}
