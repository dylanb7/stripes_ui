import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:stripes_ui/Util/animated_painter.dart';
import 'package:stripes_ui/Util/text_styles.dart';

class PinField extends StatelessWidget {
  final Function(String) onFilled;

  final bool errorText;

  final bool loading;

  final bool accepted;

  const PinField(
      {required this.onFilled,
      this.errorText = false,
      this.loading = false,
      this.accepted = false,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        const Spacer(),
        SizedBox(
            width: 300,
            child: Column(children: [
              PinCodeTextField(
                appContext: context,
                autoFocus: true,
                length: 4,
                onChanged: (val) {},
                textStyle: lightBackgroundStyle.copyWith(fontSize: 44),
                animationType: AnimationType.scale,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: false,
                onCompleted: (val) {
                  onFilled(val);
                },
              ),
              const SizedBox(
                height: 10,
              ),
            ])),
        const Spacer(),
      ]),
      if (errorText)
        Column(
          children: [
            Text(
              'We do not recognize that access code.',
              style: errorStyleTitle,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              'Please try again or tap "Can\'t find your access code?" below.',
              style: errorStyle,
            ),
          ],
        ),
      if (loading)
        const SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(),
        ),
      if (accepted) const AnimatedCheck(),
    ]);
  }
}

class AnimatedCheck extends StatefulWidget {
  static const checkDuration = Duration(milliseconds: 400);

  const AnimatedCheck({Key? key}) : super(key: key);

  @override
  State createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: AnimatedCheck.checkDuration,
        lowerBound: 0.0,
        upperBound: 1.0)
      ..addListener(() {
        setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.forward();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 60,
      child: CustomPaint(
        painter: AnimatedPainter(
            progress: _controller.value,
            path: (Size size) {
              final Path path = Path();
              path.moveTo(size.width * 0.81, size.height * 0.11);
              path.cubicTo(
                  size.width * 0.81,
                  size.height * 0.11,
                  size.width * 0.38,
                  size.height * 0.65,
                  size.width * 0.38,
                  size.height * 0.65);
              path.cubicTo(
                  size.width * 0.38,
                  size.height * 0.65,
                  size.width * 0.19,
                  size.height * 0.42,
                  size.width * 0.19,
                  size.height * 0.42);
              path.cubicTo(size.width * 0.19, size.height * 0.42, 0,
                  size.height * 0.66, 0, size.height * 0.66);
              path.cubicTo(0, size.height * 0.66, size.width * 0.38,
                  size.height * 1.11, size.width * 0.38, size.height * 1.11);
              path.cubicTo(size.width * 0.38, size.height * 1.11, size.width,
                  size.height * 0.34, size.width, size.height * 0.34);
              path.cubicTo(size.width, size.height * 0.34, size.width * 0.81,
                  size.height * 0.11, size.width * 0.81, size.height * 0.11);
              path.cubicTo(
                  size.width * 0.81,
                  size.height * 0.11,
                  size.width * 0.81,
                  size.height * 0.11,
                  size.width * 0.81,
                  size.height * 0.11);
              path.moveTo(size.width * 0.38, size.height);
              path.cubicTo(size.width * 0.38, size.height, size.width * 0.09,
                  size.height * 0.66, size.width * 0.09, size.height * 0.66);
              path.cubicTo(
                  size.width * 0.09,
                  size.height * 0.66,
                  size.width * 0.19,
                  size.height * 0.53,
                  size.width * 0.19,
                  size.height * 0.53);
              path.cubicTo(
                  size.width * 0.19,
                  size.height * 0.53,
                  size.width * 0.38,
                  size.height * 0.75,
                  size.width * 0.38,
                  size.height * 0.75);
              path.cubicTo(
                  size.width * 0.38,
                  size.height * 0.75,
                  size.width * 0.81,
                  size.height * 0.22,
                  size.width * 0.81,
                  size.height * 0.22);
              path.cubicTo(
                  size.width * 0.81,
                  size.height * 0.22,
                  size.width * 0.91,
                  size.height * 0.34,
                  size.width * 0.91,
                  size.height * 0.34);
              path.cubicTo(
                  size.width * 0.91,
                  size.height * 0.34,
                  size.width * 0.38,
                  size.height,
                  size.width * 0.38,
                  size.height);
              path.cubicTo(size.width * 0.38, size.height, size.width * 0.38,
                  size.height, size.width * 0.38, size.height);
              return path;
            },
            paintColor: Theme.of(context).primaryColor),
      ),
    );
  }
}
