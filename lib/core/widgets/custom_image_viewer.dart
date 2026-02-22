import 'package:flutter/material.dart';

class CustomImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;

  const CustomImageViewer({super.key, required this.imageProvider});

  @override
  State<CustomImageViewer> createState() => _CustomImageViewerState();
}

class _CustomImageViewerState extends State<CustomImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    Matrix4 currentMatrix = _transformationController.value;
    double currentScale = currentMatrix.getMaxScaleOnAxis();

    double targetScale = 1.0;
    
    // Check if the current scale matches one of our presets (within a small margin)
    bool isPreset1 = (currentScale - 2.5).abs() < 0.1;
    bool isPreset2 = (currentScale - 5.0).abs() < 0.1;

    if (currentScale > 1.05 && !isPreset1 && !isPreset2) {
      // If manually zoomed (pinch-to-zoom) to a non-preset level, reset to 1.0
      targetScale = 1.0;
    } else if (currentScale < 1.9) {
      // Step 1: 1.0 -> 2.5
      targetScale = 2.5;
    } else if (currentScale < 3.9) {
      // Step 2: 2.5 -> 5.0
      targetScale = 5.0;
    } else {
      // Reset: 5.0 -> 1.0
      targetScale = 1.0;
    }

    if (targetScale == 1.0) {
      _animateToMatrix(Matrix4.identity());
      return;
    }

    final Offset tapPosition = _doubleTapDetails!.localPosition;
    final double scaleChange = targetScale / currentScale;

    final Matrix4 zoomMatrix = Matrix4.identity()
      ..translate(tapPosition.dx, tapPosition.dy)
      ..scale(scaleChange)
      ..translate(-tapPosition.dx, -tapPosition.dy);

    final Matrix4 endMatrix = zoomMatrix * currentMatrix;

    _animateToMatrix(endMatrix);
  }

  void _animateToMatrix(Matrix4 endMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 5.0,
            child: Image(
              image: widget.imageProvider,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
