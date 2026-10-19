import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/annotation.dart';
import '../repositories/annotation_repository.dart';

class SaveAnnotation {
  const SaveAnnotation(this._repository);
  final AnnotationRepository _repository;

  Future<Either<Failure, VisitAnnotation>> call(VisitAnnotation annotation) =>
      _repository.saveAnnotation(
        annotation.copyWith(
          updatedAt: DateTime.now(),
          syncStatus: 'pendingSync',
        ),
      );
}
