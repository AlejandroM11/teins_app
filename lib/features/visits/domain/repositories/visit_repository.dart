import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/visit.dart';

abstract interface class VisitRepository {
  /// Stream reactivo de visitas asignadas al técnico.
  /// Se actualiza automáticamente cuando PowerSync sincroniza.
  Stream<Either<Failure, List<Visit>>> watchAssignedVisits(String technicianId);

  /// Obtiene las visitas asignadas una sola vez (snapshot).
  Future<Either<Failure, List<Visit>>> getAssignedVisits(String technicianId);

  /// Obtiene una visita por ID.
  Future<Either<Failure, Visit>> getVisit(String visitId);

  /// Crea una nueva visita localmente.
  /// La sincronización la lleva PowerSync.
  Future<Either<Failure, Visit>> createVisit(Visit visit);

  /// Actualiza una visita existente.
  Future<Either<Failure, Visit>> updateVisit(Visit visit);

  /// Transiciona el estado de una visita validando la máquina de estados.
  Future<Either<Failure, Visit>> transitionStatus(
    String visitId,
    VisitStatus newStatus,
  );
}
