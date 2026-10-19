import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/photo_repository.dart';

class DeletePhoto {
  const DeletePhoto(this._repository);

  final PhotoRepository _repository;

  Future<Either<Failure, void>> call(String photoId) =>
      _repository.deletePhoto(photoId);
}
