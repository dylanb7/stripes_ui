import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class SliderListener extends ChangeNotifier {
  bool interact = false;

  interacted() {
    interact = true;
    notifyListeners();
  }
}

class StripesSlider extends StatefulWidget {
  final String? minLabel, maxLabel;

  final int min, max;

  final int? initial;

  final SliderListener? listener;

  final Function(double) onChange;

  final Function(double)? onSlide;

  const StripesSlider(
      {required this.onChange,
      this.onSlide,
      this.min = 1,
      this.max = 5,
      this.initial,
      this.minLabel,
      this.maxLabel,
      this.listener,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _StripesSliderState();
  }
}

class _StripesSliderState extends State<StripesSlider> {
  late final SliderListener listener;

  late double value;

  @override
  void initState() {
    value =
        (widget.initial ?? ((widget.max - widget.min).toDouble() / 2.0).round())
            .toDouble();
    listener = widget.listener ?? SliderListener();
    listener.addListener(_state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          visible: !listener.interact,
          child: Text(
            AppLocalizations.of(context)!.levelReminder,
            textAlign: TextAlign.center,
            style: lightBackgroundHeaderStyle.copyWith(
                fontWeight: FontWeight.bold, color: darkIconButton),
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              color: listener.interact ? backgroundStrong : disabled),
          child: Row(children: [
            if (value.toInt() != widget.min) ...[
              const SizedBox(
                width: 12.0,
              ),
              GestureDetector(
                child: Text(
                  '${widget.min}',
                  style: darkBackgroundStyle.copyWith(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  setState(() {
                    if (!listener.interact) {
                      listener.interacted();
                    }
                    value = widget.min.toDouble();
                    widget.onChange(value);
                  });
                },
              ).showCursorOnHover
            ],
            Expanded(
              child: Center(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white.withOpacity(1),
                    inactiveTrackColor: Colors.white.withOpacity(.5),
                    trackHeight: 4.0,
                    thumbShape: CustomThumb(
                      thumbRadius: 20.0,
                      min: widget.min,
                      max: widget.max,
                    ),
                    overlayColor: Colors.white.withOpacity(.4),
                    //valueIndicatorColor: Colors.white,
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: value,
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    thumbColor: listener.interact ? lightIconButton : disabled,
                    divisions: widget.max - widget.min,
                    onChangeStart: (val) {
                      if (!listener.interact) {
                        setState(() {
                          listener.interacted();
                          value = val;
                        });
                      }
                    },
                    onChangeEnd: (value) {
                      widget.onChange(value);
                    },
                    onChanged: (double val) {
                      setState(() {
                        value = val;
                        if (widget.onSlide != null) {
                          widget.onSlide!(val);
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            if (value.toInt() != widget.max) ...[
              GestureDetector(
                child: Text(
                  '${widget.max}',
                  style: darkBackgroundStyle.copyWith(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  setState(() {
                    if (!listener.interact) {
                      listener.interacted();
                    }
                    value = widget.max.toDouble();
                    widget.onChange(value);
                  });
                },
              ).showCursorOnHover,
              const SizedBox(
                width: 12.0,
              ),
            ],
          ]),
        ),
        const SizedBox(
          height: 6.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.minLabel ?? AppLocalizations.of(context)!.mildTag,
                style: lightBackgroundStyle,
              ),
              Text(
                widget.maxLabel ?? AppLocalizations.of(context)!.severeTag,
                style: lightBackgroundStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    listener.removeListener(_state);
    super.dispose();
  }
}

class CustomThumb extends SliderComponentShape {
  final double thumbRadius;
  final int min;
  final int max;

  const CustomThumb({
    required this.thumbRadius,
    this.min = 0,
    this.max = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  String getValue(double value) {
    return (min + (max - min) * value).round().toString();
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = Colors.white //Thumb Background Color
      ..style = PaintingStyle.fill;

    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius * .8,
        fontWeight: FontWeight.w700,
        color: sliderTheme.thumbColor, //Text Color of Value on Thumb
      ),
      text: getValue(value),
    );

    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawCircle(center, thumbRadius * .9, paint);
    tp.paint(canvas, textCenter);
  }
}

class PainSlider extends StatefulWidget {
  final String? minLabel, maxLabel;

  final int? initial;

  final SliderListener? listener;

  final Function(double) onChange;

  final Function(double)? onSlide;

  const PainSlider(
      {required this.onChange,
      this.onSlide,
      this.initial,
      this.minLabel,
      this.maxLabel,
      this.listener,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _PainSliderState();
  }
}

class _PainSliderState extends State<PainSlider> {
  late final SliderListener listener;

  late double value;

  @override
  void initState() {
    value = widget.initial?.toDouble() ?? 5.0;
    listener = widget.listener ?? SliderListener();
    listener.addListener(_state);
    super.initState();
  }

  final List<String> hurtLevels = [
    'No Hurt',
    'Hurts Little Bit',
    'Hurts Little More',
    'Hurts Even More',
    'Hurts Whole Lot',
    'Hurts Worst'
  ];

  @override
  Widget build(BuildContext context) {
    int selectedIndex = (value / 2).floor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          visible: !listener.interact,
          child: Text(
            AppLocalizations.of(context)!.levelReminder,
            textAlign: TextAlign.center,
            style: lightBackgroundHeaderStyle.copyWith(
                fontWeight: FontWeight.bold, color: darkIconButton),
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              color: listener.interact ? backgroundStrong : disabled),
          child: Column(children: [
            if (listener.interact)
              Text(
                hurtLevels[selectedIndex],
                style: darkBackgroundStyle,
              ),
            Row(
                children: List.generate(
                    6, (index) => from(index, index == selectedIndex))),
            Row(children: [
              const SizedBox(
                width: 12.0,
              ),
              if (value.toInt() != 0) ...[
                GestureDetector(
                  child: Text(
                    '0',
                    style: darkBackgroundStyle.copyWith(fontSize: 16.0),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      if (!listener.interact) {
                        listener.interacted();
                      }
                      value = 0.0;
                      widget.onChange(value);
                    });
                  },
                ).showCursorOnHover
              ],
              Expanded(
                child: Center(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white.withOpacity(1),
                      inactiveTrackColor: Colors.white.withOpacity(.5),
                      trackHeight: 4.0,
                      thumbShape: const CustomThumb(
                        thumbRadius: 20.0,
                        min: 0,
                        max: 10,
                      ),
                      overlayColor: Colors.white.withOpacity(.4),
                      //valueIndicatorColor: Colors.white,
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: value,
                      min: 0.0,
                      max: 10.0,
                      thumbColor:
                          listener.interact ? lightIconButton : disabled,
                      divisions: 10,
                      onChangeStart: (val) {
                        if (!listener.interact) {
                          setState(() {
                            listener.interacted();
                            value = val;
                          });
                        }
                      },
                      onChangeEnd: (value) {
                        widget.onChange(value);
                      },
                      onChanged: (double val) {
                        setState(() {
                          value = val;
                          if (widget.onSlide != null) {
                            widget.onSlide!(val);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              if (value.toInt() != 10.0) ...[
                GestureDetector(
                  child: Text(
                    '10',
                    style: darkBackgroundStyle.copyWith(fontSize: 16.0),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      if (!listener.interact) {
                        listener.interacted();
                      }
                      value = 10.0;
                      widget.onChange(value);
                    });
                  },
                ).showCursorOnHover,
              ],
              const SizedBox(
                width: 12.0,
              ),
            ]),
          ]),
        ),
        const SizedBox(
          height: 6.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.minLabel ?? AppLocalizations.of(context)!.mildTag,
                style: lightBackgroundStyle,
              ),
              Text(
                widget.maxLabel ?? AppLocalizations.of(context)!.severeTag,
                style: lightBackgroundStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget from(int index, bool isSelected) {
    return AspectRatio(
        aspectRatio: 1,
        child: SvgPicture.asset(
          'packages/stripes_ui/assets/svg/pain_face_$index.svg',
          colorFilter: ColorFilter.mode(
              !listener.interact
                  ? darkBackgroundText.withOpacity(0.5)
                  : isSelected
                      ? darkBackgroundText
                      : darkBackgroundText.withOpacity(0.7),
              BlendMode.srcIn),
        ));
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    listener.removeListener(_state);
    super.dispose();
  }
}
