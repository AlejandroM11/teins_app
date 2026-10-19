import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/material.dart';
import '../providers/material_providers.dart';

/// Bottom sheet para buscar y agregar un material al listado de la visita.
///
/// Búsqueda incremental: el provider se refrescada con cada cambio del query
/// después de un breve debounce para no saturar SQLite con cada tecla.
class AddMaterialSheet extends ConsumerStatefulWidget {
  const AddMaterialSheet({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends ConsumerState<AddMaterialSheet> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _obsController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  CatalogMaterial? _selectedMaterial;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _qtyController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(catalogCategoriesProvider);
    final searchParams = CatalogSearchParams(
      query: _searchQuery,
      category: _selectedCategory,
    );
    final resultsAsync = ref.watch(catalogSearchProvider(searchParams));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Agregar material',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Si hay material seleccionado, mostrar formulario de cantidad
              if (_selectedMaterial != null)
                _QuantityForm(
                  material: _selectedMaterial!,
                  visitId: widget.visitId,
                  qtyController: _qtyController,
                  obsController: _obsController,
                  onCancel: () =>
                      setState(() => _selectedMaterial = null),
                  onAdd: _addMaterial,
                )
              else ...[
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: _onSearchChanged,
                    autofocus: true,
                  ),
                ),

                // Filtro por categoría
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => categories.isEmpty
                      ? const SizedBox.shrink()
                      : _CategoryFilter(
                          categories: categories,
                          selected: _selectedCategory,
                          onSelected: (cat) => setState(
                            () => _selectedCategory =
                                _selectedCategory == cat ? null : cat,
                          ),
                        ),
                ),

                // Resultados
                Expanded(
                  child: resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => const Center(
                      child: Text('Error al buscar materiales.'),
                    ),
                    data: (materials) {
                      if (materials.isEmpty) {
                        return const Center(
                          child: Text(
                            'No se encontraron materiales.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final mat = materials[index];
                          return _CatalogItemTile(
                            material: mat,
                            onSelect: () => setState(
                              () => _selectedMaterial = mat,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addMaterial() async {
    final qty = double.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida.')),
      );
      return;
    }

    await ref.read(materialActionProvider.notifier).add(
          visitId: widget.visitId,
          material: _selectedMaterial!,
          quantity: qty,
          observations: _obsController.text.trim().isNotEmpty
              ? _obsController.text.trim()
              : null,
        );

    if (mounted) Navigator.of(context).pop();
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selected == cat;
          return FilterChip(
            label: Text(cat, style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
            selectedColor: AppColors.primaryLight,
          );
        },
      ),
    );
  }
}

class _CatalogItemTile extends StatelessWidget {
  const _CatalogItemTile({required this.material, required this.onSelect});

  final CatalogMaterial material;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          size: 20,
          color: AppColors.secondary,
        ),
      ),
      title: Text(
        material.name,
        style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${material.code} · ${material.unit}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
        onPressed: onSelect,
        tooltip: 'Seleccionar',
      ),
      onTap: onSelect,
    );
  }
}

class _QuantityForm extends ConsumerWidget {
  const _QuantityForm({
    required this.material,
    required this.visitId,
    required this.qtyController,
    required this.obsController,
    required this.onCancel,
    required this.onAdd,
  });

  final CatalogMaterial material;
  final String visitId;
  final TextEditingController qtyController;
  final TextEditingController obsController;
  final VoidCallback onCancel;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(materialActionProvider) is MaterialActionLoading;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material seleccionado
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          material.code,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cantidad
            TextField(
              controller: qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Cantidad *',
                suffix: Text(material.unit),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Observaciones
            TextField(
              controller: obsController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'Ej: instalado en rack 2',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onAdd,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
