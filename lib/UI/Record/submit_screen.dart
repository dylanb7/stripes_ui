import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/question_screen.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

final toggleProvider = StateProvider.autoDispose(
  (ref) => [false, false],
);

class SubmitScreen extends ConsumerWidget {
  final String type;

  final QuestionsListener questionsListener;

  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  final DateTime? submitTime;

  final bool isEdit;

  final String? desc;

  SubmitScreen(
      {required this.questionsListener,
      required this.type,
      this.submitTime,
      this.isEdit = false,
      this.desc,
      Key? key})
      : super(key: key) {
    if (submitTime != null) {
      _dateListener.date = submitTime!;
      _timeListener.time = TimeOfDay.fromDateTime(submitTime!);
    }
    if (desc != null) {
      _descriptionController.text = desc!;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestState state = ref.watch(testHolderProvider).state;
    final List<bool> toggles = ref.watch(toggleProvider);
    final isBlueRecord =
        (state == TestState.logs || state == TestState.logsSubmit) &&
            type == "Poo" &&
            !isEdit;

    return ProviderScope(
      overrides: [
        dateProvider.overrideWith((ref) => _dateListener),
        timeProvider.overrideWith((ref) => _timeListener),
      ],
      child: Column(
        children: [
          Text(
            isEdit
                ? AppLocalizations.of(context)!.editSubmitHeader(type)
                : AppLocalizations.of(context)!.submitHeader(type),
            style: lightBackgroundHeaderStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 40,
          ),
          Text('$state'),
          IgnorePointer(
            ignoring: isEdit,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DateWidget(),
                TimeWidget(),
              ],
            ),
          ),
          if (isBlueRecord) ...[
            const SizedBox(
              height: 18.0,
            ),
            Text(
              AppLocalizations.of(context)!.submitBlueQuestion,
              style: lightBackgroundStyle,
            ),
            const SizedBox(
              height: 8.0,
            ),
            ToggleButtons(
                onPressed: (index) => ref.read(toggleProvider.notifier).state =
                    [index == 0, index == 1],
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderColor: lightIconButton.withOpacity(0.4),
                selectedBorderColor: lightIconButton,
                selectedColor: Colors.white,
                fillColor: lightIconButton.withOpacity(0.5),
                color: lightIconButton,
                constraints: const BoxConstraints(
                  minHeight: 40.0,
                  minWidth: 80.0,
                ),
                isSelected: toggles,
                children: [
                  AppLocalizations.of(context)!.blueQuestionYes,
                  AppLocalizations.of(context)!.blueQuestionNo
                ].map((e) => Text(e)).toList())
          ],
          const SizedBox(
            height: 30,
          ),
          LongTextEntry(type: type, textController: _descriptionController),
          const SizedBox(
            height: 30,
          ),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: StripesRoundedButton(
                text: isEdit
                    ? AppLocalizations.of(context)!.editSubmitButtonText
                    : AppLocalizations.of(context)!.submitButtonText,
                onClick: () {
                  if (!isBlueRecord || toggles.contains(true)) {
                    _submitEntry(context, ref, isBlueRecord, toggles);
                  } else {
                    showSnack(
                        AppLocalizations.of(context)!.submitBlueQuestionError,
                        context);
                  }
                },
                light: false,
                rounding: 25.0,
              )),
          const SizedBox(
            height: 15,
          ),
        ],
      ),
    );
  }

  _submitEntry(BuildContext context, WidgetRef ref, bool blueRecord,
      List<bool> toggles) {
    final DateTime dateOfEntry =
        isEdit ? submitTime ?? _dateListener.date : _dateListener.date;
    final TimeOfDay timeOfEntry = _timeListener.time;
    final currentTime = DateTime.now();
    final int entryStamp = dateToStamp(DateTime(
        dateOfEntry.year,
        dateOfEntry.month,
        dateOfEntry.day,
        timeOfEntry.hour,
        timeOfEntry.minute,
        currentTime.second,
        currentTime.millisecond));
    final DetailResponse detailResponse = DetailResponse(
      description: _descriptionController.text,
      responses: questionsListener.questions.values.toList(growable: false),
      stamp: isEdit ? dateToStamp(submitTime!) : entryStamp,
      detailType: type,
    );
    if (isEdit) {
      ref.read(stampProvider)?.updateStamp(detailResponse);
    } else {
      ref.read(stampProvider)?.addStamp(detailResponse);
      if (blueRecord) {
        ref
            .read(testHolderProvider)
            .obj!
            .addLog(BMTestLog(response: detailResponse, isBlue: toggles.first));
      }
    }
    context.pop();
  }
}

class LongTextEntry extends StatelessWidget {
  final TextEditingController textController;

  final String type;

  const LongTextEntry(
      {required this.type, required this.textController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.submitDescriptionTag,
            style: lightBackgroundHeaderStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 5,
          ),
          SizedBox(
            height: 120,
            child: TextField(
              controller: textController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  hintText: AppLocalizations.of(context)!
                      .submitDescriptionPlaceholder,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0)),
            ),
          ),
        ],
      ),
    );
  }
}
