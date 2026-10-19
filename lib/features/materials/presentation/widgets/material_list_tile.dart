import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/material.dart';

/// Tile de un material registrado en la visita.
/// Permite editar cantidad inline y eliminar.
class MaterialListTile extends StatefulWidget {
  const MaterialListTile({
    super.key,
    required this.material,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  final VisitMaterial material;
  final void Function(double) onQuantityChanged;
  final VoidCallback onDelete;

  @override
  State<MaterialListTile> createState() => _MaterialListTileState();
}

class _MaterialListTileState extends State<MaterialListTile> {
  late TextEditingController _qtyController;
  bool _editingQty = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: _formatQty(widget.material.quantity),
    );
  }

  @override
  void didUpdateWidget(MaterialListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.material.quantity != widget.material.quantity &&
        !_editingQty) {
      _qtyController.text = _formatQty(widget.material.quantity);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    return qty == qty.truncate() ? qty.toInt().toString() : qty.toString();
  }

  void _submitQty() {
    final value = double.tryParse(_qtyController.text);
    if (value != null && value > 0) {
      widget.onQuantityChanged(value);
    } else {
      // Revertir si valor inválido
      _qtyController.text = _formatQty(widget.material.quantity);
    }
    setState(() => _editingQty = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Ícono de categoría
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 22,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Info del material
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.material.materialName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.material.materialCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (widget.material.observations != null)
                    Text(
                      widget.material.observations!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Editor de cantidad inline
            _buildQuantityEditor(),
            const SizedBox(width: AppSpacing.xs),

            // Botón eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
              iconSize: 20,
              tooltip: 'Eliminar',
              onPressed: widget.onDelete,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityEditor() {
    if (_editingQty) {
      return SizedBox(
        width: 72,
        child: TextField(
          controller: _qtyController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            suffix: Text(
              widget.material.unit,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          onSubmitted: (_) => _submitQty(),
          onEditingComplete: _submitQty,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _editingQty = true),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatQty(widget.material.quantity),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              widget.material.unit,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
