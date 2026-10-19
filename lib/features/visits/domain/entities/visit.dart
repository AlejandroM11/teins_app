import 'package:equatable/equatable.dart';

/// Estado de negocio de la visita.
/// Separado deliberadamente del [SyncStatus] para no mezclar
/// estado de negocio con estado de sincronización.
enum VisitStatus {
  assigned,
  inProgress,
  completed,
  pendingReview,
  synced;

  static VisitStatus fromString(String value) {
    return VisitStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VisitStatus.assigned,
    );
  }

  String get displayName {
    switch (this) {
      case VisitStatus.assigned:
        return 'Asignada';
      case VisitStatus.inProgress:
        return 'En progreso';
      case VisitStatus.completed:
        return 'Completada';
      case VisitStatus.pendingReview:
        return 'En revisión';
      case VisitStatus.synced:
        return 'Sincronizada';
    }
  }

  bool canTransitionTo(VisitStatus next) {
    switch (this) {
      case VisitStatus.assigned:
        return next == VisitStatus.inProgress;
      case VisitStatus.inProgress:
        return next == VisitStatus.completed;
      case VisitStatus.completed:
        return next == VisitStatus.pendingReview || next == VisitStatus.synced;
      case VisitStatus.pendingReview:
        return next == VisitStatus.synced;
      case VisitStatus.synced:
        return false;
    }
  }
}

/// Estado de sincronización de cualquier entidad.
/// Independiente del estado de negocio.
enum SyncStatus {
  local,
  pendingSync,
  syncing,
  synced,
  syncError,
  conflict;

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.local,
    );
  }
}

/// Entidad de dominio: Visita técnica.
///
/// Representa el núcleo del negocio TEINS.
/// No tiene dependencias de Flutter, Supabase ni PowerSync.
class Visit extends Equatable {
  const Visit({
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
  final String visitType;          // 'infraestructura' | 'energia' | 'datos'
  final String? address;
  final VisitStatus status;
  final SyncStatus syncStatus;
  final String? formTemplateId;
  final int? formTemplateVersion;
  final String? observations;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? latitude;
  final double? longitude;

  /// Transiciona el estado con validación de la máquina de estados.
  /// Lanza [ArgumentError] si la transición no está permitida.
  Visit transitionTo(VisitStatus newStatus) {
    if (!status.canTransitionTo(newStatus)) {
      throw ArgumentError(
        'Transición inválida: ${status.name} → ${newStatus.name}',
      );
    }
    return copyWith(
      status: newStatus,
      startedAt: newStatus == VisitStatus.inProgress
          ? (startedAt ?? DateTime.now())
          : startedAt,
      completedAt:
          newStatus == VisitStatus.completed ? DateTime.now() : completedAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingSync,
    );
  }

  bool get isEditable =>
      status == VisitStatus.assigned || status == VisitStatus.inProgress;

  bool get hasPendingSync =>
      syncStatus == SyncStatus.pendingSync ||
      syncStatus == SyncStatus.local ||
      syncStatus == SyncStatus.syncError;

  Visit copyWith({
    String? id,
    String? technicianId,
    String? clientId,
    String? clientName,
    String? title,
    String? description,
    String? visitType,
    String? address,
    VisitStatus? status,
    SyncStatus? syncStatus,
    String? formTemplateId,
    int? formTemplateVersion,
    String? observations,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? latitude,
    double? longitude,
  }) {
    return Visit(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      title: title ?? this.title,
      description: description ?? this.description,
      visitType: visitType ?? this.visitType,
      address: address ?? this.address,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      formTemplateId: formTemplateId ?? this.formTemplateId,
      formTemplateVersion: formTemplateVersion ?? this.formTemplateVersion,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        technicianId,
        clientId,
        title,
        visitType,
        status,
        syncStatus,
        formTemplateId,
        formTemplateVersion,
        createdAt,
        updatedAt,
      ];
}
