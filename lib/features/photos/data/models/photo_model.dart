import '../../domain/entities/photo.dart';

class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.visitId,
    required this.localPath,
    required this.syncStatus,
    required this.capturedAt,
    this.formFieldId,
    this.caption,
    this.storagePath,
    this.storageUrl,
    this.fileSizeBytes,
    this.width,
    this.height,
    this.uploadedAt,
  });

  final String id;
  final String visitId;
  final String? formFieldId;
  final String localPath;
  final String? caption;
  final String syncStatus;
  final String? storagePath;
  final String? storageUrl;
  final int? fileSizeBytes;
  final int? width;
  final int? height;
  final String capturedAt;
  final String? uploadedAt;

  factory PhotoModel.fromRow(Map<String, dynamic> row) {
    return PhotoModel(
      id: row['id'] as String,
      visitId: row['visit_id'] as String,
      formFieldId: row['form_field_id'] as String?,
      localPath: row['local_path'] as String,
      caption: row['caption'] as String?,
      syncStatus: row['sync_status'] as String? ?? 'local',
      storagePath: row['storage_path'] as String?,
      storageUrl: row['storage_url'] as String?,
      fileSizeBytes: row['file_size_bytes'] as int?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      capturedAt: row['captured_at'] as String,
      uploadedAt: row['uploaded_at'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'visit_id': visitId,
        'form_field_id': formFieldId,
        'local_path': localPath,
        'caption': caption,
        'sync_status': syncStatus,
        'storage_path': storagePath,
        'storage_url': storageUrl,
        'file_size_bytes': fileSizeBytes,
        'width': width,
        'height': height,
        'captured_at': capturedAt,
        'uploaded_at': uploadedAt,
      };

  VisitPhoto toEntity() {
    return VisitPhoto(
      id: id,
      visitId: visitId,
      formFieldId: formFieldId,
      localPath: localPath,
      caption: caption,
      syncStatus: PhotoSyncStatus.fromString(syncStatus),
      storagePath: storagePath,
      storageUrl: storageUrl,
      fileSizeBytes: fileSizeBytes,
      width: width,
      height: height,
      capturedAt: DateTime.parse(capturedAt),
      uploadedAt: uploadedAt != null ? DateTime.tryParse(uploadedAt!) : null,
    );
  }

  factory PhotoModel.fromEntity(VisitPhoto entity) {
    return PhotoModel(
      id: entity.id,
      visitId: entity.visitId,
      formFieldId: entity.formFieldId,
      localPath: entity.localPath,
      caption: entity.caption,
      syncStatus: entity.syncStatus.name,
      storagePath: entity.storagePath,
      storageUrl: entity.storageUrl,
      fileSizeBytes: entity.fileSizeBytes,
      width: entity.width,
      height: entity.height,
      capturedAt: entity.capturedAt.toUtc().toIso8601String(),
      uploadedAt: entity.uploadedAt?.toUtc().toIso8601String(),
    );
  }
}
