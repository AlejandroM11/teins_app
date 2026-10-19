import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo.dart';

abstract interface class PhotoRepository {
  /// Captura una foto con la cámara, la comprime y la almacena localmente.
  /// Retorna la entidad con localPath y syncStatus = pendingUpload.
  Future<Either<Failure, VisitPhoto>> captureFromCamera({
    required String visitId,
    String? formFieldId,
  });

  /// Selecciona una foto desde la galería, la comprime y la almacena localmente.
  Future<Either<Failure, VisitPhoto>> pickFromGallery({
    required String visitId,
    String? formFieldId,
  });

  /// Stream reactivo de fotos de una visita.
  Stream<Either<Failure, List<VisitPhoto>>> watchVisitPhotos(String visitId);

  /// Obtiene las fotos de una visita (snapshot).
  Future<Either<Failure, List<VisitPhoto>>> getVisitPhotos(String visitId);

  /// Actualiza el caption de una foto.
  Future<Either<Failure, void>> updateCaption(String photoId, String? caption);

  /// Elimina una foto. Si ya fue subida a Storage, también la elimina ahí.
  /// Si aún está pendiente, elimina solo el archivo local y el registro.
  Future<Either<Failure, void>> deletePhoto(String photoId);

  /// Sube todas las fotos pendientes de upload a Supabase Storage.
  /// Llamado por el servicio de sincronización cuando hay conexión.
  Future<Either<Failure, int>> uploadPendingPhotos(String visitId);

  /// Obtiene fotos pendientes de subir (útil para indicadores de sync).
  Future<Either<Failure, List<VisitPhoto>>> getPendingUpload(String visitId);
}
