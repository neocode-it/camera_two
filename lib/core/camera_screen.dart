import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/camera/camera_cubit.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late CameraCubit _camCubit;

  @override
  void initState() {
    super.initState();
    _camCubit = context.read<CameraCubit>();
    _camCubit.initialize();
  }

  @override
  void dispose() {
    _camCubit.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _cameraPreview(),
                _cameraTrigger(),
              ],
            ),
            _messageArea(),
          ],
        ),
      ),
    );
  }

  Widget _messageArea() {
    return BlocBuilder<CameraMessageCubit, CameraMessageState>(
      bloc: context.read<CameraCubit>().messageCubit,
      builder: (context, state) {
        if (state is NewCameraMessage && state.message.isValid()) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 14, 14, 14)),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
              child: Text(
                state.message.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _cameraPreview() {
    return Expanded(
      child: BlocBuilder<CameraCubit, CameraState>(
        builder: (context, state) {
          if (state is CameraReady) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Center(
                child: GestureDetector(
                  onScaleUpdate: (details) =>
                      _onPinchUpdate(details, state.zoomLevel),
                  child: AspectRatio(
                    aspectRatio: state.aspectRatio,
                    child: CameraPreview(state.controller),
                  ),
                ),
              ),
            );
          } else if (state is CameraBusy) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: const Center(),
            );
          } else if (state is CameraPermissionDenied) {
            return const Center(
              child: Text("Kameraberechtigung fehlt!"),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  _onPinchUpdate(ScaleUpdateDetails details, currentZoom) {
    double zoomLevel = currentZoom * details.scale;
    context.read<CameraCubit>().adjustZoom(zoomLevel);
  }

  Widget _cameraTrigger() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade900),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
              onPressed: () => context.read<CameraCubit>().takePicture(),
              child: const Icon(
                Icons.camera_alt,
                size: 40,
              ),
            ),
          )
        ],
      ),
    );
  }
}
