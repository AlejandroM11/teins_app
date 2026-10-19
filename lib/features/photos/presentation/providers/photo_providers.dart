import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/photo.dart';
import '../../domain/usecases/capture_photo.dart';
import '../../domain/usecases/delete_photo.dart';
import '../../domain/usecases/get_visit_photos.dart';

/// Stream reactivo de fotos de una visita.
final visitPhotosProvider = StreamProvider.autoDispose
    .family<List<VisitPhoto>, String>((ref, visitId) {
  final useCase = sl<GetVisitPhotos>();
  return useCase(visitId).map(
    (either) => either.fold((_) => [], (list) => list),
  );
});

// ── Estado de acciones de foto ────────────────────────────────────────────

sealed class PhotoActionState {
  const PhotoActionState();
}

class PhotoActionIdle extends PhotoActionState {
  const PhotoActionIdle();
}

class PhotoActionLoading extends PhotoActionState {
  const PhotoActionLoading();
}

class PhotoActionSuccess extends PhotoActionState {
  const PhotoActionSuccess(this.photo);
  final VisitPhoto photo;
}

class PhotoActionError extends PhotoActionState {
  const PhotoActionError(this.failure);
  final Failure failure;
}

class PhotoDeleted extends PhotoActionState {
  const PhotoDeleted();
}

/// Controller para capturar y eliminar fotos.
class PhotoActionController extends StateNotifier<PhotoActionState> {
  PhotoActionController()
      : _capturePhoto = sl<CapturePhoto>(),
        _deletePhoto = sl<DeletePhoto>(),
        super(const PhotoActionIdle());

  final CapturePhoto _capturePhoto;
  final DeletePhoto _deletePhoto;

  Future<void> captureFromCamera({
    required String visitId,
    String? formFieldId,
  }) async {
    state = const PhotoActionLoading();
    final result = await _capturePhoto(
      CapturePhotoParams(visitId: visitId, formFieldId: formFieldId),
    );
    result.fold(
      (f) => state = PhotoActionError(f),
      (photo) => state = PhotoActionSuccess(photo),
    );
  }

  Future<void> pickFromGallery({
    required String visitId,
    String? formFieldId,
  }) async {
    state = const PhotoActionLoading();
    final result = await _capturePhoto(
      CapturePhotoParams(
        visitId: visitId,
        formFieldId: formFieldId,
        fromGallery: true,
      ),
    );
    result.fold(
      (f) => state = PhotoActionError(f),
      (photo) => state = PhotoActionSuccess(photo),
    );
  }

  Future<void> delete(String photoId) async {
    state = const PhotoActionLoading();
    final result = await _deletePhoto(photoId);
    result.fold(
      (f) => state = PhotoActionError(f),
      (_) => state = const PhotoDeleted(),
    );
  }

  void reset() => state = const PhotoActionIdle();
}

final photoActionProvider =
    StateNotifierProvider.autoDispose<PhotoActionController, PhotoActionState>(
  (_) => PhotoActionController(),
);
