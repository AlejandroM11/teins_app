import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class CapturePhotoParams {
  const CapturePhotoParams({
    required this.visitId,
    this.formFieldId,
    this.fromGallery = false,
  });

  final String visitId;
  final String? formFieldId;
  final bool fromGallery;
}

/// Captura o selecciona una fotografía y la almacena localmente.
/// No requiere Internet — funciona completamente offline.
class CapturePhoto {
  const CapturePhoto(this._repository);

  final PhotoRepository _repository;

  Future<Either<Failure, VisitPhoto>> call(CapturePhotoParams params) {
    if (params.fromGallery) {
      return _repository.pickFromGallery(
        visitId: params.visitId,
        formFieldId: params.formFieldId,
      );
    }
    return _repository.captureFromCamera(
      visitId: params.visitId,
      formFieldId: params.formFieldId,
    );
  }
}
