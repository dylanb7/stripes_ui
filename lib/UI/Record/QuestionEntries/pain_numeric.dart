import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class PainFacesWidget extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;
  final Numeric question;

  const PainFacesWidget({
    required this.questionsListener,
    required this.question,
    super.key,
  });

  @override
  ConsumerState<PainFacesWidget> createState() => _PainFacesWidgetState();
}

class _PainFacesWidgetState extends ConsumerState<PainFacesWidget> {
  final SliderListener _sliderListener = SliderListener();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final num? val = _getResponse();
      if (val != null) {
        _sliderListener.interacted();
      }
    });
    _sliderListener.addListener(_onSliderInteract);
  }

  void _onSliderInteract() {
    // Controller handles pending state automatically
  }

  @override
  void dispose() {
    _sliderListener.removeListener(_onSliderInteract);
    super.dispose();
  }

  num? _getResponse([QuestionEntryController? controller]) {
    if (controller != null) {
      final res = controller.response;
      if (res is NumericResponse) return res.response;
      return null;
    }
    final Response? res =
        widget.questionsListener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  void _saveValue(QuestionEntryController controller, double newValue) {
    controller.addResponse(NumericResponse(
      question: widget.question,
      stamp: controller.stamp,
      response: newValue,
    ));
  }

  void _setUnableToDetermine(QuestionEntryController controller) {
    if (_getResponse(controller) == -1) {
      controller.removeResponse();
      _sliderListener.hasInteracted = false;
    } else {
      _sliderListener.hasInteracted = false;
      _saveValue(controller, -1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.questionsListener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return QuestionEntryCard(
          styled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
            child: Column(
              children: [
                PainSlider(
                  initial: _getResponse(controller)?.toInt() ?? 0,
                  onChange: (val) {
                    setState(() => _saveValue(controller, val));
                  },
                  onSlide: (val) {
                    setState(() {
                      // Pending handled by controller
                      _saveValue(controller, val);
                    });
                  },
                  listener: _sliderListener,
                ),
                const SizedBox(height: AppPadding.small),
                Selection(
                  text: "Unable to determine pain level",
                  onClick: () => _setUnableToDetermine(controller),
                  selected: _getResponse(controller) == -1,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class PainNumericWidget extends ConsumerStatefulWidget {
  final QuestionsListener listener;
  final Numeric question;

  const PainNumericWidget({
    required this.listener,
    required this.question,
    super.key,
  });

  @override
  ConsumerState<PainNumericWidget> createState() => _PainNumericWidgetState();
}

class _PainNumericWidgetState extends ConsumerState<PainNumericWidget> {
  final SliderListener _sliderListener = SliderListener();
  double _value = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final num? val = _getResponse();
      if (val != null) {
        _value = val.toDouble();
        _sliderListener.interacted();
        if (mounted) setState(() {});
      }
    });
    _sliderListener.addListener(_onSliderInteract);
  }

  void _onSliderInteract() {
    // Pending handled by controller
  }

  @override
  void dispose() {
    _sliderListener.removeListener(_onSliderInteract);
    super.dispose();
  }

  num? _getResponse([QuestionEntryController? controller]) {
    if (controller != null) {
      final res = controller.response;
      if (res is NumericResponse) return res.response;
      return null;
    }
    final Response? res = widget.listener.fromQuestion(widget.question);
    if (res == null) return null;
    return (res as NumericResponse).response;
  }

  void _saveValue(QuestionEntryController controller, double newValue) {
    controller.addResponse(NumericResponse(
      question: widget.question,
      stamp: controller.stamp,
      response: newValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.listener,
      child: Builder(builder: (context) {
        final controller = QuestionEntryScope.of(context);
        return Column(
          children: [
            const SizedBox(height: AppPadding.xxl),
            QuestionEntryCard(
              styled: false,
              child: StripesSlider(
                onChange: (p0) {},
                onSlide: (val) {
                  setState(() {
                    _value = val;
                    _saveValue(controller, val);
                  });
                },
                listener: _sliderListener,
                min: 0,
                max: 10,
                minLabel: context.translate.painLevelZero,
                maxLabel: context.translate.painLevelFive,
                initial: _value.toInt(),
              ),
            ),
          ],
        );
      }),
    );
  }
}
