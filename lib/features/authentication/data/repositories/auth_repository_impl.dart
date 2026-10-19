import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDatasource remoteDatasource})
      : _remote = remoteDatasource;

  final AuthRemoteDatasource _remote;

  @override
  Future<Either<Failure, UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remote.signIn(email: email, password: password);
      return Right(model.toEntity());
    } on AuthException catch (e) {
      return Left(AuthenticationFailure(
        message: e.message,
        code: e.code,
        originalError: e,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(originalError: e));
    } catch (e) {
      AppLogger.e('AuthRepository.signIn', error: e);
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } catch (e) {
      AppLogger.e('AuthRepository.signOut', error: e);
      return const Right(null); // Cerrar sesión siempre "funciona" localmente
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentUser() async {
    try {
      final model = await _remote.getCurrentUser();
      return Right(model?.toEntity());
    } catch (e) {
      AppLogger.e('AuthRepository.getCurrentUser', error: e);
      return Left(UnknownFailure(originalError: e));
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _remote.authStateChanges.map((model) => model?.toEntity());
  }

  @override
  Future<Either<Failure, UserProfile?>> recoverSession() async {
    // Supabase Flutter recupera la sesión automáticamente desde el almacenamiento
    // seguro del dispositivo al inicializar. Solo necesitamos leer el usuario actual.
    return getCurrentUser();
  }
}
