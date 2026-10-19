import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/form_template.dart';
import '../repositories/form_repository.dart';

class GetFormTemplate {
  const GetFormTemplate(this._repository);

  final FormRepository _repository;

  Future<Either<Failure, FormTemplate?>> byVisitType(String visitType) =>
      _repository.getTemplateByVisitType(visitType);

  Future<Either<Failure, FormTemplate?>> byId(
    String templateId,
    int version,
  ) =>
      _repository.getTemplateById(templateId, version);
}
