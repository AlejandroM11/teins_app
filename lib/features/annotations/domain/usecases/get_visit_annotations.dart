import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/annotation.dart';
import '../repositories/annotation_repository.dart';

class GetVisitAnnotations {
  const GetVisitAnnotations(this._repository);
  final AnnotationRepository _repository;

  Stream<Either<Failure, VisitAnnotation?>> call(String visitId) =>
      _repository.watchAnnotation(visitId);

  Future<Either<Failure, VisitAnnotation?>> once(String visitId) =>
      _repository.getAnnotation(visitId);
}
