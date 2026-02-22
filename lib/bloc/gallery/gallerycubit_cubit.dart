import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:outtake/classes/gallery_image_file.dart';
import 'package:meta/meta.dart';

import 'package:outtake/repository/file_repository.dart';

part 'gallerycubit_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit() : super(GalleryLoading());
  final fileRepo = FileRepository();
  Map<String, List<GalleryImageFile>> _gallery = {};

  Future<void> loadGallery() async {
    emit(GalleryLoading());
    try {
      _gallery = await fileRepo.getGallery();

      emit(GalleryLoaded(_gallery));
    } catch (e) {
      return;
    }
  }

  Future<void> deleteSelectedImages(List<int> indexes) async {
    try {
      _gallery.forEach(
        (groupName, List<GalleryImageFile> imageFiles) {
          imageFiles.forEach((item) {
            if (indexes.contains(item.id)) {
              fileRepo.deleteImage(item.file.path);
            }
          });
        },
      );
      await loadGallery();
    } catch (e) {}
    return;
  }
}
