import 'package:flutter/material.dart';

class ZoomSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const ZoomSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ZoomSlider> createState() => _ZoomSliderState();
}

class _ZoomSliderState extends State<ZoomSlider> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: Colors.white,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
        ),
        child: Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
