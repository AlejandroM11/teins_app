import 'package:equatable/equatable.dart';

/// Tipos de campo soportados por el motor de formularios dinámicos.
enum FormFieldType {
  text,
  textarea,
  number,
  decimal,
  select,
  multiSelect,
  boolean,
  date,
  time,
  photo,
  measure,
  materials;

  static FormFieldType fromString(String value) {
    return FormFieldType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormFieldType.text,
    );
  }
}

/// Entidad de dominio: Definición de un campo de formulario.
class FormFieldDefinition extends Equatable {
  const FormFieldDefinition({
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.required = false,
    this.options = const [],
    this.unit,
    this.minValue,
    this.maxValue,
    this.defaultValue,
  });

  final String id;
  final FormFieldType type;
  final String label;
  final String? hint;
  final bool required;
  final List<String> options;   // Para campos select/multiSelect
  final String? unit;           // Para campos de medida
  final double? minValue;
  final double? maxValue;
  final dynamic defaultValue;

  @override
  List<Object?> get props => [id, type, label, required];
}

/// Entidad de dominio: Sección de un formulario.
class FormSection extends Equatable {
  const FormSection({
    required this.id,
    required this.title,
    required this.order,
    required this.fields,
  });

  final String id;
  final String title;
  final int order;
  final List<FormFieldDefinition> fields;

  @override
  List<Object?> get props => [id, title, order];
}

/// Entidad de dominio: Plantilla de formulario.
///
/// El versionado es crítico: cuando una visita inicia, se guarda
/// la versión de la plantilla usada. Actualizaciones futuras
/// no destruyen formularios ya completados.
class FormTemplate extends Equatable {
  const FormTemplate({
    required this.id,
    required this.name,
    required this.visitType,
    required this.version,
    required this.sections,
  });

  final String id;
  final String name;
  final String visitType;
  final int version;
  final List<FormSection> sections;

  List<FormFieldDefinition> get allFields =>
      sections.expand((s) => s.fields).toList();

  int get totalRequiredFields =>
      allFields.where((f) => f.required).length;

  @override
  List<Object?> get props => [id, version, visitType];
}

/// Entidad de dominio: Respuesta a un formulario.
///
/// Almacena las respuestas como Map para flexibilidad,
/// pero el motor de formularios valida los tipos.
class FormResponse extends Equatable {
  const FormResponse({
    required this.id,
    required this.visitId,
    required this.templateId,
    required this.templateVersion,
    required this.responses,
    required this.createdAt,
    required this.syncStatus,
    this.updatedAt,
    this.completedAt,
    this.isComplete = false,
  });

  final String id;
  final String visitId;
  final String templateId;
  final int templateVersion;
  /// Map<fieldId, value> — el valor puede ser String, num, bool, List<String>
  final Map<String, dynamic> responses;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final bool isComplete;
  final String syncStatus;

  FormResponse copyWith({
    Map<String, dynamic>? responses,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? isComplete,
    String? syncStatus,
  }) {
    return FormResponse(
      id: id,
      visitId: visitId,
      templateId: templateId,
      templateVersion: templateVersion,
      responses: responses ?? this.responses,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      isComplete: isComplete ?? this.isComplete,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, visitId, templateId, templateVersion];
}
