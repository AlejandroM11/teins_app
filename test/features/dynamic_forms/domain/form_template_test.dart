import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/features/dynamic_forms/data/models/form_models.dart';
import 'package:teins_app/features/dynamic_forms/domain/entities/form_template.dart';

void main() {
  group('FormTemplate', () {
    late FormTemplate template;

    setUp(() {
      template = const FormTemplate(
        id: 'energia_v1',
        name: 'Inspección de Energía',
        visitType: 'energia',
        version: 1,
        sections: [
          FormSection(
            id: 'instalacion',
            title: 'Datos de la Instalación',
            order: 0,
            fields: [
              FormFieldDefinition(
                id: 'voltaje',
                type: FormFieldType.decimal,
                label: 'Voltaje de entrada (V)',
                required: true,
              ),
              FormFieldDefinition(
                id: 'tipo_instalacion',
                type: FormFieldType.select,
                label: 'Tipo de instalación',
                required: true,
                options: ['Residencial', 'Comercial', 'Industrial'],
              ),
            ],
          ),
          FormSection(
            id: 'observaciones',
            title: 'Observaciones',
            order: 1,
            fields: [
              FormFieldDefinition(
                id: 'notas',
                type: FormFieldType.textarea,
                label: 'Notas adicionales',
                required: false,
              ),
            ],
          ),
        ],
      );
    });

    group('allFields', () {
      test('returns all fields from all sections', () {
        expect(template.allFields.length, 3);
      });

      test('fields are in section order', () {
        final ids = template.allFields.map((f) => f.id).toList();
        expect(ids, ['voltaje', 'tipo_instalacion', 'notas']);
      });
    });

    group('totalRequiredFields', () {
      test('counts only required fields', () {
        expect(template.totalRequiredFields, 2);
      });
    });

    group('FormFieldType', () {
      test('fromString parses known types correctly', () {
        expect(FormFieldType.fromString('text'), FormFieldType.text);
        expect(FormFieldType.fromString('decimal'), FormFieldType.decimal);
        expect(FormFieldType.fromString('select'), FormFieldType.select);
        expect(FormFieldType.fromString('boolean'), FormFieldType.boolean);
        expect(FormFieldType.fromString('textarea'), FormFieldType.textarea);
        expect(FormFieldType.fromString('number'), FormFieldType.number);
        expect(FormFieldType.fromString('date'), FormFieldType.date);
        expect(FormFieldType.fromString('photo'), FormFieldType.photo);
      });

      test('fromString falls back to text for unknown', () {
        expect(FormFieldType.fromString('unknown_type'), FormFieldType.text);
      });
    });
  });

  group('FormResponseModel serialization', () {
    final now = DateTime.utc(2025, 3, 10, 8, 30);
    final responses = {'voltaje': 220.0, 'tipo_instalacion': 'Industrial'};

    late FormResponseModel model;

    setUp(() {
      model = FormResponseModel(
        id: 'response-001',
        visitId: 'visit-001',
        templateId: 'energia_v1',
        templateVersion: 1,
        responsesJson: jsonEncode(responses),
        syncStatus: 'local',
        createdAt: now.toIso8601String(),
      );
    });

    test('toEntity decodes responses JSON correctly', () {
      final entity = model.toEntity();
      expect(entity.responses['voltaje'], 220.0);
      expect(entity.responses['tipo_instalacion'], 'Industrial');
      expect(entity.isComplete, isFalse);
    });

    test('fromEntity encodes responses back to JSON', () {
      final entity = model.toEntity();
      final roundTripped = FormResponseModel.fromEntity(entity);
      final decoded = jsonDecode(roundTripped.responsesJson) as Map;
      expect(decoded['voltaje'], 220.0);
      expect(decoded['tipo_instalacion'], 'Industrial');
    });

    test('isComplete flag is preserved in round-trip', () {
      final completedModel = FormResponseModel(
        id: 'response-002',
        visitId: 'visit-002',
        templateId: 'energia_v1',
        templateVersion: 1,
        responsesJson: '{}',
        syncStatus: 'pendingSync',
        isComplete: 1,
        createdAt: now.toIso8601String(),
      );
      final entity = completedModel.toEntity();
      expect(entity.isComplete, isTrue);
    });

    test('fromRow creates model correctly from SQLite row', () {
      final row = <String, dynamic>{
        'id': 'response-001',
        'visit_id': 'visit-001',
        'template_id': 'energia_v1',
        'template_version': 1,
        'responses_json': jsonEncode(responses),
        'sync_status': 'pendingSync',
        'is_complete': 0,
        'created_at': now.toIso8601String(),
        'updated_at': null,
        'completed_at': null,
      };
      final fromRow = FormResponseModel.fromRow(row);
      expect(fromRow.id, 'response-001');
      expect(fromRow.syncStatus, 'pendingSync');
      expect(fromRow.isComplete, 0);
    });

    test('empty responsesJson defaults to empty map', () {
      final row = <String, dynamic>{
        'id': 'r-001',
        'visit_id': 'v-001',
        'template_id': 't-001',
        'template_version': 1,
        'responses_json': null,
        'sync_status': 'local',
        'is_complete': 0,
        'created_at': now.toIso8601String(),
        'updated_at': null,
        'completed_at': null,
      };
      final m = FormResponseModel.fromRow(row);
      final entity = m.toEntity();
      expect(entity.responses, isEmpty);
    });
  });

  group('FormTemplateModel', () {
    const sampleJson = {
      'id': 'infraestructura_v1',
      'name': 'Inspección de Infraestructura',
      'visit_type': 'infraestructura',
      'version': 1,
      'sections': [
        {
          'id': 'general',
          'title': 'Información General',
          'order': 0,
          'fields': [
            {
              'id': 'ubicacion',
              'type': 'text',
              'label': 'Ubicación exacta',
              'required': true,
            },
            {
              'id': 'condicion',
              'type': 'select',
              'label': 'Condición del sitio',
              'required': true,
              'options': ['Bueno', 'Regular', 'Deficiente'],
            },
          ],
        },
      ],
    };

    test('fromJson parses sections and fields correctly', () {
      final model = FormTemplateModel.fromJson(
        Map<String, dynamic>.from(sampleJson),
      );
      final entity = model.toEntity();

      expect(entity.id, 'infraestructura_v1');
      expect(entity.sections.length, 1);
      expect(entity.sections[0].fields.length, 2);
      expect(entity.sections[0].fields[0].required, isTrue);
      expect(entity.sections[0].fields[1].options, ['Bueno', 'Regular', 'Deficiente']);
    });

    test('round-trip: fromJson → toEntity → toRow → fromRow → toEntity', () {
      final model = FormTemplateModel.fromJson(
        Map<String, dynamic>.from(sampleJson),
      );
      final entity1 = model.toEntity();

      // Simular guardado y lectura desde SQLite
      final row = model.toRow();
      final restoredModel = FormTemplateModel.fromRow(row);
      final entity2 = restoredModel.toEntity();

      expect(entity2.id, entity1.id);
      expect(entity2.sections.length, entity1.sections.length);
      expect(entity2.allFields.length, entity1.allFields.length);
    });
  });
}
