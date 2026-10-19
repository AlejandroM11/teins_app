import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/annotation_repository.dart';

class DeleteAnnotation {
  const DeleteAnnotation(this._repository);
  final AnnotationRepository _repository;

  Future<Either<Failure, void>> call(String visitId) =>
      _repository.deleteAnnotation(visitId);
}
