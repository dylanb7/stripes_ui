import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/session_graph.dart';

import 'package:stripes_ui/Models/pain_intensity.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_intensity_selector.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/severity_slider.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class PainIntensityWidget extends StatelessWidget {
  final SessionGraph graph;
  final Numeric question;

  const PainIntensityWidget({
    required this.graph,
    required this.question,
    super.key,
  });

  @override
  Widget build(BuildContext context) => QuestionEntryScope(
    question: question,
    listener: graph,
    child: Builder(
      builder: (context) {
        final controller = QuestionEntryScope.of(context);
        final response = controller.response;
        final score = response is NumericResponse ? response.response : null;
        final selectedBand = PainIntensityBand.fromScore(score);

        void save(num value) => controller.addResponse(
          NumericResponse(
            question: question,
            stamp: response?.stamp ?? controller.stamp,
            id: response?.id,
            group: response?.group,
            response: value,
          ),
        );

        final control = Center(
          child: ConstrainedBox(
            key: const ValueKey('compact-pain-level-control'),
            constraints: const BoxConstraints(maxWidth: 520),
            child: PainIntensitySelector(
              selectedBand: selectedBand,
              notSure: score == -1,
              onBandSelected: (band) {
                // Merely reopening/reselecting an old answer must not round it.
                if (band != selectedBand) save(band.representativeScore);
              },
              onNotSure: () {
                if (score == -1) {
                  controller.removeResponse();
                } else {
                  save(-1);
                }
              },
            ),
          ),
        );
        if (CompactRecordQuestions.maybeOf(context) != null) {
          final translated =
              QuestionsLocalizations.of(context)?.translateQuestion(question) ??
              question;
          return CompactRecordQuestion(
            prompt: translated.prompt,
            child: control,
          );
        }
        return QuestionEntryCard(
          styled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
            child: control,
          ),
        );
      },
    ),
  );
}

/// Retained for callers using the old widget name; renders the range selector.
class PainFacesWidget extends PainIntensityWidget {
  const PainFacesWidget({
    required super.graph,
    required super.question,
    super.key,
  });
}

class PainNumericWidget extends ConsumerStatefulWidget {
  final SessionGraph listener;
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
    controller.addResponse(
      NumericResponse(
        question: widget.question,
        stamp: controller.stamp,
        response: newValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionEntryScope(
      question: widget.question,
      listener: widget.listener,
      child: Builder(
        builder: (context) {
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
        },
      ),
    );
  }
}
