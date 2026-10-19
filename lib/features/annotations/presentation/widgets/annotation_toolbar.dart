import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/annotation.dart';
import '../providers/annotation_providers.dart';

/// Barra de herramientas del canvas.
/// Diseño compacto y táctil para uso en campo.
class AnnotationToolbar extends ConsumerWidget {
  const AnnotationToolbar({super.key, required this.visitId});

  final String visitId;

  // Herramientas disponibles con ícono y etiqueta
  static const _tools = [
    (AnnotationElementType.freeStroke, Icons.draw_rounded, 'Lápiz'),
    (AnnotationElementType.line, Icons.horizontal_rule_rounded, 'Línea'),
    (AnnotationElementType.arrow, Icons.arrow_forward_rounded, 'Flecha'),
    (AnnotationElementType.rectangle, Icons.crop_square_rounded, 'Rect.'),
    (AnnotationElementType.circle, Icons.circle_outlined, 'Círculo'),
    (AnnotationElementType.marker, Icons.location_on_rounded, 'Marcador'),
    (AnnotationElementType.text, Icons.text_fields_rounded, 'Texto'),
  ];

  // Paleta de colores predefinida
  static const _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.white,
    Colors.black,
  ];

  static const _strokeWidths = [2.0, 4.0, 6.0, 10.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(annotationEditorProvider(visitId));
    final notifier = ref.read(annotationEditorProvider(visitId).notifier);

    return Container(
      color: AppColors.grey900.withOpacity(0.92),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fila 1: herramientas ───────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  for (final tool in _tools)
                    _ToolButton(
                      icon: tool.$2,
                      label: tool.$3,
                      isActive: state.activeTool == tool.$1,
                      onTap: () => notifier.setTool(tool.$1),
                    ),
                  const VerticalDivider(color: Colors.white24),
                  // Undo
                  _IconActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Deshacer',
                    onTap: state.canUndo ? notifier.undo : null,
                  ),
                  // Limpiar
                  _IconActionButton(
                    icon: Icons.delete_sweep_rounded,
                    label: 'Limpiar',
                    onTap: state.elements.isEmpty
                        ? null
                        : () => _confirmClear(context, notifier),
                  ),
                ],
              ),
            ),

            // ── Fila 2: colores y grosor ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  // Colores
                  for (final color in _colors)
                    _ColorButton(
                      color: color,
                      isSelected: state.activeColor == color,
                      onTap: () => notifier.setColor(color),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(height: 24, child: VerticalDivider(color: Colors.white24)),
                  const SizedBox(width: AppSpacing.sm),
                  // Grosores
                  for (final w in _strokeWidths)
                    _StrokeWidthButton(
                      width: w,
                      color: state.activeColor,
                      isSelected: state.strokeWidth == w,
                      onTap: () => notifier.setStrokeWidth(w),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    AnnotationEditorController notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar canvas'),
        content: const Text('¿Eliminar todas las anotaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (confirmed == true) notifier.clearAll();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: isActive
              ? Border.all(color: AppColors.primaryLight, width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? Colors.white : Colors.white24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: enabled ? Colors.white70 : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class _StrokeWidthButton extends StatelessWidget {
  const _StrokeWidthButton({
    required this.width,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final double width;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: width.clamp(2, 18),
            height: width.clamp(2, 18),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
