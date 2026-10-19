import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar sesión.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call() => _repository.signOut();
}
