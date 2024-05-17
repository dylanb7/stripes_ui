import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BMSlider extends ConsumerStatefulWidget {
  final QuestionsListener listener;

  final Numeric question;

  const BMSlider({required this.listener, required this.question, super.key});

  @override
  ConsumerState createState() => _BMSliderState();
}

class _BMSliderState extends ConsumerState<BMSlider> {
  late List<Image> images;

  late SliderListener listener;

  double value = 4;

  @override
  void initState() {
    const List<String> paths = [
      'packages/stripes_ui/assets/images/poop1.png',
      'packages/stripes_ui/assets/images/poop2.png',
      'packages/stripes_ui/assets/images/poop3.png',
      'packages/stripes_ui/assets/images/poop4.png',
      'packages/stripes_ui/assets/images/poop5.png',
      'packages/stripes_ui/assets/images/poop6.png',
      'packages/stripes_ui/assets/images/poop7.png'
    ];
    images = paths
        .map((path) => Image.asset(
              path,
            ))
        .toList();
    listener = SliderListener();

    final Response? res = widget.listener.fromQuestion(widget.question);
    bool pending = false;
    if (res != null) {
      listener.hasInteracted = true;
      value = (res as NumericResponse).response.toDouble();
    } else {
      pending = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (pending) {
        widget.listener.addPending(widget.question);
      }
    });
    listener.addListener(_interactListener);

    super.initState();
  }

  _interactListener() {
    widget.listener.removePending(widget.question);
  }

  @override
  void didChangeDependencies() {
    for (Image image in images) {
      precacheImage(image.image, context);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 250, child: images[value.toInt() - 1]),
        StripesSlider(
          onChange: (p0) {},
          onSlide: (val) {
            setState(() {
              value = val;
              _saveValue();
            });
          },
          listener: listener,
          min: 1,
          max: 7,
          minLabel: AppLocalizations.of(context)!.hardTag,
          maxLabel: AppLocalizations.of(context)!.softTag,
          initial: value.toInt(),
        ),
      ],
    );
  }

  _saveValue() {
    widget.listener.addResponse(NumericResponse(
        question: widget.question,
        stamp: dateToStamp(DateTime.now()),
        response: value));
  }

  @override
  void dispose() {
    listener.removeListener(_interactListener);
    super.dispose();
  }
}
