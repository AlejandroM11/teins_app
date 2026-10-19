import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../data/repositories/form_repository_impl.dart';
import '../../domain/entities/form_template.dart';
import '../../domain/repositories/form_repository.dart';
import '../../domain/usecases/get_form_template.dart';
import '../../domain/usecases/save_form_response.dart';
import '../../domain/usecases/get_form_response.dart';

// ── Providers de datos ────────────────────────────────────────────────────

/// Plantilla de formulario para un tipo de visita.
final formTemplateProvider =
    FutureProvider.family<FormTemplate?, String>((ref, visitType) async {
  final useCase = sl<GetFormTemplate>();
  final result = await useCase.byVisitType(visitType);
  return result.fold((_) => null, (t) => t);
});

/// Stream reactivo de la respuesta del formulario de una visita.
final formResponseStreamProvider =
    StreamProvider.family<FormResponse?, String>((ref, visitId) {
  final useCase = sl<GetFormResponse>();
  return useCase.watch(visitId).map(
    (either) => either.fold((_) => null, (r) => r),
  );
});

// ── Estado del formulario ─────────────────────────────────────────────────

/// Estado del controller de formulario con autosave.
class FormEditorState {
  const FormEditorState({
    this.template,
    this.response,
    this.isSaving = false,
    this.lastSavedAt,
    this.failure,
    this.currentSectionIndex = 0,
  });

  final FormTemplate? template;
  final FormResponse? response;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final Failure? failure;
  final int currentSectionIndex;

  bool get hasData => template != null;
  bool get isDirty => response?.syncStatus == 'pendingSync';

  FormEditorState copyWith({
    FormTemplate? template,
    FormResponse? response,
    bool? isSaving,
    DateTime? lastSavedAt,
    Failure? failure,
    int? currentSectionIndex,
  }) {
    return FormEditorState(
      template: template ?? this.template,
      response: response ?? this.response,
      isSaving: isSaving ?? this.isSaving,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      failure: failure,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
    );
  }
}

/// Controller que gestiona el formulario dinámico con autosave debounced.
///
/// Flujo offline-first:
/// 1. Usuario modifica campo
/// 2. updateField() activa debounce timer
/// 3. Después de 800ms sin cambios, _persistToLocal() guarda en SQLite
/// 4. La UI se actualiza inmediatamente (estado en memoria)
/// 5. PowerSync sincroniza en background cuando hay conexión
class FormEditorController extends StateNotifier<FormEditorState> {
  FormEditorController({
    required this.visitId,
    required this.visitType,
  })  : _saveUseCase = sl<SaveFormResponse>(),
        _getTemplateUseCase = sl<GetFormTemplate>(),
        _repo = sl<FormRepository>() as FormRepositoryImpl,
        super(const FormEditorState());

  final String visitId;
  final String visitType;
  final SaveFormResponse _saveUseCase;
  final GetFormTemplate _getTemplateUseCase;
  final FormRepositoryImpl _repo;

  Timer? _debounceTimer;

  /// Inicializa: carga plantilla y respuesta existente (o crea una vacía).
  Future<void> initialize() async {
    final templateResult = await _getTemplateUseCase.byVisitType(visitType);
    final template = templateResult.fold((_) => null, (t) => t);

    if (template == null) {
      state = state.copyWith(
        failure: const DatabaseFailure(
          message: 'No se encontró la plantilla del formulario.',
        ),
      );
      return;
    }

    final response = await _repo.getOrCreateResponse(
      visitId: visitId,
      templateId: template.id,
      templateVersion: template.version,
    );

    state = state.copyWith(template: template, response: response);
    AppLogger.d('FormEditor inicializado para visita $visitId');
  }

  /// Actualiza el valor de un campo y activa el autosave debounced.
  void updateField(String fieldId, dynamic value) {
    final current = state.response;
    if (current == null) return;

    final updatedResponses = Map<String, dynamic>.from(current.responses)
      ..[fieldId] = value;

    state = state.copyWith(
      response: current.copyWith(
        responses: updatedResponses,
        updatedAt: DateTime.now(),
        syncStatus: 'pendingSync',
      ),
    );

    _scheduleAutosave();
  }

  /// Navega a una sección del formulario.
  void goToSection(int index) {
    final template = state.template;
    if (template == null) return;
    if (index < 0 || index >= template.sections.length) return;
    state = state.copyWith(currentSectionIndex: index);
  }

  /// Marca el formulario como completo y guarda inmediatamente.
  Future<bool> markComplete() async {
    _cancelDebounce();
    final current = state.response;
    if (current == null) return false;

    // Validar campos requeridos
    final template = state.template;
    if (template != null) {
      final missingRequired = template.allFields
          .where((f) => f.required)
          .where((f) {
            final value = current.responses[f.id];
            return value == null ||
                (value is String && value.trim().isEmpty);
          })
          .toList();

      if (missingRequired.isNotEmpty) {
        state = state.copyWith(
          failure: ValidationFailure(
            message: 'Campos requeridos sin completar: '
                '${missingRequired.map((f) => f.label).join(', ')}',
          ),
        );
        return false;
      }
    }

    final completed = current.copyWith(
      isComplete: true,
      completedAt: DateTime.now(),
      syncStatus: 'pendingSync',
    );
    await _persist(completed);
    return state.failure == null;
  }

  /// Guarda inmediatamente sin esperar el debounce.
  Future<void> saveNow() async {
    _cancelDebounce();
    final current = state.response;
    if (current != null) await _persist(current);
  }

  void _scheduleAutosave() {
    _cancelDebounce();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.kFormAutosaveDebounceMs),
      () async {
        final current = state.response;
        if (current != null) await _persist(current);
      },
    );
  }

  Future<void> _persist(FormResponse response) async {
    state = state.copyWith(isSaving: true, failure: null);
    final result = await _saveUseCase(response);
    result.fold(
      (failure) {
        AppLogger.w('Autosave failure: ${failure.message}');
        state = state.copyWith(isSaving: false, failure: failure);
      },
      (saved) {
        state = state.copyWith(
          isSaving: false,
          response: saved,
          lastSavedAt: DateTime.now(),
          failure: null,
        );
        AppLogger.d('Autosave OK: ${response.visitId}');
      },
    );
  }

  void _cancelDebounce() => _debounceTimer?.cancel();

  @override
  void dispose() {
    _cancelDebounce();
    super.dispose();
  }
}

final formEditorProvider = StateNotifierProvider.autoDispose
    .family<FormEditorController, FormEditorState, (String, String)>(
  (ref, params) {
    final (visitId, visitType) = params;
    final controller = FormEditorController(
      visitId: visitId,
      visitType: visitType,
    );
    // Inicializar al crear el provider
    Future.microtask(() => controller.initialize());
    return controller;
  },
);
