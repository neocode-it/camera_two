import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';
import 'package:gallery_two/repository/file_repository.dart';
import 'package:image/image.dart' as img;

import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

part 'camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraCubit(this._messageCubit) : super(CameraPermissionMissing());
  final FileRepository fileRepo = FileRepository();
  final CameraMessageCubit _messageCubit;
  CameraController? _controller;
  late List<CameraDescription> _cameras;

  double _aspectRatio = .6;

  double _zoomLevel = 1.0;

  CameraMessageCubit get messageCubit {
    return _messageCubit;
  }

  adjustZoom(double gg) {
    if (state is! CameraReady) {
      return;
    }

    double newLevel = gg.clamp(1.0, 10.0);
    if (_zoomLevel + .1 > newLevel && _zoomLevel - .1 < newLevel) {
      return;
    }

    _zoomLevel = newLevel;
    _controller?.setZoomLevel(_zoomLevel);
    emit(CameraReady(_controller!, _cameras, _zoomLevel, _aspectRatio));
  }

  Future<void> loadCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    await _controller?.initialize();
    emit(CameraReady(_controller!, _cameras, _zoomLevel, _aspectRatio));
  }

  Future<void> takePicture() async {
    if (_controller == null) {
      return;
    }
    try {
      emit(CameraBusy());
      Future.delayed(const Duration(milliseconds: 300)).then((_) =>
          emit(CameraReady(_controller!, _cameras, _zoomLevel, _aspectRatio)));
      XFile file = await _controller!.takePicture();
      File? imageFile = await _cropToAspectRatio(file.path, _aspectRatio);
      await fileRepo.copyImage(imageFile!.path);
      _messageCubit.newMessage("Bild erstellt");
    } catch (e) {
      _messageCubit.newMessage("Unbekannter Fehler");
    }
  }

  Future<File?> _cropToAspectRatio(String imagePath, double aspectRatio) async {
    try {
      final image = img.decodeImage(await File(imagePath).readAsBytes());
      if (image == null) {
        throw Exception("Image invalid");
      }

      final width = image.width;
      final height = image.height;

      int targetWidth;
      int targetHeight;

      targetHeight = height;
      targetWidth = (height * aspectRatio).round();

      // Center cropping logic
      final x = (width - targetWidth) ~/ 2;
      final y = (height - targetHeight) ~/ 2;

      final croppedImage = img.copyCrop(image,
          x: x, y: y, width: targetWidth, height: targetHeight);
      final croppedFile = File(imagePath);

      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));
      return croppedFile;
    } catch (e) {
      return null;
    }
  }

  void closeCamera() {
    _controller?.dispose();
  }

  Future<void> initialize() async {
    emit(CameraPermissionMissing());
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
