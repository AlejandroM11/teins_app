import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de elemento de anotación en el canvas.
enum AnnotationElementType {
  freeStroke,   // Trazo libre (pencil)
  line,         // Línea recta
  arrow,        // Flecha
  rectangle,    // Rectángulo
  circle,       // Círculo
  text,         // Texto / etiqueta
  marker,       // Marcador de punto
  eraser;       // Borrador

  static AnnotationElementType fromString(String value) {
    return AnnotationElementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnnotationElementType.freeStroke,
    );
  }
}

/// Un punto en el canvas con coordenadas normalizadas (0.0 – 1.0).
/// Normalizar coordenadas permite que las anotaciones sean
/// independientes del tamaño de pantalla.
class CanvasPoint extends Equatable {
  const CanvasPoint(this.x, this.y);

  final double x;
  final double y;

  Offset toOffset(Size canvasSize) =>
      Offset(x * canvasSize.width, y * canvasSize.height);

  static CanvasPoint fromOffset(Offset offset, Size canvasSize) => CanvasPoint(
        offset.dx / canvasSize.width,
        offset.dy / canvasSize.height,
      );

  Map<String, double> toMap() => {'x': x, 'y': y};

  factory CanvasPoint.fromMap(Map<String, dynamic> map) =>
      CanvasPoint((map['x'] as num).toDouble(), (map['y'] as num).toDouble());

  @override
  List<Object?> get props => [x, y];
}

/// Entidad de dominio: Elemento individual de una anotación.
///
/// Cada trazo, línea, texto o marcador es un elemento separado.
/// Esto permite edición no destructiva y serialización eficiente.
class AnnotationElement extends Equatable {
  const AnnotationElement({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
    this.text,
    this.fontSize,
    this.opacity = 1.0,
  });

  final String id;
  final AnnotationElementType type;
  final List<CanvasPoint> points;
  final Color color;
  final double strokeWidth;
  final String? text;       // Para elementos de tipo texto
  final double? fontSize;
  final double opacity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'points': points.map((p) => p.toMap()).toList(),
        'color': color.value,
        'strokeWidth': strokeWidth,
        'text': text,
        'fontSize': fontSize,
        'opacity': opacity,
      };

  factory AnnotationElement.fromMap(Map<String, dynamic> map) =>
      AnnotationElement(
        id: map['id'] as String,
        type: AnnotationElementType.fromString(map['type'] as String),
        points: (map['points'] as List)
            .map((p) => CanvasPoint.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        color: Color(map['color'] as int),
        strokeWidth: (map['strokeWidth'] as num).toDouble(),
        text: map['text'] as String?,
        fontSize: (map['fontSize'] as num?)?.toDouble(),
        opacity: (map['opacity'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [id, type, color, strokeWidth];
}

/// Entidad de dominio: Anotación completa de una visita.
///
/// Contiene todos los elementos dibujados sobre el canvas de esa visita.
/// La imagen base (si existe) se referencia por URL, no se embebe.
class VisitAnnotation extends Equatable {
  const VisitAnnotation({
    required this.id,
    required this.visitId,
    required this.elements,
    required this.createdAt,
    required this.syncStatus,
    this.title,
    this.baseImagePath,
    this.canvasWidth,
    this.canvasHeight,
    this.updatedAt,
  });

  final String id;
  final String visitId;
  final String? title;
  final List<AnnotationElement> elements;
  /// Imagen base opcional (plano, foto, cuadrícula).
  final String? baseImagePath;
  /// Dimensiones de referencia del canvas (para normalización).
  final double? canvasWidth;
  final double? canvasHeight;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  bool get isEmpty => elements.isEmpty;

  VisitAnnotation copyWith({
    String? title,
    List<AnnotationElement>? elements,
    String? baseImagePath,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return VisitAnnotation(
      id: id,
      visitId: visitId,
      title: title ?? this.title,
      elements: elements ?? this.elements,
      baseImagePath: baseImagePath ?? this.baseImagePath,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, visitId, createdAt];
}
