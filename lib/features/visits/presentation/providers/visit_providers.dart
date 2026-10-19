import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/visit.dart';
import '../../domain/usecases/create_visit.dart';
import '../../domain/usecases/get_assigned_visits.dart';
import '../../domain/usecases/get_visit.dart';
import '../../domain/usecases/start_visit.dart';
import '../../domain/usecases/complete_visit.dart';
import '../../domain/usecases/update_visit.dart';

/// Stream reactivo de visitas del técnico autenticado.
/// Se actualiza en tiempo real cuando PowerSync sincroniza.
final assignedVisitsProvider =
    StreamProvider<Either<Failure, List<Visit>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final useCase = sl<GetAssignedVisits>();
  return useCase(user.id);
});

/// Visitas filtradas por estado para la UI.
final visitsByStatusProvider =
    Provider.family<List<Visit>, VisitStatus?>((ref, status) {
  final visitsAsync = ref.watch(assignedVisitsProvider);
  return visitsAsync.when(
    data: (either) => either.fold(
      (_) => [],
      (visits) => status == null
          ? visits
          : visits.where((v) => v.status == status).toList(),
    ),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Proveedor de una visita específica por ID.
final visitByIdProvider =
    FutureProvider.family<Either<Failure, Visit>, String>((ref, visitId) async {
  final useCase = sl<GetVisit>();
  return useCase(visitId);
});

/// Estado de creación/acción de visita.
sealed class VisitActionState {
  const VisitActionState();
}

class VisitActionIdle extends VisitActionState {
  const VisitActionIdle();
}

class VisitActionLoading extends VisitActionState {
  const VisitActionLoading();
}

class VisitActionSuccess extends VisitActionState {
  const VisitActionSuccess(this.visit);
  final Visit visit;
}

class VisitActionError extends VisitActionState {
  const VisitActionError(this.failure);
  final Failure failure;
}

/// Controller para acciones sobre visitas (crear, iniciar, completar).
class VisitActionController extends StateNotifier<VisitActionState> {
  VisitActionController()
      : _createVisit = sl<CreateVisit>(),
        _startVisit = sl<StartVisit>(),
        _completeVisit = sl<CompleteVisit>(),
        _updateVisit = sl<UpdateVisit>(),
        super(const VisitActionIdle());

  final CreateVisit _createVisit;
  final StartVisit _startVisit;
  final CompleteVisit _completeVisit;
  final UpdateVisit _updateVisit;

  Future<void> createVisit(CreateVisitParams params) async {
    state = const VisitActionLoading();
    final result = await _createVisit(params);
    result.fold(
      (f) => state = VisitActionError(f),
      (v) => state = VisitActionSuccess(v),
    );
  }

  Future<void> startVisit(String visitId) async {
    state = const VisitActionLoading();
    final result = await _startVisit(visitId);
    result.fold(
      (f) => state = VisitActionError(f),
      (v) => state = VisitActionSuccess(v),
    );
  }

  Future<void> completeVisit(String visitId) async {
    state = const VisitActionLoading();
    final result = await _completeVisit(visitId);
    result.fold(
      (f) => state = VisitActionError(f),
      (v) => state = VisitActionSuccess(v),
    );
  }

  Future<void> updateVisit(Visit visit) async {
    state = const VisitActionLoading();
    final result = await _updateVisit(visit);
    result.fold(
      (f) => state = VisitActionError(f),
      (v) => state = VisitActionSuccess(v),
    );
  }

  void reset() => state = const VisitActionIdle();
}

final visitActionControllerProvider =
    StateNotifierProvider.autoDispose<VisitActionController, VisitActionState>(
  (_) => VisitActionController(),
);
