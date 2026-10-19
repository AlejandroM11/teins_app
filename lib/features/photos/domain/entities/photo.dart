import 'package:equatable/equatable.dart';

/// Estado de sincronización específico para fotografías.
enum PhotoSyncStatus {
  local,
  pendingUpload,
  uploading,
  uploaded,
  uploadError;

  static PhotoSyncStatus fromString(String value) {
    return PhotoSyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PhotoSyncStatus.local,
    );
  }
}

/// Entidad de dominio: Fotografía de visita.
///
/// REGLA CRÍTICA: [localPath] solo se elimina del disco cuando
/// [syncStatus] == [PhotoSyncStatus.uploaded] y está confirmado.
class VisitPhoto extends Equatable {
  const VisitPhoto({
    required this.id,
    required this.visitId,
    required this.localPath,
    required this.capturedAt,
    required this.syncStatus,
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
  final String localPath;
  final String? formFieldId;
  final String? caption;
  final DateTime capturedAt;
  final PhotoSyncStatus syncStatus;
  final String? storagePath;
  final String? storageUrl;
  final int? fileSizeBytes;
  final int? width;
  final int? height;
  final DateTime? uploadedAt;

  bool get isLocalOnly =>
      syncStatus == PhotoSyncStatus.local ||
      syncStatus == PhotoSyncStatus.pendingUpload ||
      syncStatus == PhotoSyncStatus.uploadError;

  bool get isUploaded => syncStatus == PhotoSyncStatus.uploaded;

  String get displayPath => storageUrl ?? localPath;

  VisitPhoto copyWith({
    String? caption,
    PhotoSyncStatus? syncStatus,
    String? storagePath,
    String? storageUrl,
    DateTime? uploadedAt,
  }) {
    return VisitPhoto(
      id: id,
      visitId: visitId,
      localPath: localPath,
      formFieldId: formFieldId,
      caption: caption ?? this.caption,
      capturedAt: capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      storagePath: storagePath ?? this.storagePath,
      storageUrl: storageUrl ?? this.storageUrl,
      fileSizeBytes: fileSizeBytes,
      width: width,
      height: height,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  List<Object?> get props => [id, visitId, localPath, syncStatus];
}
