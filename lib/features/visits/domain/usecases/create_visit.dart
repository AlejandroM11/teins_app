import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../entities/visit.dart';
import '../repositories/visit_repository.dart';

class CreateVisitParams {
  const CreateVisitParams({
    required this.technicianId,
    required this.title,
    required this.visitType,
    this.clientId,
    this.clientName,
    this.address,
    this.description,
    this.formTemplateId,
    this.formTemplateVersion,
  });

  final String technicianId;
  final String title;
  final String visitType;
  final String? clientId;
  final String? clientName;
  final String? address;
  final String? description;
  final String? formTemplateId;
  final int? formTemplateVersion;
}

/// Crea una nueva visita localmente con UUID generado en el cliente.
/// No requiere conexión a Internet.
class CreateVisit {
  const CreateVisit(this._repository);

  final VisitRepository _repository;

  Future<Either<Failure, Visit>> call(CreateVisitParams params) {
    final now = DateTime.now();
    final visit = Visit(
      id: UuidGenerator.generate(),
      technicianId: params.technicianId,
      clientId: params.clientId,
      clientName: params.clientName,
      title: params.title,
      description: params.description,
      visitType: params.visitType,
      address: params.address,
      status: VisitStatus.assigned,
      syncStatus: SyncStatus.local,
      formTemplateId: params.formTemplateId,
      formTemplateVersion: params.formTemplateVersion,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createVisit(visit);
  }
}
