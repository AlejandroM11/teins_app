import '../../domain/entities/visit.dart';

/// Modelo de datos para la capa de datos.
///
/// Maneja la serialización/deserialización desde/hacia SQLite (PowerSync).
/// La conversión a entidad de dominio garantiza que el dominio
/// no depende del formato de almacenamiento.
class VisitModel {
  const VisitModel({
    required this.id,
    required this.technicianId,
    required this.title,
    required this.visitType,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    this.clientId,
    this.clientName,
    this.address,
    this.description,
    this.observations,
    this.formTemplateId,
    this.formTemplateVersion,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String technicianId;
  final String? clientId;
  final String? clientName;
  final String title;
  final String? description;
  final String visitType;
  final String? address;
  final String status;
  final String syncStatus;
  final String? formTemplateId;
  final int? formTemplateVersion;
  final String? observations;
  final String createdAt;
  final String? updatedAt;
  final String? startedAt;
  final String? completedAt;
  final double? latitude;
  final double? longitude;

  /// Construye un VisitModel desde una fila de SQLite/PowerSync.
  factory VisitModel.fromRow(Map<String, dynamic> row) {
    return VisitModel(
      id: row['id'] as String,
      technicianId: row['technician_id'] as String,
      clientId: row['client_id'] as String?,
      clientName: row['client_name'] as String?,
      title: row['title'] as String,
      description: row['description'] as String?,
      visitType: row['visit_type'] as String,
      address: row['address'] as String?,
      status: row['status'] as String,
      syncStatus: row['sync_status'] as String? ?? 'local',
      formTemplateId: row['form_template_id'] as String?,
      formTemplateVersion: row['form_template_version'] as int?,
      observations: row['observations'] as String?,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String?,
      startedAt: row['started_at'] as String?,
      completedAt: row['completed_at'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
    );
  }

  /// Convierte a Map para insertar/actualizar en SQLite.
  Map<String, dynamic> toRow() => {
        'id': id,
        'technician_id': technicianId,
        'client_id': clientId,
        'client_name': clientName,
        'title': title,
        'description': description,
        'visit_type': visitType,
        'address': address,
        'status': status,
        'sync_status': syncStatus,
        'form_template_id': formTemplateId,
        'form_template_version': formTemplateVersion,
        'observations': observations,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'started_at': startedAt,
        'completed_at': completedAt,
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Convierte a entidad de dominio.
  Visit toEntity() {
    return Visit(
      id: id,
      technicianId: technicianId,
      clientId: clientId,
      clientName: clientName,
      title: title,
      description: description,
      visitType: visitType,
      address: address,
      status: VisitStatus.fromString(status),
      syncStatus: SyncStatus.fromString(syncStatus),
      formTemplateId: formTemplateId,
      formTemplateVersion: formTemplateVersion,
      observations: observations,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      startedAt: startedAt != null ? DateTime.tryParse(startedAt!) : null,
      completedAt:
          completedAt != null ? DateTime.tryParse(completedAt!) : null,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Construye un VisitModel desde la entidad de dominio.
  factory VisitModel.fromEntity(Visit entity) {
    return VisitModel(
      id: entity.id,
      technicianId: entity.technicianId,
      clientId: entity.clientId,
      clientName: entity.clientName,
      title: entity.title,
      description: entity.description,
      visitType: entity.visitType,
      address: entity.address,
      status: entity.status.name,
      syncStatus: entity.syncStatus.name,
      formTemplateId: entity.formTemplateId,
      formTemplateVersion: entity.formTemplateVersion,
      observations: entity.observations,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt?.toUtc().toIso8601String(),
      startedAt: entity.startedAt?.toUtc().toIso8601String(),
      completedAt: entity.completedAt?.toUtc().toIso8601String(),
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
