import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class GetVisitPhotos {
  const GetVisitPhotos(this._repository);

  final PhotoRepository _repository;

  Stream<Either<Failure, List<VisitPhoto>>> call(String visitId) =>
      _repository.watchVisitPhotos(visitId);

  Future<Either<Failure, List<VisitPhoto>>> once(String visitId) =>
      _repository.getVisitPhotos(visitId);
}
