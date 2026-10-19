import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: obtener el usuario actualmente autenticado.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserProfile?>> call() =>
      _repository.getCurrentUser();
}
