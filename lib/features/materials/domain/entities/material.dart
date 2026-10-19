import 'package:equatable/equatable.dart';

/// Entidad de dominio: Material del catálogo.
///
/// Un material es un ítem del catálogo maestro.
/// [VisitMaterial] representa el uso de ese material en una visita.
class CatalogMaterial extends Equatable {
  const CatalogMaterial({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.description,
    this.category,
    this.isActive = true,
  });

  final String id;
  final String code;       // SKU / código interno
  final String name;
  final String? description;
  final String unit;       // 'm', 'unidad', 'kg', etc.
  final String? category;
  final bool isActive;

  @override
  List<Object?> get props => [id, code];
}

/// Entidad de dominio: Material usado en una visita específica.
///
/// Relaciona un [CatalogMaterial] con una visita, con cantidad
/// y observaciones específicas de ese uso.
class VisitMaterial extends Equatable {
  const VisitMaterial({
    required this.id,
    required this.visitId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.createdAt,
    required this.syncStatus,
    this.observations,
    this.updatedAt,
  });

  final String id;
  final String visitId;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unit;
  final double quantity;
  final String? observations;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  VisitMaterial copyWith({
    double? quantity,
    String? observations,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return VisitMaterial(
      id: id,
      visitId: visitId,
      materialId: materialId,
      materialCode: materialCode,
      materialName: materialName,
      unit: unit,
      quantity: quantity ?? this.quantity,
      observations: observations ?? this.observations,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, visitId, materialId];
}
