import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teins_app/features/annotations/data/models/annotation_model.dart';
import 'package:teins_app/features/annotations/domain/entities/annotation.dart';

void main() {
  group('CanvasPoint', () {
    test('normalizes coordinates between 0 and 1', () {
      const point = CanvasPoint(0.5, 0.75);
      expect(point.x, 0.5);
      expect(point.y, 0.75);
    });

    test('toOffset scales to canvas size', () {
      const point = CanvasPoint(0.5, 0.5);
      const size = Size(400, 800);
      final offset = point.toOffset(size);
      expect(offset.dx, 200.0);
      expect(offset.dy, 400.0);
    });

    test('fromOffset normalizes correctly', () {
      const size = Size(400, 800);
      final offset = const Offset(100, 200);
      final point = CanvasPoint.fromOffset(offset, size);
      expect(point.x, 0.25);
      expect(point.y, 0.25);
    });

    test('toMap and fromMap round-trip', () {
      const original = CanvasPoint(0.3, 0.7);
      final map = original.toMap();
      final restored = CanvasPoint.fromMap(map);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
    });

    test('equality works correctly', () {
      const a = CanvasPoint(0.1, 0.2);
      const b = CanvasPoint(0.1, 0.2);
      const c = CanvasPoint(0.3, 0.4);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('AnnotationElement', () {
    final element = AnnotationElement(
      id: 'el-001',
      type: AnnotationElementType.freeStroke,
      points: const [CanvasPoint(0.1, 0.1), CanvasPoint(0.5, 0.5)],
      color: Colors.red,
      strokeWidth: 3.0,
    );

    test('toMap encodes all fields', () {
      final map = element.toMap();
      expect(map['id'], 'el-001');
      expect(map['type'], 'freeStroke');
      expect(map['color'], Colors.red.value);
      expect(map['strokeWidth'], 3.0);
      expect((map['points'] as List).length, 2);
    });

    test('fromMap round-trip preserves data', () {
      final map = element.toMap();
      final restored = AnnotationElement.fromMap(map);
      expect(restored.id, element.id);
      expect(restored.type, element.type);
      expect(restored.color, element.color);
      expect(restored.strokeWidth, element.strokeWidth);
      expect(restored.points.length, element.points.length);
    });

    test('text element includes text field', () {
      final textEl = AnnotationElement(
        id: 'el-txt',
        type: AnnotationElementType.text,
        points: const [CanvasPoint(0.2, 0.3)],
        color: Colors.blue,
        strokeWidth: 2.0,
        text: 'Panel eléctrico',
        fontSize: 14.0,
      );
      final map = textEl.toMap();
      expect(map['text'], 'Panel eléctrico');
      expect(map['fontSize'], 14.0);
    });
  });

  group('AnnotationElementType', () {
    test('fromString parses all types', () {
      expect(
        AnnotationElementType.fromString('freeStroke'),
        AnnotationElementType.freeStroke,
      );
      expect(
        AnnotationElementType.fromString('line'),
        AnnotationElementType.line,
      );
      expect(
        AnnotationElementType.fromString('arrow'),
        AnnotationElementType.arrow,
      );
      expect(
        AnnotationElementType.fromString('text'),
        AnnotationElementType.text,
      );
    });

    test('fromString defaults to freeStroke for unknown', () {
      expect(
        AnnotationElementType.fromString('unknown'),
        AnnotationElementType.freeStroke,
      );
    });
  });

  group('VisitAnnotation', () {
    final annotation = VisitAnnotation(
      id: 'ann-001',
      visitId: 'visit-001',
      elements: [
        AnnotationElement(
          id: 'el-001',
          type: AnnotationElementType.line,
          points: const [CanvasPoint(0.0, 0.0), CanvasPoint(1.0, 1.0)],
          color: Colors.black,
          strokeWidth: 2.0,
        ),
      ],
      syncStatus: 'local',
      createdAt: DateTime(2025, 1, 15),
    );

    test('isEmpty returns false when elements exist', () {
      expect(annotation.isEmpty, isFalse);
    });

    test('isEmpty returns true for no elements', () {
      final empty = annotation.copyWith(elements: []);
      expect(empty.isEmpty, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      final updated = annotation.copyWith(
        title: 'Plano principal',
        syncStatus: 'pendingSync',
      );
      expect(updated.id, annotation.id);
      expect(updated.visitId, annotation.visitId);
      expect(updated.elements.length, annotation.elements.length);
      expect(updated.title, 'Plano principal');
      expect(updated.syncStatus, 'pendingSync');
    });
  });

  group('AnnotationModel serialization', () {
    final element = AnnotationElement(
      id: 'el-001',
      type: AnnotationElementType.freeStroke,
      points: const [CanvasPoint(0.1, 0.2), CanvasPoint(0.3, 0.4)],
      color: Colors.red,
      strokeWidth: 3.0,
    );

    final annotation = VisitAnnotation(
      id: 'ann-001',
      visitId: 'visit-001',
      elements: [element],
      syncStatus: 'pendingSync',
      createdAt: DateTime.utc(2025, 2, 1),
    );

    test('fromEntity serializes elements to JSON string', () {
      final model = AnnotationModel.fromEntity(annotation);
      expect(model.id, 'ann-001');
      expect(model.visitId, 'visit-001');
      // elementsJson should be valid JSON array
      final decoded = jsonDecode(model.elementsJson) as List;
      expect(decoded.length, 1);
    });

    test('toEntity deserializes elements correctly', () {
      final model = AnnotationModel.fromEntity(annotation);
      final entity = model.toEntity();
      expect(entity.elements.length, 1);
      expect(entity.elements[0].type, AnnotationElementType.freeStroke);
      expect(entity.elements[0].color, Colors.red);
    });

    test('round-trip preserves all point coordinates', () {
      final model = AnnotationModel.fromEntity(annotation);
      final entity = model.toEntity();
      expect(entity.elements[0].points[0].x, closeTo(0.1, 0.001));
      expect(entity.elements[0].points[0].y, closeTo(0.2, 0.001));
      expect(entity.elements[0].points[1].x, closeTo(0.3, 0.001));
    });

    test('empty elements serialize and deserialize correctly', () {
      final empty = annotation.copyWith(elements: []);
      final model = AnnotationModel.fromEntity(empty);
      final entity = model.toEntity();
      expect(entity.elements, isEmpty);
    });

    test('fromRow creates model from SQLite row', () {
      final row = <String, dynamic>{
        'id': 'ann-001',
        'visit_id': 'visit-001',
        'title': null,
        'elements_json': '[]',
        'base_image_path': null,
        'canvas_width': 400.0,
        'canvas_height': 600.0,
        'sync_status': 'synced',
        'created_at': '2025-02-01T00:00:00.000Z',
        'updated_at': null,
      };
      final model = AnnotationModel.fromRow(row);
      expect(model.id, 'ann-001');
      expect(model.canvasWidth, 400.0);
      expect(model.syncStatus, 'synced');
    });
  });
}
