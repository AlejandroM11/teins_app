import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/annotation.dart';

class AnnotationModel {
  const AnnotationModel({
    required this.id,
    required this.visitId,
    required this.elementsJson,
    required this.syncStatus,
    required this.createdAt,
    this.title,
    this.baseImagePath,
    this.canvasWidth,
    this.canvasHeight,
    this.updatedAt,
  });

  final String id;
  final String visitId;
  final String? title;
  final String elementsJson;
  final String? baseImagePath;
  final double? canvasWidth;
  final double? canvasHeight;
  final String syncStatus;
  final String createdAt;
  final String? updatedAt;

  factory AnnotationModel.fromRow(Map<String, dynamic> row) {
    return AnnotationModel(
      id: row['id'] as String,
      visitId: row['visit_id'] as String,
      title: row['title'] as String?,
      elementsJson: row['elements_json'] as String? ?? '[]',
      baseImagePath: row['base_image_path'] as String?,
      canvasWidth: (row['canvas_width'] as num?)?.toDouble(),
      canvasHeight: (row['canvas_height'] as num?)?.toDouble(),
      syncStatus: row['sync_status'] as String? ?? 'local',
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'visit_id': visitId,
        'title': title,
        'elements_json': elementsJson,
        'base_image_path': baseImagePath,
        'canvas_width': canvasWidth,
        'canvas_height': canvasHeight,
        'sync_status': syncStatus,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  VisitAnnotation toEntity() {
    final elementsRaw = jsonDecode(elementsJson) as List<dynamic>;
    final elements = elementsRaw
        .map((e) => AnnotationElement.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    return VisitAnnotation(
      id: id,
      visitId: visitId,
      title: title,
      elements: elements,
      baseImagePath: baseImagePath,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      syncStatus: syncStatus,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
    );
  }

  factory AnnotationModel.fromEntity(VisitAnnotation entity) {
    final elementsJson = jsonEncode(
      entity.elements.map((e) => e.toMap()).toList(),
    );
    return AnnotationModel(
      id: entity.id,
      visitId: entity.visitId,
      title: entity.title,
      elementsJson: elementsJson,
      baseImagePath: entity.baseImagePath,
      canvasWidth: entity.canvasWidth,
      canvasHeight: entity.canvasHeight,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt?.toUtc().toIso8601String(),
    );
  }
}
