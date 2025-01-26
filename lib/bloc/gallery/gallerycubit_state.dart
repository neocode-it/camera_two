part of 'gallerycubit_cubit.dart';

@immutable
abstract class GalleryState {}

class GalleryLoading extends GalleryState {}

class GalleryLoaded extends GalleryState {
  GalleryLoaded(this.gallery);
  final Map<String, List<GalleryImageFile>> gallery;
}
