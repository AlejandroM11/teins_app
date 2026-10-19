import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/annotation.dart';
import '../painters/annotation_painter.dart';
import '../providers/annotation_providers.dart';

/// Canvas de dibujo interactivo.
///
/// Optimizaciones de rendimiento:
/// - RepaintBoundary aísla el canvas del árbol de widgets
/// - CustomPaint solo se repinta cuando cambian los elementos (shouldRepaint)
/// - GestureDetector captura gestos de pan para trazos continuos
/// - Los puntos se normalizan respecto al tamaño real del canvas
class DrawingCanvas extends ConsumerWidget {
  const DrawingCanvas({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(annotationEditorProvider(visitId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          onPanStart: (details) {
            final point = _normalize(details.localPosition, canvasSize);
            ref
                .read(annotationEditorProvider(visitId).notifier)
                .onStrokeStart(point);
          },
          onPanUpdate: (details) {
            final point = _normalize(details.localPosition, canvasSize);
            ref
                .read(annotationEditorProvider(visitId).notifier)
                .onStrokeUpdate(point);
          },
          onPanEnd: (_) {
            ref
                .read(annotationEditorProvider(visitId).notifier)
                .onStrokeEnd();
          },
          onTapDown: editorState.activeTool == AnnotationElementType.text
              ? (details) => _handleTextTap(
                    context,
                    ref,
                    details.localPosition,
                    canvasSize,
                  )
              : null,
          child: RepaintBoundary(
            child: CustomPaint(
              size: canvasSize,
              painter: AnnotationPainter(
                elements: editorState.elements,
                activeStroke: editorState.activeStroke,
              ),
            ),
          ),
        );
      },
    );
  }

  CanvasPoint _normalize(Offset local, Size canvasSize) {
    return CanvasPoint(
      local.dx / canvasSize.width,
      local.dy / canvasSize.height,
    );
  }

  Future<void> _handleTextTap(
    BuildContext context,
    WidgetRef ref,
    Offset local,
    Size canvasSize,
  ) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar texto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe una anotación...',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (text != null && text.trim().isNotEmpty) {
      final point = _normalize(local, canvasSize);
      ref
          .read(annotationEditorProvider(visitId).notifier)
          .addText(point, text);
    }
  }
}
