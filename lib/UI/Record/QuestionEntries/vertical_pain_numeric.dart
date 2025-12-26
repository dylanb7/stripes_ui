import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/base.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_entry_scope.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class VerticalPainFaces extends ConsumerStatefulWidget {
  final QuestionsListener questionsListener;
  final Numeric question;

  const VerticalPainFaces({
    required this.question,
    required this.questionsListener,
    super.key,
  });

  @override
  ConsumerState<VerticalPainFaces> createState() => _VerticalPainFacesState();
}

class _VerticalPainFacesState extends ConsumerState<VerticalPainFaces> {
  num? _getResponse(QuestionEntryController? controller) {
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

  void _saveValue(QuestionEntryController controller, int newValue) {
    controller.addResponse(NumericResponse(
      question: widget.question,
      stamp: controller.stamp,
      response: newValue,
    ));
  }

  void _onTap(QuestionEntryController controller, int index) {
    if (index == _getResponse(controller)?.toInt()) {
      controller.removeResponse();
    } else {
      _saveValue(controller, index);
    }
    setState(() {});
  }

  void _setUnableToDetermine(QuestionEntryController controller) {
    if (_getResponse(controller) == -1) {
      controller.removeResponse();
    } else {
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
        final num? selected = _getResponse(controller);

        return QuestionEntryCard(
          styled: false,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.tiny),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.tiny),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(11, (index) {
                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => _onTap(controller, index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.small),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Radio<int>.adaptive(
                                      value: index,
                                      groupValue: (selected ?? -1).toInt(),
                                      toggleable: true,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      onChanged: (value) =>
                                          _onTap(controller, index),
                                    ),
                                    const SizedBox(width: AppPadding.tiny),
                                    Text(
                                      "$index",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ).showCursorOnHover;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppPadding.small),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.tiny),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(5, (index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.small),
                                child: Text(
                                  context.translate.painLevelZero,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            if (index == 4) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.small),
                                child: Text(
                                  context.translate.painLevelFive,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.small),
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                        right: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                        bottom: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: AppPadding.small),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppPadding.tiny),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(5, (value) {
                            final Widget base = Container(
                              alignment: Alignment.center,
                              width: 45,
                              height: 45,
                              child: Image.asset(
                                "packages/stripes_ui/assets/images/pain_faces_$value.png",
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            );
                            if (value == 0 || value == 4) return base;
                            return Expanded(child: base);
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Selection(
                  text: "Unable to determine pain level",
                  onClick: () => _setUnableToDetermine(controller),
                  selected: selected == -1,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
