import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../data/repositories/annotation_repository_impl.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';
import '../../domain/usecases/save_annotation.dart';

// ── Estado del editor de anotaciones ─────────────────────────────────────

class AnnotationEditorState {
  const AnnotationEditorState({
    this.annotation,
    this.activeTool = AnnotationElementType.freeStroke,
    this.activeColor = Colors.red,
    this.strokeWidth = 3.0,
    this.activeStroke,
    this.isSaving = false,
    this.lastSavedAt,
    this.canUndo = false,
  });

  final VisitAnnotation? annotation;
  final AnnotationElementType activeTool;
  final Color activeColor;
  final double strokeWidth;

  /// Trazo en construcción (aún no confirmado).
  final AnnotationElement? activeStroke;

  final bool isSaving;
  final DateTime? lastSavedAt;

  /// Indica si hay pasos en el historial disponibles para deshacer.
  final bool canUndo;

  List<AnnotationElement> get elements => annotation?.elements ?? const [];

  AnnotationEditorState copyWith({
    VisitAnnotation? annotation,
    AnnotationElementType? activeTool,
    Color? activeColor,
    double? strokeWidth,
    AnnotationElement? activeStroke,
    bool clearActiveStroke = false,
    bool? isSaving,
    DateTime? lastSavedAt,
    bool? canUndo,
  }) {
    return AnnotationEditorState(
      annotation: annotation ?? this.annotation,
      activeTool: activeTool ?? this.activeTool,
      activeColor: activeColor ?? this.activeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      activeStroke:
          clearActiveStroke ? null : (activeStroke ?? this.activeStroke),
      isSaving: isSaving ?? this.isSaving,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      canUndo: canUndo ?? this.canUndo,
    );
  }
}

/// Controller del canvas de anotaciones.
///
/// Gestiona:
/// - Herramientas activas (lápiz, línea, flecha, rectángulo, etc.)
/// - Construcción de trazos en tiempo real (onPanStart/Update/End)
/// - Deshacer (undo)
/// - Autosave debounced
/// - Persistencia en SQLite
class AnnotationEditorController
    extends StateNotifier<AnnotationEditorState> {
  AnnotationEditorController({required this.visitId})
      : _saveUseCase = sl<SaveAnnotation>(),
        _repo = sl<AnnotationRepository>() as AnnotationRepositoryImpl,
        super(const AnnotationEditorState());

  final String visitId;
  final SaveAnnotation _saveUseCase;
  final AnnotationRepositoryImpl _repo;

  Timer? _debounceTimer;

  // Historial para undo (máximo 20 pasos)
  final List<List<AnnotationElement>> _history = [];
  static const int _maxHistory = 20;

  /// Inicializa: carga anotación existente o crea una nueva.
  Future<void> initialize() async {
    final annotation = await _repo.getOrCreate(visitId);
    state = state.copyWith(annotation: annotation);
  }

  // ── Herramientas ─────────────────────────────────────────────────────────

  void setTool(AnnotationElementType tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setColor(Color color) {
    state = state.copyWith(activeColor: color);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  // ── Gestión de trazos ────────────────────────────────────────────────────

  /// Inicia un nuevo trazo en la posición normalizada [point].
  void onStrokeStart(CanvasPoint point) {
    final el = AnnotationElement(
      id: UuidGenerator.generate(),
      type: state.activeTool,
      points: [point],
      color: state.activeColor,
      strokeWidth: state.strokeWidth,
    );
    state = state.copyWith(activeStroke: el);
  }

  /// Añade un punto al trazo activo.
  void onStrokeUpdate(CanvasPoint point) {
    final active = state.activeStroke;
    if (active == null) return;

    final updated = AnnotationElement(
      id: active.id,
      type: active.type,
      points: [...active.points, point],
      color: active.color,
      strokeWidth: active.strokeWidth,
      text: active.text,
      fontSize: active.fontSize,
      opacity: active.opacity,
    );
    state = state.copyWith(activeStroke: updated);
  }

  /// Finaliza el trazo activo y lo añade al modelo permanente.
  void onStrokeEnd() {
    final active = state.activeStroke;
    if (active == null) return;

    // Ignorar trazos demasiado cortos (tap accidental)
    if (active.type == AnnotationElementType.freeStroke &&
        active.points.length < 2) {
      state = state.copyWith(clearActiveStroke: true);
      return;
    }

    _pushHistory();

    final newElements = [...state.elements, active];
    final updatedAnnotation = state.annotation!.copyWith(
      elements: newElements,
      syncStatus: 'pendingSync',
    );

    state = state.copyWith(
      annotation: updatedAnnotation,
      clearActiveStroke: true,
      canUndo: _history.isNotEmpty,
    );

    _scheduleAutosave();
  }

  /// Añade una etiqueta de texto en la posición dada.
  void addText(CanvasPoint position, String text) {
    if (text.trim().isEmpty) return;
    _pushHistory();

    final el = AnnotationElement(
      id: UuidGenerator.generate(),
      type: AnnotationElementType.text,
      points: [position],
      color: state.activeColor,
      strokeWidth: state.strokeWidth,
      text: text,
      fontSize: 14.0,
    );
    final newElements = [...state.elements, el];
    final updatedAnnotation = state.annotation!.copyWith(
      elements: newElements,
      syncStatus: 'pendingSync',
    );
    state = state.copyWith(
      annotation: updatedAnnotation,
      canUndo: _history.isNotEmpty,
    );
    _scheduleAutosave();
  }

  /// Deshace el último trazo.
  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    final updatedAnnotation = state.annotation!.copyWith(
      elements: previous,
      syncStatus: 'pendingSync',
    );
    state = state.copyWith(
      annotation: updatedAnnotation,
      canUndo: _history.isNotEmpty,
    );
    _scheduleAutosave();
  }

  /// Borra todos los elementos del canvas.
  void clearAll() {
    _pushHistory();
    final updatedAnnotation = state.annotation!.copyWith(
      elements: const [],
      syncStatus: 'pendingSync',
    );
    state = state.copyWith(
      annotation: updatedAnnotation,
      canUndo: _history.isNotEmpty,
    );
    _scheduleAutosave();
  }

  bool get canUndo => _history.isNotEmpty;

  // ── Persistencia ─────────────────────────────────────────────────────────

  void _scheduleAutosave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      // Autosave más lento para anotaciones (son más pesadas)
      const Duration(milliseconds: AppConstants.kFormAutosaveDebounceMs * 2),
      _persist,
    );
  }

  Future<void> _persist() async {
    final annotation = state.annotation;
    if (annotation == null) return;
    state = state.copyWith(isSaving: true);
    final result = await _saveUseCase(annotation);
    result.fold(
      (f) {
        AppLogger.w('Annotation autosave failure: ${f.message}');
        state = state.copyWith(isSaving: false);
      },
      (saved) {
        state = state.copyWith(
          isSaving: false,
          annotation: saved,
          lastSavedAt: DateTime.now(),
        );
      },
    );
  }

  Future<void> saveNow() async {
    _debounceTimer?.cancel();
    await _persist();
  }

  // ── Historial ────────────────────────────────────────────────────────────

  void _pushHistory() {
    _history.add(List<AnnotationElement>.from(state.elements));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final annotationEditorProvider = StateNotifierProvider.autoDispose
    .family<AnnotationEditorController, AnnotationEditorState, String>(
  (ref, visitId) {
    final controller = AnnotationEditorController(visitId: visitId);
    Future.microtask(() => controller.initialize());
    return controller;
  },
);
