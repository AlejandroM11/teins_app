import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/form_template.dart';
import 'form_field_widget.dart';

/// Renderiza una sección del formulario con sus campos.
///
/// Usa FormBuilder como contenedor para que la validación
/// funcione correctamente por sección.
class FormSectionWidget extends StatelessWidget {
  const FormSectionWidget({
    super.key,
    required this.section,
    required this.responses,
    required this.formKey,
    required this.onFieldChanged,
    this.enabled = true,
  });

  final FormSection section;
  final Map<String, dynamic> responses;
  final GlobalKey<FormBuilderState> formKey;
  final void Function(String fieldId, dynamic value) onFieldChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de sección
          _SectionHeader(title: section.title),
          const SizedBox(height: AppSpacing.md),

          // Campos de la sección
          ...section.fields.map(
            (field) => FormFieldWidget(
              key: ValueKey(field.id),
              field: field,
              initialValue: responses[field.id],
              onChanged: onFieldChanged,
              enabled: enabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
