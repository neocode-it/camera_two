import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/camera/camera_cubit.dart';
import 'package:gallery_two/bloc/camera_message/camera_message_cubit.dart';
import 'package:gallery_two/core/gallery_screen.dart';
import 'package:gallery_two/core/widgets/capture_button.dart';
import 'package:gallery_two/core/widgets/zoom_slider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late CameraCubit _camCubit;
  
  // For focus indicator
  bool _showFocusCircle = false;
  Offset _focusPoint = Offset.zero;

  // For flash animation
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camCubit = context.read<CameraCubit>();
    _camCubit.initialize();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeIn),
    );
    
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _flashController.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCubit.closeCamera();
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _camCubit.pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _camCubit.resumeCamera();
    }
  }

  void _handleTapFocus(TapUpDetails details, BoxConstraints constraints) {
    if (!_camCubit.state.runtimeType.toString().contains('CameraReady')) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _camCubit.setFocusPoint(offset);
    
    setState(() {
      _focusPoint = details.localPosition;
      _showFocusCircle = true;
    });

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showFocusCircle = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<CameraCubit, CameraState>(
          builder: (context, state) {
            if (state is CameraPermissionDenied) {
              return const Center(child: Text("Kameraberechtigung fehlt!", style: TextStyle(color: Colors.white)));
            }
            if (state is CameraPermissionMissing) {
                return const Center(child: CircularProgressIndicator());
            }
            if (state is CameraPaused) {
                return const Center(child: Text("Kamera pausiert", style: TextStyle(color: Colors.white)));
            }
            
            if (state is CameraReady) {
              return Stack(
                children: [
                   // Preview
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onScaleUpdate: (details) => _onPinchUpdate(details, state.zoomLevel),
                          onTapUp: (details) => _handleTapFocus(details, constraints),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: state.aspectRatio,
                              child: CameraPreview(state.controller),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Focus Indicator
                  if (_showFocusCircle)
                    Positioned(
                      left: _focusPoint.dx - 25,
                      top: _focusPoint.dy - 25,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                  // Flash Animation Overlay
                  AnimatedBuilder(
                    animation: _flashOpacity,
                    builder: (context, child) {
                      return IgnorePointer(
                        child: Container(
                          color: Colors.white.withOpacity(_flashOpacity.value),
                        ),
                      );
                    },
                  ),

                  // Controls Layer
                  Column(
                    children: [
                       // Top Bar
                       _buildTopBar(state),
                       
                       const Spacer(),
                       
                       // Zoom Presets
                       _buildZoomPresets(state),
                       
                       // Zoom Slider
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
                         child: ZoomSlider(
                           value: state.zoomLevel,
                           min: state.minZoomLevel,
                           max: state.maxZoomLevel,
                           onChanged: (val) => _camCubit.adjustZoom(val),
                         ),
                       ),
                       
                       // Bottom Bar
                       _buildBottomBar(state),
                    ],
                  ),
                  
                  // Messages
                  _messageArea(),
                ],
              );
            }
            
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(CameraReady state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              state.flashMode == FlashMode.off
                  ? Icons.flash_off
                  : state.flashMode == FlashMode.auto
                      ? Icons.flash_auto
                      : state.flashMode == FlashMode.always
                          ? Icons.flash_on
                          : Icons.highlight, // Icon for torch mode
              color: state.flashMode == FlashMode.torch
                  ? Colors.yellow
                  : Colors.white,
            ),
            onPressed: () {
              FlashMode nextMode;
              if (state.flashMode == FlashMode.off) {
                nextMode = FlashMode.auto;
              } else if (state.flashMode == FlashMode.auto) {
                nextMode = FlashMode.always;
              } else if (state.flashMode == FlashMode.always) {
                nextMode = FlashMode.torch;
              } else {
                nextMode = FlashMode.off;
              }
              _camCubit.setFlashMode(nextMode);
            },
          ),
          // Lens Switch Button
          // Show this button if there are MULTIPLE cameras with same lens direction
          // This allows cycling between Back Main, Back Wide, Back Tele etc.
          if (state.cameras
                  .where((c) =>
                      c.lensDirection == state.controller.description.lensDirection)
                  .length >
              1)
            TextButton.icon(
              onPressed: () => _camCubit.switchLens(),
              icon: const Icon(Icons.switch_camera_outlined, color: Colors.white),
              label: Text(
                 "LENS", // Or display current camera ID?
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                 backgroundColor: Colors.black45,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildZoomPresets(CameraReady state) {
    List<Widget> buttons = [];
    
    // Always add 1x button
    buttons.add(_zoomPresetButton(state, 1.0));
    
    // Add 0.5x if supported
    if (state.minZoomLevel <= 0.6) {
      buttons.insert(0, const SizedBox(width: 15));
      buttons.insert(0, _zoomPresetButton(state, 0.5));
    }
    
    // Add 2x if supported
    if (state.maxZoomLevel >= 2.0) {
      buttons.add(const SizedBox(width: 15));
      buttons.add(_zoomPresetButton(state, 2.0));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  Widget _zoomPresetButton(CameraReady state, double zoom) {
     final bool isSelected = (state.zoomLevel - zoom).abs() < 0.1;
     return GestureDetector(
       onTap: () => _camCubit.adjustZoom(zoom),
       child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
             color: isSelected ? Colors.white : Colors.black45,
             shape: BoxShape.circle,
             border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
             child: Text(
                "${zoom}x",
                style: TextStyle(
                   color: isSelected ? Colors.black : Colors.white,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                ),
             ),
          ),
       ),
     );
  }

  Widget _buildBottomBar(CameraReady state) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.only(bottom: 30, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           // Gallery Preview
           _lastImagePreview(state),
           
           // Shutter Button
           CaptureButton(
             size: 80,
             onPressed: () async {
               _flashController.forward(from: 0.0);
               await _camCubit.takePicture();
             },
           ),
           
           // Switch Camera (Front/Back)
           IconButton(
             icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
             onPressed: () => _camCubit.switchCamera(),
           ),
        ],
      ),
    );
  }

  Widget _lastImagePreview(CameraReady state) {
    if (state.lastImage != null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const GalleryScreen()),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: FileImage(state.lastImage!),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }
    return const SizedBox(width: 50, height: 50);
  }

  Widget _messageArea() {
    return BlocBuilder<CameraMessageCubit, CameraMessageState>(
      bloc: context.read<CameraCubit>().messageCubit,
      builder: (context, state) {
        if (state is NewCameraMessage && state.message.isValid()) {
          return Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.message.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _onPinchUpdate(ScaleUpdateDetails details, double currentZoom) {
    double zoomLevel = currentZoom * details.scale;
    _camCubit.adjustZoom(zoomLevel);
  }
}
