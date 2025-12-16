import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/UI/Record/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';

class BMSlider extends ConsumerStatefulWidget {
  final QuestionsListener listener;
  final Numeric question;

  const BMSlider({
    required this.listener,
    required this.question,
    super.key,
  });

  @override
  ConsumerState<BMSlider> createState() => _BMSliderState();
}

class _BMSliderState extends ConsumerState<BMSlider> {
  late List<Image> images;
  final SliderListener _sliderListener = SliderListener();
  double _value = 4;

  @override
  void initState() {
    super.initState();
    const List<String> paths = [
      'packages/stripes_ui/assets/images/poop1.png',
      'packages/stripes_ui/assets/images/poop2.png',
      'packages/stripes_ui/assets/images/poop3.png',
      'packages/stripes_ui/assets/images/poop4.png',
      'packages/stripes_ui/assets/images/poop5.png',
      'packages/stripes_ui/assets/images/poop6.png',
      'packages/stripes_ui/assets/images/poop7.png'
    ];
    images = paths.map((path) => Image.asset(path)).toList();

    _sliderListener.addListener(_onSliderInteract);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final num? val = _getResponse();
      if (val != null) {
        _sliderListener.interacted();
        _value = val.toDouble();
        if (mounted) setState(() {});
      }
    });
  }

  void _onSliderInteract() {
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
  void dispose() {
    _sliderListener.removeListener(_onSliderInteract);
    super.dispose();
  }

  num? _getResponse() {
    final Response? res = widget.listener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  void _saveValue(double newValue) {
    widget.listener.addResponse(NumericResponse(
      question: widget.question,
      stamp: dateToStamp(DateTime.now()),
      response: newValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> descriptors = [
      "Separate hard lumps, like nuts (hard to pass)",
      "Sausage-shaped but lumpy",
      "Like a sausage but with cracks on its surface",
      "Like a sausage or snake, smooth and soft",
      "Soft blobs with clear-cut edges (passed easily)",
      "Fluffy pieces with ragged edges, a mushy stool",
      "Liquid consistency with no solid pieces"
    ];

    return QuestionEntryScope(
      question: widget.question,
      listener: widget.listener,
      child: Column(
        children: [
          QuestionEntryCard(
            styled: false,
            child: Column(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 2.2,
                    child: images[_value.toInt() - 1],
                  ),
                ),
                if (_sliderListener.hasInteracted) ...[
                  SizedBox(
                    height: AppPadding.xxxl,
                    child: Text(
                      descriptors[_value.toInt() - 1],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ] else
                  const SizedBox(height: AppPadding.xl),
                const SizedBox(height: AppPadding.tiny),
                StripesSlider(
                  onChange: (p0) {},
                  onSlide: (val) {
                    setState(() {
                      _value = val;
                      _saveValue(val);
                    });
                  },
                  listener: _sliderListener,
                  hasLevelReminder: !_sliderListener.hasInteracted,
                  min: 1,
                  max: 7,
                  initial: _value.toInt(),
                ),
                const SizedBox(height: AppPadding.tiny),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppPadding.small),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.translate.hardTag,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      Text(
                        context.translate.softTag,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
