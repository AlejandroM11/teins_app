import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_local_datasource.dart';
import '../models/photo_model.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({
    required PhotoLocalDatasource localDatasource,
    required SupabaseClient supabaseClient,
    required ConnectivityService connectivityService,
    required PermissionService permissionService,
  })  : _local = localDatasource,
        _supabase = supabaseClient,
        _connectivity = connectivityService,
        _permissions = permissionService,
        _picker = ImagePicker();

  final PhotoLocalDatasource _local;
  final SupabaseClient _supabase;
  final ConnectivityService _connectivity;
  final PermissionService _permissions;
  final ImagePicker _picker;

  @override
  Future<Either<Failure, VisitPhoto>> captureFromCamera({
    required String visitId,
    String? formFieldId,
  }) async {
    // Verificar permiso de cámara
    final permFailure = await _permissions.requestCamera();
    if (permFailure != null) return Left(permFailure);

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90, // Pre-compresión nativa del picker
      );
      if (xFile == null) {
        return const Left(
          ValidationFailure(message: 'No se capturó ninguna imagen.'),
        );
      }
      return _processAndSave(
        xFile: xFile,
        visitId: visitId,
        formFieldId: formFieldId,
      );
    } on PermissionException catch (e) {
      return Left(PermissionFailure(originalError: e));
    } catch (e) {
      AppLogger.e('captureFromCamera error', error: e);
      return Left(StorageFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, VisitPhoto>> pickFromGallery({
    required String visitId,
    String? formFieldId,
  }) async {
    final permFailure = await _permissions.requestStorage();
    if (permFailure != null) return Left(permFailure);

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (xFile == null) {
        return const Left(
          ValidationFailure(message: 'No se seleccionó ninguna imagen.'),
        );
      }
      return _processAndSave(
        xFile: xFile,
        visitId: visitId,
        formFieldId: formFieldId,
      );
    } catch (e) {
      AppLogger.e('pickFromGallery error', error: e);
      return Left(StorageFailure(originalError: e));
    }
  }

  /// Comprime y guarda la fotografía en almacenamiento local.
  ///
  /// Proceso:
  /// 1. Leer bytes originales
  /// 2. Decodificar imagen
  /// 3. Redimensionar si excede máximo (1920×1080)
  /// 4. Re-codificar como JPEG con calidad 85
  /// 5. Guardar en directorio de la app (persistente entre sesiones)
  /// 6. Insertar metadata en SQLite con syncStatus = pendingUpload
  /// 7. Si hay Internet, iniciar upload en background
  Future<Either<Failure, VisitPhoto>> _processAndSave({
    required XFile xFile,
    required String visitId,
    String? formFieldId,
  }) async {
    try {
      final photoId = UuidGenerator.generate();
      final bytes = await xFile.readAsBytes();

      // Decodificar y comprimir
      final compressed = await _compressImage(bytes);
      if (compressed == null) {
        return const Left(
          StorageFailure(message: 'Error al procesar la imagen.'),
        );
      }

      // Guardar en directorio local permanente de la app
      final localPath = await _saveToLocal(photoId, compressed.bytes);

      final now = DateTime.now();
      final model = PhotoModel(
        id: photoId,
        visitId: visitId,
        formFieldId: formFieldId,
        localPath: localPath,
        syncStatus: 'pendingUpload',
        capturedAt: now.toUtc().toIso8601String(),
        fileSizeBytes: compressed.bytes.length,
        width: compressed.width,
        height: compressed.height,
      );

      await _local.insert(model);
      AppLogger.i('Foto guardada localmente: $photoId '
          '(${compressed.bytes.length ~/ 1024} KB)');

      final entity = model.toEntity();

      // Upload en background si hay conexión (no bloquear UI)
      if (_connectivity.isOnline) {
        unawaited(_uploadPhoto(entity));
      }

      return Right(entity);
    } catch (e) {
      AppLogger.e('_processAndSave error', error: e);
      return Left(StorageFailure(originalError: e));
    }
  }

  /// Comprime la imagen: redimensiona si es demasiado grande y re-encoda como JPEG.
  Future<_CompressResult?> _compressImage(List<int> bytes) async {
    try {
      final original = img.decodeImage(Uint8List.fromList(bytes));
      if (original == null) return null;

      // Redimensionar solo si supera el máximo configurado
      img.Image processed = original;
      if (original.width > AppConstants.kPhotoMaxWidth ||
          original.height > AppConstants.kPhotoMaxHeight) {
        processed = img.copyResize(
          original,
          width: AppConstants.kPhotoMaxWidth,
          height: AppConstants.kPhotoMaxHeight,
          interpolation: img.Interpolation.linear,
          maintainAspect: true,
        );
      }

      final jpegBytes = img.encodeJpg(
        processed,
        quality: AppConstants.kPhotoJpegQuality,
      );

      return _CompressResult(
        bytes: jpegBytes,
        width: processed.width,
        height: processed.height,
      );
    } catch (e) {
      AppLogger.e('_compressImage error', error: e);
      return null;
    }
  }

  /// Guarda los bytes en el directorio de documentos de la app.
  /// Este directorio persiste entre sesiones (no es caché temporal).
  Future<String> _saveToLocal(String photoId, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'teins_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final file = File(p.join(photosDir.path, '$photoId.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Sube una foto a Supabase Storage en background.
  ///
  /// Regla crítica: NUNCA eliminar el archivo local hasta confirmar
  /// que el upload fue exitoso y el syncStatus se actualizó a 'uploaded'.
  Future<void> _uploadPhoto(VisitPhoto photo) async {
    try {
      await _local.updateSyncStatus(photo.id, 'uploading');

      final file = File(photo.localPath);
      if (!await file.exists()) {
        AppLogger.w('Archivo local no encontrado: ${photo.localPath}');
        await _local.updateSyncStatus(photo.id, 'uploadError');
        return;
      }

      final bytes = await file.readAsBytes();
      final storagePath = AppConstants.photosPath(photo.visitId, photo.id);

      await _supabase.storage
          .from(AppConstants.kPhotosBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final url = _supabase.storage
          .from(AppConstants.kPhotosBucket)
          .getPublicUrl(storagePath);

      await _local.updateSyncStatus(
        photo.id,
        'uploaded',
        storagePath: storagePath,
        storageUrl: url,
        uploadedAt: DateTime.now().toUtc().toIso8601String(),
      );

      AppLogger.i('Foto subida correctamente: ${photo.id}');
    } catch (e) {
      AppLogger.e('_uploadPhoto error: ${photo.id}', error: e);
      // Marcar como error pero NO borrar el archivo local
      await _local.updateSyncStatus(photo.id, 'uploadError');
    }
  }

  @override
  Stream<Either<Failure, List<VisitPhoto>>> watchVisitPhotos(String visitId) {
    return _local
        .watchByVisit(visitId)
        .map<Either<Failure, List<VisitPhoto>>>(
          (models) => Right(models.map((m) => m.toEntity()).toList()),
        )
        .handleError((e) {
      return Left<Failure, List<VisitPhoto>>(
        DatabaseFailure(originalError: e),
      );
    });
  }

  @override
  Future<Either<Failure, List<VisitPhoto>>> getVisitPhotos(
    String visitId,
  ) async {
    try {
      final models = await _local.getByVisit(visitId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    } catch (e) {
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, void>> updateCaption(
    String photoId,
    String? caption,
  ) async {
    try {
      await _local.updateCaption(photoId, caption);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(String photoId) async {
    try {
      final model = await _local.getById(photoId);
      if (model == null) return const Right(null);

      // Eliminar archivo local
      final file = File(model.localPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.d('Archivo local eliminado: ${model.localPath}');
      }

      // Si ya fue subida, eliminar de Storage también
      if (model.storagePath != null &&
          model.syncStatus == 'uploaded' &&
          _connectivity.isOnline) {
        try {
          await _supabase.storage
              .from(AppConstants.kPhotosBucket)
              .remove([model.storagePath!]);
        } catch (e) {
          AppLogger.w('No se pudo eliminar de Storage (continuando): $e');
        }
      }

      await _local.delete(photoId);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, int>> uploadPendingPhotos(String visitId) async {
    if (!_connectivity.isOnline) {
      return const Right(0);
    }
    try {
      final pending = await _local.getPendingUpload(visitId);
      var uploaded = 0;
      for (final model in pending) {
        await _uploadPhoto(model.toEntity());
        uploaded++;
      }
      return Right(uploaded);
    } catch (e) {
      return Left(SyncFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, List<VisitPhoto>>> getPendingUpload(
    String visitId,
  ) async {
    try {
      final models = await _local.getPendingUpload(visitId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Right(const []);
    }
  }
}

class _CompressResult {
  const _CompressResult({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
