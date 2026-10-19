import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../network/connectivity_service.dart';
import '../permissions/permission_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/authenticate_user.dart';
import '../../features/authentication/domain/usecases/get_current_user.dart';
import '../../features/authentication/domain/usecases/sign_out.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';

import '../../features/visits/data/datasources/visit_local_datasource.dart';
import '../../features/visits/data/repositories/visit_repository_impl.dart';
import '../../features/visits/domain/repositories/visit_repository.dart';
import '../../features/visits/domain/usecases/get_assigned_visits.dart';
import '../../features/visits/domain/usecases/get_visit.dart';
import '../../features/visits/domain/usecases/create_visit.dart';
import '../../features/visits/domain/usecases/update_visit.dart';
import '../../features/visits/domain/usecases/start_visit.dart';
import '../../features/visits/domain/usecases/complete_visit.dart';

import '../../features/dynamic_forms/data/datasources/form_local_datasource.dart';
import '../../features/dynamic_forms/data/repositories/form_repository_impl.dart';
import '../../features/dynamic_forms/domain/repositories/form_repository.dart';
import '../../features/dynamic_forms/domain/usecases/get_form_template.dart';
import '../../features/dynamic_forms/domain/usecases/save_form_response.dart';
import '../../features/dynamic_forms/domain/usecases/get_form_response.dart';

import '../../features/materials/data/datasources/material_local_datasource.dart';
import '../../features/materials/data/repositories/material_repository_impl.dart';
import '../../features/materials/domain/repositories/material_repository.dart';
import '../../features/materials/domain/usecases/get_materials_catalog.dart';
import '../../features/materials/domain/usecases/add_material_to_visit.dart';
import '../../features/materials/domain/usecases/get_visit_materials.dart';
import '../../features/materials/domain/usecases/update_material_quantity.dart';
import '../../features/materials/domain/usecases/remove_material_from_visit.dart';

import '../../features/photos/data/datasources/photo_local_datasource.dart';
import '../../features/photos/data/repositories/photo_repository_impl.dart';
import '../../features/photos/domain/repositories/photo_repository.dart';
import '../../features/photos/domain/usecases/capture_photo.dart';
import '../../features/photos/domain/usecases/get_visit_photos.dart';
import '../../features/photos/domain/usecases/delete_photo.dart';

import '../../features/annotations/data/datasources/annotation_local_datasource.dart';
import '../../features/annotations/data/repositories/annotation_repository_impl.dart';
import '../../features/annotations/domain/repositories/annotation_repository.dart';
import '../../features/annotations/domain/usecases/save_annotation.dart';
import '../../features/annotations/domain/usecases/get_visit_annotations.dart';
import '../../features/annotations/domain/usecases/delete_annotation.dart';

import '../../features/synchronization/data/services/powersync_service.dart';
import '../../features/synchronization/data/repositories/sync_repository_impl.dart';
import '../../features/synchronization/domain/repositories/sync_repository.dart';
import '../../features/synchronization/domain/usecases/get_sync_status.dart';

final sl = GetIt.instance;

/// Configura e inicializa todas las dependencias de la aplicación.
///
/// Se llama una sola vez en main.dart antes de runApp.
/// El orden de registro importa: registrar primero los servicios base.
Future<void> configureDependencies() async {
  AppLogger.i('Configurando dependencias...');

  // ── Servicios de infraestructura ─────────────────────────────────────────
  _registerInfrastructureServices();

  // ── Features ─────────────────────────────────────────────────────────────
  _registerAuthFeature();
  _registerVisitsFeature();
  _registerFormsFeature();
  _registerMaterialsFeature();
  _registerPhotosFeature();
  _registerAnnotationsFeature();
  _registerSyncFeature();

  AppLogger.i('Dependencias configuradas correctamente.');
}

void _registerInfrastructureServices() {
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<PermissionService>(() => PermissionService());
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );
}

void _registerAuthFeature() {
  // Datasource
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(supabaseClient: sl()),
  );
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDatasource: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => AuthenticateUser(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  // Controller
  sl.registerFactory(
    () => AuthController(
      authenticateUser: sl(),
      getCurrentUser: sl(),
      signOut: sl(),
    ),
  );
}

void _registerVisitsFeature() {
  sl.registerLazySingleton<VisitLocalDatasource>(
    () => VisitLocalDatasourceImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(localDatasource: sl()),
  );
  sl.registerLazySingleton(() => GetAssignedVisits(sl()));
  sl.registerLazySingleton(() => GetVisit(sl()));
  sl.registerLazySingleton(() => CreateVisit(sl()));
  sl.registerLazySingleton(() => UpdateVisit(sl()));
  sl.registerLazySingleton(() => StartVisit(sl()));
  sl.registerLazySingleton(() => CompleteVisit(sl()));
}

void _registerFormsFeature() {
  sl.registerLazySingleton<FormLocalDatasource>(
    () => FormLocalDatasourceImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton<FormRepository>(
    () => FormRepositoryImpl(localDatasource: sl()),
  );
  sl.registerLazySingleton(() => GetFormTemplate(sl()));
  sl.registerLazySingleton(() => SaveFormResponse(sl()));
  sl.registerLazySingleton(() => GetFormResponse(sl()));
}

void _registerMaterialsFeature() {
  sl.registerLazySingleton<MaterialLocalDatasource>(
    () => MaterialLocalDatasourceImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton<MaterialRepository>(
    () => MaterialRepositoryImpl(localDatasource: sl()),
  );
  sl.registerLazySingleton(() => GetMaterialsCatalog(sl()));
  sl.registerLazySingleton(() => AddMaterialToVisit(sl()));
  sl.registerLazySingleton(() => GetVisitMaterials(sl()));
  sl.registerLazySingleton(() => UpdateMaterialQuantity(sl()));
  sl.registerLazySingleton(() => RemoveMaterialFromVisit(sl()));
}

void _registerPhotosFeature() {
  sl.registerLazySingleton<PhotoLocalDatasource>(
    () => PhotoLocalDatasourceImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton<PhotoRepository>(
    () => PhotoRepositoryImpl(
      localDatasource: sl(),
      supabaseClient: sl(),
      connectivityService: sl(),
      permissionService: sl(),
    ),
  );
  sl.registerLazySingleton(() => CapturePhoto(sl()));
  sl.registerLazySingleton(() => GetVisitPhotos(sl()));
  sl.registerLazySingleton(() => DeletePhoto(sl()));
}

void _registerAnnotationsFeature() {
  sl.registerLazySingleton<AnnotationLocalDatasource>(
    () => AnnotationLocalDatasourceImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton<AnnotationRepository>(
    () => AnnotationRepositoryImpl(localDatasource: sl()),
  );
  sl.registerLazySingleton(() => SaveAnnotation(sl()));
  sl.registerLazySingleton(() => GetVisitAnnotations(sl()));
  sl.registerLazySingleton(() => DeleteAnnotation(sl()));
}

void _registerSyncFeature() {
  sl.registerLazySingleton<PowerSyncService>(
    () => PowerSyncService(
      supabaseClient: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(powerSyncService: sl()),
  );
  sl.registerLazySingleton(() => GetSyncStatus(sl()));
}
