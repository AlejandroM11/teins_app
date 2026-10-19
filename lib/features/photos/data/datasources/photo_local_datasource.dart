import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../synchronization/data/services/powersync_service.dart';
import '../models/photo_model.dart';

abstract interface class PhotoLocalDatasource {
  Future<void> insert(PhotoModel model);
  Future<void> updateSyncStatus(
    String photoId,
    String syncStatus, {
    String? storagePath,
    String? storageUrl,
    String? uploadedAt,
  });
  Future<void> updateCaption(String photoId, String? caption);
  Future<void> delete(String photoId);
  Future<PhotoModel?> getById(String photoId);
  Stream<List<PhotoModel>> watchByVisit(String visitId);
  Future<List<PhotoModel>> getByVisit(String visitId);
  Future<List<PhotoModel>> getPendingUpload(String visitId);
}

class PhotoLocalDatasourceImpl implements PhotoLocalDatasource {
  const PhotoLocalDatasourceImpl({required PowerSyncService powerSyncService})
      : _db = powerSyncService;

  final PowerSyncService _db;
  static const _table = 'photos';

  @override
  Future<void> insert(PhotoModel model) async {
    try {
      await _db.execute(
        '''
        INSERT INTO $_table (
          id, visit_id, form_field_id, local_path, caption,
          sync_status, storage_path, storage_url,
          file_size_bytes, width, height,
          captured_at, uploaded_at
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
        ''',
        [
          model.id,
          model.visitId,
          model.formFieldId,
          model.localPath,
          model.caption,
          model.syncStatus,
          model.storagePath,
          model.storageUrl,
          model.fileSizeBytes,
          model.width,
          model.height,
          model.capturedAt,
          model.uploadedAt,
        ],
      );
    } catch (e) {
      AppLogger.e('PhotoDatasource.insert error', error: e);
      throw DatabaseException(
        message: 'Error al guardar la fotografía.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateSyncStatus(
    String photoId,
    String syncStatus, {
    String? storagePath,
    String? storageUrl,
    String? uploadedAt,
  }) async {
    try {
      await _db.execute(
        '''
        UPDATE $_table
        SET sync_status   = ?,
            storage_path  = COALESCE(?, storage_path),
            storage_url   = COALESCE(?, storage_url),
            uploaded_at   = COALESCE(?, uploaded_at)
        WHERE id = ?
        ''',
        [syncStatus, storagePath, storageUrl, uploadedAt, photoId],
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error al actualizar estado de la foto.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateCaption(String photoId, String? caption) async {
    try {
      await _db.execute(
        'UPDATE $_table SET caption = ? WHERE id = ?',
        [caption, photoId],
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error al actualizar el caption.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> delete(String photoId) async {
    try {
      await _db.execute(
        'DELETE FROM $_table WHERE id = ?',
        [photoId],
      );
    } catch (e) {
      throw DatabaseException(
        message: 'Error al eliminar la fotografía.',
        originalError: e,
      );
    }
  }

  @override
  Future<PhotoModel?> getById(String photoId) async {
    try {
      final row = await _db.getOptional(
        'SELECT * FROM $_table WHERE id = ?',
        [photoId],
      );
      return row != null ? PhotoModel.fromRow(row) : null;
    } catch (e) {
      throw DatabaseException(
        message: 'Error al cargar la fotografía.',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<PhotoModel>> watchByVisit(String visitId) {
    return _db
        .watch(
          'SELECT * FROM $_table WHERE visit_id = ? ORDER BY captured_at DESC',
          [visitId],
        )
        .map((rows) => rows.map(PhotoModel.fromRow).toList());
  }

  @override
  Future<List<PhotoModel>> getByVisit(String visitId) async {
    try {
      final rows = await _db.getAll(
        'SELECT * FROM $_table WHERE visit_id = ? ORDER BY captured_at DESC',
        [visitId],
      );
      return rows.map(PhotoModel.fromRow).toList();
    } catch (e) {
      throw DatabaseException(
        message: 'Error al cargar las fotografías.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<PhotoModel>> getPendingUpload(String visitId) async {
    try {
      final rows = await _db.getAll(
        '''
        SELECT * FROM $_table
        WHERE visit_id = ?
          AND sync_status IN ('pendingUpload', 'local', 'uploadError')
        ORDER BY captured_at ASC
        ''',
        [visitId],
      );
      return rows.map(PhotoModel.fromRow).toList();
    } catch (e) {
      return [];
    }
  }
}
