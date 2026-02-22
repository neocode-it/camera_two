import 'dart:io';
import 'dart:ui'; // Add this for Offset if not using material
import 'package:flutter/material.dart'; // Add this for Offset and other UI types

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outtake/bloc/camera_message/camera_message_cubit.dart';
import 'package:outtake/repository/file_repository.dart';

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
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  CameraMessageCubit get messageCubit {
    return _messageCubit;
  }

  void adjustZoom(double zoom) {
    if (state is! CameraReady || _controller == null) {
      return;
    }

    double newLevel = zoom.clamp(_minZoomLevel, _maxZoomLevel);
    if ((_zoomLevel - newLevel).abs() < 0.01) {
      return;
    }

    _zoomLevel = newLevel;
    _controller!.setZoomLevel(_zoomLevel);
    emit((state as CameraReady).copyWith(zoomLevel: _zoomLevel));
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null) return;
    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      if (state is CameraReady) {
        emit((state as CameraReady).copyWith(flashMode: mode));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> setFocusPoint(Offset point) async {
    if (_controller == null) return;
    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.isEmpty) return;
    
    // Get current direction
    final currentDirection = _cameras[_selectedCameraIndex].lensDirection;
    
    // Find next direction
    final nextDirection = currentDirection == CameraLensDirection.back 
        ? CameraLensDirection.front 
        : CameraLensDirection.back;
        
    // Find first camera with next direction
    int newIndex = _cameras.indexWhere((c) => c.lensDirection == nextDirection);
    
    if (newIndex != -1) {
       await loadCamera(cameraIndex: newIndex);
    } else {
       // If no camera of other direction, maybe just cycle lenses?
       await switchLens();
    }
  }

  Future<void> switchLens() async {
     if (_cameras.isEmpty) return;
     
     final currentDirection = _cameras[_selectedCameraIndex].lensDirection;
     
     // Find all indices with same direction
     List<int> sameDirectionIndices = [];
     for(int i=0; i<_cameras.length; i++) {
       if (_cameras[i].lensDirection == currentDirection) {
         sameDirectionIndices.add(i);
       }
     }
     
     if (sameDirectionIndices.length < 2) return;
     
     // Find current index in the filtered list
     int currentFilteredIndex = sameDirectionIndices.indexOf(_selectedCameraIndex);
     if (currentFilteredIndex == -1) return; // Should not happen
     
     // Get next index
     int nextFilteredIndex = (currentFilteredIndex + 1) % sameDirectionIndices.length;
     int newIndex = sameDirectionIndices[nextFilteredIndex];
     
     await loadCamera(cameraIndex: newIndex);
     _messageCubit.newMessage("Kamera gewechselt (${_cameras[newIndex].name})");
  }

  Future<void> loadCamera({int cameraIndex = 0}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      if (cameraIndex >= _cameras.length) {
        cameraIndex = 0;
      }
      _selectedCameraIndex = cameraIndex;

      // Dispose previous controller if exists
      await _controller?.dispose();

      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      
      double aspectRatio = _controller!.value.aspectRatio;
      if (Platform.isAndroid || Platform.isIOS) {
         // Mobile cameras are usually landscape, so we invert for portrait UI
         if (aspectRatio > 1.0) {
           aspectRatio = 1.0 / aspectRatio;
         }
      }
      _aspectRatio = aspectRatio;
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      
      // Reset zoom to min or 1.0
      _zoomLevel = _minZoomLevel; 
      await _controller!.setZoomLevel(_zoomLevel);
      
      // Set initial flash mode
      await _controller!.setFlashMode(_flashMode);

      File? lastImage = await fileRepo.getLastImage();

      emit(CameraReady(
        _controller!,
        _cameras,
        _zoomLevel,
        _aspectRatio,
        minZoomLevel: _minZoomLevel,
        maxZoomLevel: _maxZoomLevel,
        flashMode: _flashMode,
        selectedCameraIndex: _selectedCameraIndex,
        lastImage: lastImage,
      ));
    } catch (e) {
      _messageCubit.newMessage("Fehler beim Laden der Kamera: $e");
    }
  }

  Future<void> pauseCamera() async {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.dispose();
      _controller = null;
      emit(CameraPaused());
    }
  }

  Future<void> resumeCamera() async {
    if (state is CameraPaused || state is CameraReady) { // Check if we should resume
       await loadCamera(cameraIndex: _selectedCameraIndex);
    }
  }

  Future<void> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      XFile file = await _controller!.takePicture();

      String newPath = await fileRepo.copyImage(file.path);
      _messageCubit.newMessage("Bild erstellt");
      if (state is CameraReady) {
        emit((state as CameraReady).copyWith(lastImage: File(newPath)));
      }
    } catch (e) {
      _messageCubit.newMessage("Fehler beim Erstellen des Bildes");
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
