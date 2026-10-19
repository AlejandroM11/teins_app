import '../../domain/entities/material.dart';

class CatalogMaterialModel {
  const CatalogMaterialModel({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.description,
    this.category,
    this.isActive = 1,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String unit;
  final String? category;
  final int isActive;

  factory CatalogMaterialModel.fromRow(Map<String, dynamic> row) {
    return CatalogMaterialModel(
      id: row['id'] as String,
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      unit: row['unit'] as String,
      category: row['category'] as String?,
      isActive: row['is_active'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'unit': unit,
        'category': category,
        'is_active': isActive,
      };

  CatalogMaterial toEntity() {
    return CatalogMaterial(
      id: id,
      code: code,
      name: name,
      description: description,
      unit: unit,
      category: category,
      isActive: isActive == 1,
    );
  }
}

class VisitMaterialModel {
  const VisitMaterialModel({
    required this.id,
    required this.visitId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.syncStatus,
    required this.createdAt,
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
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  factory VisitMaterialModel.fromRow(Map<String, dynamic> row) {
    return VisitMaterialModel(
      id: row['id'] as String,
      visitId: row['visit_id'] as String,
      materialId: row['material_id'] as String,
      materialCode: row['material_code'] as String,
      materialName: row['material_name'] as String,
      unit: row['unit'] as String,
      quantity: (row['quantity'] as num).toDouble(),
      observations: row['observations'] as String?,
      syncStatus: row['sync_status'] as String? ?? 'local',
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'visit_id': visitId,
        'material_id': materialId,
        'material_code': materialCode,
        'material_name': materialName,
        'unit': unit,
        'quantity': quantity,
        'observations': observations,
        'sync_status': syncStatus,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  VisitMaterial toEntity() {
    return VisitMaterial(
      id: id,
      visitId: visitId,
      materialId: materialId,
      materialCode: materialCode,
      materialName: materialName,
      unit: unit,
      quantity: quantity,
      observations: observations,
      syncStatus: syncStatus,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    );
  }

  factory VisitMaterialModel.fromEntity(VisitMaterial entity) {
    return VisitMaterialModel(
      id: entity.id,
      visitId: entity.visitId,
      materialId: entity.materialId,
      materialCode: entity.materialCode,
      materialName: entity.materialName,
      unit: entity.unit,
      quantity: entity.quantity,
      observations: entity.observations,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt?.toUtc().toIso8601String(),
    );
  }
}
