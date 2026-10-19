import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

/// Indicador de estado de autosave — discreto y siempre visible.
///
/// El técnico siempre debe saber si su información está guardada.
class AutosaveIndicator extends StatelessWidget {
  const AutosaveIndicator({
    super.key,
    required this.isSaving,
    this.lastSavedAt,
    this.hasError = false,
  });

  final bool isSaving;
  final DateTime? lastSavedAt;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _buildBadge(
        icon: Icons.warning_amber_rounded,
        label: 'No se pudo guardar',
        color: AppColors.error,
      );
    }

    if (isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Guardando...',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (lastSavedAt != null) {
      return _buildBadge(
        icon: Icons.check_circle_outline_rounded,
        label: 'Guardado ${AppDateUtils.formatRelative(lastSavedAt!)}',
        color: AppColors.success,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
