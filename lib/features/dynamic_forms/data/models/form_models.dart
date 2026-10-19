import 'dart:convert';
import '../../domain/entities/form_template.dart';

/// Modelos de datos para formularios — serialización desde/hacia SQLite.
class FormTemplateModel {
  const FormTemplateModel({
    required this.id,
    required this.name,
    required this.visitType,
    required this.version,
    required this.sectionsJson,
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String visitType;
  final int version;
  final String sectionsJson;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;

  factory FormTemplateModel.fromRow(Map<String, dynamic> row) {
    return FormTemplateModel(
      id: row['id'] as String,
      name: row['name'] as String,
      visitType: row['visit_type'] as String,
      version: row['version'] as int,
      sectionsJson: row['sections_json'] as String,
      isActive: row['is_active'] as int? ?? 1,
      createdAt: row['created_at'] as String?,
      updatedAt: row['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'visit_type': visitType,
        'version': version,
        'sections_json': sectionsJson,
        'is_active': isActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  FormTemplate toEntity() {
    final sectionsRaw =
        jsonDecode(sectionsJson) as List<dynamic>;
    final sections = sectionsRaw
        .map((s) => _parseSectionFromJson(s as Map<String, dynamic>))
        .toList();
    return FormTemplate(
      id: id,
      name: name,
      visitType: visitType,
      version: version,
      sections: sections,
    );
  }

  factory FormTemplateModel.fromJson(Map<String, dynamic> json) {
    return FormTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      visitType: json['visit_type'] as String,
      version: json['version'] as int,
      sectionsJson: jsonEncode(json['sections']),
    );
  }

  static FormSection _parseSectionFromJson(Map<String, dynamic> s) {
    final fields = (s['fields'] as List<dynamic>)
        .map((f) => _parseFieldFromJson(f as Map<String, dynamic>))
        .toList();
    return FormSection(
      id: s['id'] as String,
      title: s['title'] as String,
      order: s['order'] as int,
      fields: fields,
    );
  }

  static FormFieldDefinition _parseFieldFromJson(Map<String, dynamic> f) {
    final optionsRaw = f['options'];
    final options = optionsRaw is List
        ? optionsRaw.map((o) => o.toString()).toList()
        : <String>[];
    return FormFieldDefinition(
      id: f['id'] as String,
      type: FormFieldType.fromString(f['type'] as String),
      label: f['label'] as String,
      hint: f['hint'] as String?,
      required: (f['required'] as bool?) ?? false,
      options: options,
      unit: f['unit'] as String?,
    );
  }
}

class FormResponseModel {
  const FormResponseModel({
    required this.id,
    required this.visitId,
    required this.templateId,
    required this.templateVersion,
    required this.responsesJson,
    required this.syncStatus,
    required this.createdAt,
    this.isComplete = 0,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String visitId;
  final String templateId;
  final int templateVersion;
  final String responsesJson;
  final String syncStatus;
  final int isComplete;
  final String createdAt;
  final String? updatedAt;
  final String? completedAt;

  factory FormResponseModel.fromRow(Map<String, dynamic> row) {
    return FormResponseModel(
      id: row['id'] as String,
      visitId: row['visit_id'] as String,
      templateId: row['template_id'] as String,
      templateVersion: row['template_version'] as int,
      responsesJson: row['responses_json'] as String? ?? '{}',
      syncStatus: row['sync_status'] as String? ?? 'local',
      isComplete: row['is_complete'] as int? ?? 0,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String?,
      completedAt: row['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'visit_id': visitId,
        'template_id': templateId,
        'template_version': templateVersion,
        'responses_json': responsesJson,
        'sync_status': syncStatus,
        'is_complete': isComplete,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'completed_at': completedAt,
      };

  FormResponse toEntity() {
    return FormResponse(
      id: id,
      visitId: visitId,
      templateId: templateId,
      templateVersion: templateVersion,
      responses: Map<String, dynamic>.from(
        jsonDecode(responsesJson) as Map,
      ),
      syncStatus: syncStatus,
      isComplete: isComplete == 1,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      completedAt:
          completedAt != null ? DateTime.tryParse(completedAt!) : null,
    );
  }

  factory FormResponseModel.fromEntity(FormResponse entity) {
    return FormResponseModel(
      id: entity.id,
      visitId: entity.visitId,
      templateId: entity.templateId,
      templateVersion: entity.templateVersion,
      responsesJson: jsonEncode(entity.responses),
      syncStatus: entity.syncStatus,
      isComplete: entity.isComplete ? 1 : 0,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt?.toUtc().toIso8601String(),
      completedAt: entity.completedAt?.toUtc().toIso8601String(),
    );
  }
}
