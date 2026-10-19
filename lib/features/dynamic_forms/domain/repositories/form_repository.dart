import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/form_template.dart';

abstract interface class FormRepository {
  Future<Either<Failure, FormTemplate?>> getTemplateByVisitType(
    String visitType,
  );
  Future<Either<Failure, FormTemplate?>> getTemplateById(
    String templateId,
    int version,
  );
  Future<Either<Failure, FormResponse?>> getResponse(String visitId);
  Future<Either<Failure, FormResponse>> saveResponse(FormResponse response);
  Stream<Either<Failure, FormResponse?>> watchResponse(String visitId);
  Future<Either<Failure, List<FormTemplate>>> loadTemplatesFromAssets();
}
