import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/material.dart';
import '../repositories/material_repository.dart';

class GetMaterialsCatalog {
  const GetMaterialsCatalog(this._repository);

  final MaterialRepository _repository;

  Future<Either<Failure, List<CatalogMaterial>>> call({
    String query = '',
    String? category,
    int limit = 30,
    int offset = 0,
  }) =>
      _repository.searchCatalog(
        query: query,
        category: category,
        limit: limit,
        offset: offset,
      );

  Future<Either<Failure, List<String>>> getCategories() =>
      _repository.getCategories();
}
