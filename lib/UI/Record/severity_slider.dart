import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class SliderListener extends ChangeNotifier {
  bool hasInteracted = false;

  interacted() {
    hasInteracted = true;
    notifyListeners();
  }
}

class StripesSlider extends StatefulWidget {
  final String? minLabel, maxLabel;

  final int min, max;

  final int? initial;

  final bool hasInstruction, hasLevelReminder;

  final SliderListener? listener;

  final Function(double) onChange;

  final Function(double)? onSlide;

  const StripesSlider(
      {required this.onChange,
      this.onSlide,
      this.min = 1,
      this.max = 5,
      this.hasInstruction = true,
      this.hasLevelReminder = true,
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
    final Color primary = Theme.of(context).primaryColor;
    final Color disabled = Theme.of(context).disabledColor;

    final Widget sliderBox = DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          color: listener.hasInteracted ? primary : disabled),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Row(children: [
            Visibility(
              visible: value.toInt() != widget.min,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: GestureDetector(
                child: Text(
                  '${widget.min}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: listener.hasInteracted
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  setState(() {
                    if (!listener.hasInteracted) {
                      listener.interacted();
                    }
                    value = widget.min.toDouble();
                    widget.onChange(value);
                  });
                },
              ).showCursorOnHover,
            ),
            Expanded(
              child: Center(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8.0,
                    activeTrackColor: Theme.of(context).colorScheme.onPrimary,
                    allowedInteraction: SliderInteraction.tapAndSlide,
                    inactiveTrackColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    thumbShape: CustomThumb(
                      thumbRadius: 22.0,
                      color: Theme.of(context).colorScheme.onPrimary,
                      min: widget.min,
                      max: widget.max,
                    ),
                    tickMarkShape:
                        const LineSliderTickMarkShape(tickMarkRadius: 2.0),
                    activeTickMarkColor: Theme.of(context).colorScheme.primary,
                    inactiveTickMarkColor: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.8),
                  ),
                  child: Slider(
                    value: value,
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    thumbColor: listener.hasInteracted ? primary : disabled,
                    divisions: widget.max - widget.min,
                    onChangeStart: (val) {
                      if (!listener.hasInteracted) {
                        setState(() {
                          listener.interacted();
                          value = val;
                          widget.onChange(val);
                          if (widget.onSlide != null) {
                            widget.onSlide!(val);
                          }
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
            Visibility(
                visible: value.toInt() != widget.max,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: GestureDetector(
                  child: Text(
                    '${widget.max}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: listener.hasInteracted
                            ? Theme.of(context).colorScheme.onPrimary
                            : null),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    setState(() {
                      if (!listener.hasInteracted) {
                        listener.interacted();
                      }
                      value = widget.max.toDouble();
                      widget.onChange(value);
                    });
                  },
                ).showCursorOnHover),
          ]),
          if (widget.minLabel != null && widget.maxLabel != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.minLabel ?? AppLocalizations.of(context)!.mildTag,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: listener.hasInteracted
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                ),
                Text(
                  widget.maxLabel ?? AppLocalizations.of(context)!.severeTag,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: listener.hasInteracted
                          ? Theme.of(context).colorScheme.onPrimary
                          : null),
                ),
              ],
            ),
        ]),
      ),
    );

    if (!widget.hasInstruction) return sliderBox;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hasLevelReminder) ...[
          Visibility(
            visible: !listener.hasInteracted,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              AppLocalizations.of(context)!.levelReminder,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
        ],
        sliderBox
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

class MoodSlider extends StatefulWidget {
  final String? minLabel, maxLabel;

  final int? initial;

  final SliderListener? listener;

  final Function(double) onChange;

  final Function(double)? onSlide;

  const MoodSlider(
      {required this.onChange,
      this.onSlide,
      this.initial,
      this.minLabel,
      this.maxLabel,
      this.listener,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _MoodSliderState();
  }
}

class _MoodSliderState extends State<MoodSlider> {
  late final SliderListener listener;

  late double value;

  @override
  void initState() {
    value = widget.initial?.toDouble() ?? 5.0;
    listener = widget.listener ?? SliderListener();
    listener.addListener(_state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = (value / 2).floor();
    final Color primary = Theme.of(context).primaryColor;
    final Color disabled = Theme.of(context).disabledColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          visible: !listener.hasInteracted,
          maintainSize: true,
          maintainState: true,
          maintainAnimation: true,
          child: Text(
            AppLocalizations.of(context)!.levelReminder,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              color: listener.hasInteracted
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(
              height: 2.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Row(
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: from(5 - index, index == selectedIndex),
                  ),
                ),
              ),
            ),
            Row(children: [
              const SizedBox(
                width: 12.0,
              ),
              Visibility(
                  visible: value.toInt() != 0,
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  child: GestureDetector(
                    child: Text(
                      '1',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        if (!listener.hasInteracted) {
                          listener.interacted();
                        }
                        value = 0.0;
                        widget.onChange(value);
                        if (widget.onSlide != null) widget.onSlide!(value);
                      });
                    },
                  ).showCursorOnHover),
              Expanded(
                child: Center(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      activeTrackColor: Theme.of(context).colorScheme.onPrimary,
                      inactiveTrackColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      thumbShape: CustomThumb(
                        thumbRadius: 20.0,
                        color: Theme.of(context).colorScheme.onPrimary,
                        min: 1,
                        max: 10,
                      ),
                      activeTickMarkColor:
                          Theme.of(context).colorScheme.primary,
                      inactiveTickMarkColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Slider(
                      value: value,
                      min: 1.0,
                      max: 10.0,
                      thumbColor: listener.hasInteracted ? primary : disabled,
                      divisions: 9,
                      onChangeStart: (val) {
                        if (!listener.hasInteracted) {
                          widget.onChange(val);
                          if (widget.onSlide != null) widget.onSlide!(value);
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
              Visibility(
                  visible: value.toInt() != 10.0,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: GestureDetector(
                    child: Text(
                      '10',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        if (!listener.hasInteracted) {
                          listener.interacted();
                        }
                        value = 10.0;
                        widget.onChange(value);
                        if (widget.onSlide != null) widget.onSlide!(value);
                      });
                    },
                  ).showCursorOnHover),
              const SizedBox(
                width: 12.0,
              ),
            ]),
          ]),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.minLabel ?? "",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              widget.maxLabel ?? "",
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
        const SizedBox(
          height: 6.0,
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
              !listener.hasInteracted
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)
                  : isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
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

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color disabled = Theme.of(context).disabledColor;
    final Color onPrimary = Theme.of(context).colorScheme.onPrimary;
    final List<String> hurtLevels = [
      AppLocalizations.of(context)!.painLevelZero,
      AppLocalizations.of(context)!.painLevelOne,
      AppLocalizations.of(context)!.painLevelTwo,
      AppLocalizations.of(context)!.painLevelThree,
      AppLocalizations.of(context)!.painLevelFour,
      AppLocalizations.of(context)!.painLevelFive,
    ];
    final int selectedIndex = (value / 2).floor();
    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          color: listener.hasInteracted ? primary : disabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            listener.hasInteracted
                ? hurtLevels[selectedIndex]
                : AppLocalizations.of(context)!.levelReminder,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: listener.hasInteracted ? onPrimary : null),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6.0,
          ),
          Row(
            children: List.generate(
              6,
              (index) => Expanded(
                child: from(index, index == selectedIndex),
              ),
            ),
          ),
          Row(children: [
            Visibility(
                visible: value.toInt() != 0,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: SizedBox(
                  width: 22.0,
                  child: GestureDetector(
                    child: Text(
                      '0',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: listener.hasInteracted ? onPrimary : null),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        if (!listener.hasInteracted) {
                          listener.interacted();
                        }
                        value = 0.0;
                        widget.onChange(value);
                        if (widget.onSlide != null) widget.onSlide!(value);
                      });
                    },
                  ),
                ).showCursorOnHover),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8.0,
                  activeTrackColor: Theme.of(context).colorScheme.onPrimary,
                  allowedInteraction: SliderInteraction.tapAndSlide,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  thumbShape: CustomThumb(
                    thumbRadius: 22.0,
                    color: Theme.of(context).colorScheme.onPrimary,
                    min: 0,
                    max: 10,
                  ),
                  tickMarkShape:
                      const LineSliderTickMarkShape(tickMarkRadius: 2.0),
                  activeTickMarkColor: Theme.of(context).colorScheme.primary,
                  inactiveTickMarkColor: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.8),
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 10.0,
                  thumbColor: listener.hasInteracted ? primary : disabled,
                  divisions: 10,
                  onChangeStart: (val) {
                    if (!listener.hasInteracted) {
                      widget.onChange(val);
                      if (widget.onSlide != null) widget.onSlide!(value);
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
            Visibility(
                visible: value.toInt() != 10.0,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: SizedBox(
                  width: 22.0,
                  child: GestureDetector(
                    child: Text(
                      '10',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: listener.hasInteracted ? onPrimary : null),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      setState(() {
                        if (!listener.hasInteracted) {
                          listener.interacted();
                        }
                        value = 10.0;
                        widget.onChange(value);
                        if (widget.onSlide != null) widget.onSlide!(value);
                      });
                    },
                  ),
                ).showCursorOnHover),
          ]),
        ]),
      ),
    );
  }

  Widget from(int index, bool isSelected) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkResponse(
        onTap: () {
          setState(() {
            if (!listener.hasInteracted) {
              listener.interacted();
            }
            value = index.toDouble() * 2;
            widget.onChange(value);
            if (widget.onSlide != null) widget.onSlide!(value);
          });
        },
        containedInkWell: true,
        borderRadius: BorderRadius.circular(double.infinity),
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(double.infinity),
          ),
        ),
        child: SvgPicture.asset(
          'packages/stripes_ui/assets/svg/pain_face_$index.svg',
          colorFilter: ColorFilter.mode(
              !listener.hasInteracted
                  ? Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)
                  : isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.3),
              BlendMode.srcIn),
        ),
      ),
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
  final Color color;

  const CustomThumb({
    required this.thumbRadius,
    required this.color,
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
      ..color = color
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

class LineSliderTickMarkShape extends SliderTickMarkShape {
  const LineSliderTickMarkShape({
    this.tickMarkRadius,
  });

  final double? tickMarkRadius;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    assert(sliderTheme.trackHeight != null);
    return Size.fromRadius(tickMarkRadius ?? sliderTheme.trackHeight! / 2.8);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    Color? begin;
    Color? end;
    switch (textDirection) {
      case TextDirection.ltr:
        final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
        begin = isTickMarkRightOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkRightOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
      case TextDirection.rtl:
        final bool isTickMarkLeftOfThumb = center.dx < thumbCenter.dx;
        begin = isTickMarkLeftOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkLeftOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
    }
    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation)!
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double tickMarkRadius = getPreferredSize(
          isEnabled: isEnabled,
          sliderTheme: sliderTheme,
        ).width /
        2;
    if (tickMarkRadius > 0) {
      context.canvas.drawLine(Offset(center.dx, center.dy - tickMarkRadius),
          Offset(center.dx, center.dy + tickMarkRadius), paint);
    }
  }
}
