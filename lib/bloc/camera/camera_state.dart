part of 'camera_cubit.dart';

@immutable
abstract class CameraState {}

class CameraPermissionMissing extends CameraState {}

class CameraPermissionDenied extends CameraState {}

class CameraReady extends CameraState {
  final CameraController controller;
  final List<CameraDescription> cameras;
  final double zoomLevel;
  final double minZoomLevel;
  final double maxZoomLevel;
  final double aspectRatio;
  final FlashMode flashMode;
  final int selectedCameraIndex;
  final File? lastImage;

  CameraReady(
    this.controller,
    this.cameras,
    this.zoomLevel,
    this.aspectRatio, {
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.flashMode = FlashMode.off,
    this.selectedCameraIndex = 0,
    this.lastImage,
  });

  CameraReady copyWith({
    CameraController? controller,
    List<CameraDescription>? cameras,
    double? zoomLevel,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? aspectRatio,
    FlashMode? flashMode,
    int? selectedCameraIndex,
    File? lastImage,
  }) {
    return CameraReady(
      controller ?? this.controller,
      cameras ?? this.cameras,
      zoomLevel ?? this.zoomLevel,
      aspectRatio ?? this.aspectRatio,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      flashMode: flashMode ?? this.flashMode,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      lastImage: lastImage ?? this.lastImage,
    );
  }
}

class CameraBusy extends CameraState {}

class CameraPaused extends CameraState {}
