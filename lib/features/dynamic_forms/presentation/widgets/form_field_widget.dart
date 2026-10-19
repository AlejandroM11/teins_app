// Este archivo usa material_ui en lugar de flutter/material.dart porque
// flutter_form_builder v11 migró sus tipos (InputDecoration, DropdownMenuItem, etc.)
// a package:material_ui. Mezclar ambos imports genera "type/*1*/ can't be assigned
// to type/*2*/". Los demás archivos del proyecto siguen usando flutter/material.dart
// sin problema gracias al MaterialUiCompatibilityBridge en app.dart.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/form_template.dart';

/// Motor de renderizado de campos de formulario dinámico.
///
/// Cada [FormFieldDefinition] se convierte en el widget correcto
/// de flutter_form_builder. Agregar un nuevo tipo de campo solo
/// requiere extender el switch.
class FormFieldWidget extends StatelessWidget {
  const FormFieldWidget({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });

  final FormFieldDefinition field;
  final dynamic initialValue;
  final void Function(String fieldId, dynamic value) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(context),
          if (field.unit != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Unidad: ${field.unit}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context) {
    switch (field.type) {
      case FormFieldType.text:
        return _buildTextField();

      case FormFieldType.textarea:
        return _buildTextAreaField();

      case FormFieldType.number:
        return _buildNumberField(isDecimal: false);

      case FormFieldType.decimal:
      case FormFieldType.measure:
        return _buildNumberField(isDecimal: true);

      case FormFieldType.select:
        return _buildSelectField();

      case FormFieldType.multiSelect:
        return _buildMultiSelectField();

      case FormFieldType.boolean:
        return _buildBooleanField();

      case FormFieldType.date:
        return _buildDateField();

      case FormFieldType.time:
        return _buildTimeField();

      case FormFieldType.photo:
        return _buildPhotoPlaceholder();

      case FormFieldType.materials:
        return _buildMaterialsPlaceholder();
    }
  }

  // ── Campos concretos ────────────────────────────────────────────────────

  Widget _buildTextField() {
    return FormBuilderTextField(
      name: field.id,
      initialValue: initialValue?.toString(),
      enabled: enabled,
      decoration: _decoration(),
      textCapitalization: TextCapitalization.sentences,
      validator: _stringValidator(),
      onChanged: (v) => onChanged(field.id, v),
    );
  }

  Widget _buildTextAreaField() {
    return FormBuilderTextField(
      name: field.id,
      initialValue: initialValue?.toString(),
      enabled: enabled,
      maxLines: 4,
      decoration: _decoration(),
      textCapitalization: TextCapitalization.sentences,
      validator: _stringValidator(),
      onChanged: (v) => onChanged(field.id, v),
    );
  }

  Widget _buildNumberField({required bool isDecimal}) {
    return FormBuilderTextField(
      name: field.id,
      initialValue: initialValue?.toString(),
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: _decoration(
        suffix: field.unit != null ? Text(field.unit!) : null,
      ),
      validator: FormBuilderValidators.compose([
        if (field.required) FormBuilderValidators.required(),
        if (isDecimal)
          FormBuilderValidators.numeric(
            errorText: 'Ingresa un número válido',
          ),
        if (!isDecimal)
          FormBuilderValidators.integer(
            errorText: 'Ingresa un número entero',
          ),
        if (field.minValue != null)
          FormBuilderValidators.min(
            field.minValue!,
            errorText: 'Mínimo: ${field.minValue}',
          ),
        if (field.maxValue != null)
          FormBuilderValidators.max(
            field.maxValue!,
            errorText: 'Máximo: ${field.maxValue}',
          ),
      ]),
      onChanged: (v) {
        if (v == null || v.isEmpty) {
          onChanged(field.id, null);
          return;
        }
        final parsed = isDecimal ? double.tryParse(v) : int.tryParse(v);
        onChanged(field.id, parsed ?? v);
      },
    );
  }

  Widget _buildSelectField() {
    return FormBuilderDropdown<String>(
      name: field.id,
      initialValue: initialValue?.toString(),
      enabled: enabled,
      decoration: _decoration(),
      validator: _stringValidator(),
      items: field.options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: (v) => onChanged(field.id, v),
    );
  }

  Widget _buildMultiSelectField() {
    final currentValues = initialValue is List
        ? List<String>.from(initialValue as List)
        : <String>[];

    // Renombrado a FormBuilderFilterChips (con 's') desde v10
    return FormBuilderFilterChips<String>(
      name: field.id,
      initialValue: currentValues,
      decoration: _decoration(),
      options: field.options
          .map((opt) => FormBuilderChipOption(value: opt, child: Text(opt)))
          .toList(),
      onChanged: (v) => onChanged(field.id, v),
    );
  }

  Widget _buildBooleanField() {
    return FormBuilderSwitch(
      name: field.id,
      title: Text(
        field.label,
        style: const TextStyle(fontSize: 15),
      ),
      initialValue: initialValue as bool? ?? false,
      enabled: enabled,
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (v) => onChanged(field.id, v),
    );
  }

  Widget _buildDateField() {
    DateTime? initial;
    if (initialValue is String) {
      initial = DateTime.tryParse(initialValue as String);
    }
    return FormBuilderDateTimePicker(
      name: field.id,
      initialValue: initial,
      enabled: enabled,
      inputType: InputType.date,
      decoration: _decoration(),
      // El validator de DateTimePicker recibe DateTime?, no String?
      validator: field.required
          ? (DateTime? val) =>
              val == null ? '${field.label} es requerido' : null
          : null,
      onChanged: (v) => onChanged(
        field.id,
        v?.toUtc().toIso8601String(),
      ),
    );
  }

  Widget _buildTimeField() {
    DateTime? initial;
    if (initialValue is String) {
      initial = DateTime.tryParse(initialValue as String);
    }
    return FormBuilderDateTimePicker(
      name: field.id,
      initialValue: initial,
      enabled: enabled,
      inputType: InputType.time,
      decoration: _decoration(),
      onChanged: (v) => onChanged(
        field.id,
        v?.toUtc().toIso8601String(),
      ),
    );
  }

  /// Placeholder para campos de tipo foto — abre la sección de fotos.
  Widget _buildPhotoPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            field.label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          const Text(
            'Ver sección Fotografías',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder para campos de tipo materiales.
  Widget _buildMaterialsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            field.label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          const Text(
            'Ver sección Materiales',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  InputDecoration _decoration({Widget? suffix}) {
    return InputDecoration(
      labelText: field.required ? '${field.label} *' : field.label,
      hintText: field.hint,
      suffix: suffix,
    );
  }

  /// Validador para campos de tipo String (text, textarea, select, etc.)
  FormFieldValidator<String>? _stringValidator() {
    if (!field.required) return null;
    return FormBuilderValidators.required(
      errorText: '${field.label} es requerido',
    );
  }
}
