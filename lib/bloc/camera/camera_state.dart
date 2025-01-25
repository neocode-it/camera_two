part of 'camera_cubit.dart';

@immutable
abstract class CameraState {}

class CameraPermissionMissing extends CameraState {}

class CameraPermissionDenied extends CameraState {}

class CameraReady extends CameraState {
  final CameraController controller;
  final List<CameraDescription> cameras;
  final double zoomLevel;
  final double aspectRatio;
  CameraReady(this.controller, this.cameras, this.zoomLevel, this.aspectRatio);
}

class CameraBusy extends CameraState {}
