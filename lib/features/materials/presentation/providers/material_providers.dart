import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/material.dart';
import '../../domain/usecases/add_material_to_visit.dart';
import '../../domain/usecases/get_materials_catalog.dart';
import '../../domain/usecases/get_visit_materials.dart';
import '../../domain/usecases/remove_material_from_visit.dart';
import '../../domain/usecases/update_material_quantity.dart';

// ── Catálogo ─────────────────────────────────────────────────────────────

class CatalogSearchParams {
  const CatalogSearchParams({
    this.query = '',
    this.category,
    this.limit = 30,
    this.offset = 0,
  });

  final String query;
  final String? category;
  final int limit;
  final int offset;
}

final catalogSearchProvider = FutureProvider.autoDispose
    .family<List<CatalogMaterial>, CatalogSearchParams>(
  (ref, params) async {
    final useCase = sl<GetMaterialsCatalog>();
    final result = await useCase(
      query: params.query,
      category: params.category,
      limit: params.limit,
      offset: params.offset,
    );
    return result.fold((_) => [], (list) => list);
  },
);

final catalogCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final useCase = sl<GetMaterialsCatalog>();
  final result = await useCase.getCategories();
  return result.fold((_) => [], (list) => list);
});

// ── Materiales de visita ─────────────────────────────────────────────────

final visitMaterialsProvider = StreamProvider.autoDispose
    .family<List<VisitMaterial>, String>((ref, visitId) {
  final useCase = sl<GetVisitMaterials>();
  return useCase(visitId).map(
    (either) => either.fold((_) => [], (list) => list),
  );
});

// ── Acciones ─────────────────────────────────────────────────────────────

sealed class MaterialActionState {
  const MaterialActionState();
}

class MaterialActionIdle extends MaterialActionState {
  const MaterialActionIdle();
}

class MaterialActionLoading extends MaterialActionState {
  const MaterialActionLoading();
}

class MaterialActionSuccess extends MaterialActionState {
  const MaterialActionSuccess(this.message);
  final String message;
}

class MaterialActionError extends MaterialActionState {
  const MaterialActionError(this.failure);
  final Failure failure;
}

class MaterialActionController
    extends StateNotifier<MaterialActionState> {
  MaterialActionController()
      : _addMaterial = sl<AddMaterialToVisit>(),
        _updateQuantity = sl<UpdateMaterialQuantity>(),
        _removeMaterial = sl<RemoveMaterialFromVisit>(),
        super(const MaterialActionIdle());

  final AddMaterialToVisit _addMaterial;
  final UpdateMaterialQuantity _updateQuantity;
  final RemoveMaterialFromVisit _removeMaterial;

  Future<void> add({
    required String visitId,
    required CatalogMaterial material,
    required double quantity,
    String? observations,
  }) async {
    state = const MaterialActionLoading();
    final result = await _addMaterial(
      visitId: visitId,
      catalogMaterial: material,
      quantity: quantity,
      observations: observations,
    );
    result.fold(
      (f) => state = MaterialActionError(f),
      (_) {
        AppLogger.d('Material agregado: ${material.code}');
        state = const MaterialActionSuccess('Material agregado correctamente.');
      },
    );
  }

  Future<void> updateQuantity({
    required String visitMaterialId,
    required double quantity,
  }) async {
    state = const MaterialActionLoading();
    final result = await _updateQuantity(
      visitMaterialId: visitMaterialId,
      quantity: quantity,
    );
    result.fold(
      (f) => state = MaterialActionError(f),
      (_) => state =
          const MaterialActionSuccess('Cantidad actualizada.'),
    );
  }

  Future<void> remove(String visitMaterialId) async {
    state = const MaterialActionLoading();
    final result = await _removeMaterial(visitMaterialId);
    result.fold(
      (f) => state = MaterialActionError(f),
      (_) => state =
          const MaterialActionSuccess('Material eliminado.'),
    );
  }

  void reset() => state = const MaterialActionIdle();
}

final materialActionProvider = StateNotifierProvider.autoDispose<
    MaterialActionController, MaterialActionState>(
  (_) => MaterialActionController(),
);
