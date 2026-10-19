import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class AuthenticateUserParams {
  const AuthenticateUserParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Caso de uso: autenticar usuario con email y contraseña.
class AuthenticateUser {
  const AuthenticateUser(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserProfile>> call(AuthenticateUserParams params) {
    return _repository.signIn(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
