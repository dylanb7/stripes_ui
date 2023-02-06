import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class SliderListener {
  bool interact = false;

  interacted() {
    interact = true;
  }
}

class StripesSlider extends StatefulWidget {
  final String minLabel, maxLabel;

  final int min, max;

  final int? initial;

  final SliderListener? listener;

  final Function(double) onChange;

  const StripesSlider(
      {required this.onChange,
      this.min = 1,
      this.max = 5,
      this.initial,
      this.minLabel = '1 (Mild)',
      this.maxLabel = '(Severe) 5',
      this.listener,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _StripesSliderState();
  }
}

class _StripesSliderState extends State<StripesSlider> with ChangeNotifier {
  late final SliderListener listener;

  late double value;

  @override
  void initState() {
    value = (widget.initial ?? ((widget.max - widget.min) / 2.0).round())
        .toDouble();
    listener = widget.listener ?? SliderListener();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!listener.interact)
            const Text(
              'Select a Value',
              textAlign: TextAlign.center,
              style: lightBackgroundStyle,
            ),
          Slider(
            value: value,
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            thumbColor: Colors.grey,
            divisions: widget.max - widget.min + 1,
            onChangeStart: (_) {
              if (!listener.interact) {
                setState(() {
                  listener.interacted();
                });
              }
            },
            onChangeEnd: (value) {
              widget.onChange(value);
            },
            label: '${value.toInt()}',
            onChanged: (double val) {
              setState(() {
                value = val;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.minLabel,
                  style: lightBackgroundStyle,
                ),
                Text(
                  widget.maxLabel,
                  style: lightBackgroundStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
