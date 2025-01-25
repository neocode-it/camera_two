import 'package:bloc/bloc.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';
import 'package:meta/meta.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

part 'camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraCubit(this._messageCubit) : super(CameraPermissionMissing());
  final CameraMessageCubit _messageCubit;
  CameraController? _controller;
  late List<CameraDescription> _cameras;

  double _zoomLevel = 1.0;

  CameraMessageCubit get messageCubit {
    return _messageCubit;
  }

  adjustZoom(double zoomLevel) {
    if (state is! CameraReady) {
      return;
    }

    double newLevel = zoomLevel.clamp(1.0, 10.0);
    if (_zoomLevel + .5 > newLevel && _zoomLevel - .5 < newLevel) {
      return;
    }

    _zoomLevel = newLevel;
    _controller?.setZoomLevel(_zoomLevel);
    emit(CameraReady(_controller!, _cameras, _zoomLevel));
  }

  Future<void> loadCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    await _controller?.initialize();
    emit(CameraReady(_controller!, _cameras, _zoomLevel));
  }

  Future<void> takePicture() async {
    _controller?.takePicture();
    _messageCubit.newMessage("Bild erstellt");
  }

  Future<void> closeCamera() async {
    _controller?.dispose();
  }

  Future<void> initialize() async {
    if (!await Permission.camera.isGranted) {
      PermissionStatus status = await Permission.camera.request();
      if (status.isDenied) {
        emit(CameraPermissionDenied());
        return;
      }
    }

    if (await Permission.camera.isGranted) {
      loadCamera();
    } else {
      emit(CameraPermissionDenied());
    }
  }
}
