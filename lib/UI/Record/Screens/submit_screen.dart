import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/date_time_entry.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';

import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String type;

  final QuestionsListener questionsListener;

  const SubmitScreen(
      {required this.questionsListener, required this.type, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SubmitScreenState();
}

class SubmitScreenState extends ConsumerState<SubmitScreen> {
  final DateListener _dateListener = DateListener();

  final TimeListener _timeListener = TimeListener();

  final TextEditingController _descriptionController = TextEditingController();

  bool isLoading = false;

  late final bool isEdit;

  late final Timer _updateSubmitTime;

  @override
  void initState() {
    isEdit = widget.questionsListener.editId != null;
    if (widget.questionsListener.submitTime != null) {
      _dateListener.date = widget.questionsListener.submitTime!;
      _timeListener.time =
          TimeOfDay.fromDateTime(widget.questionsListener.submitTime!);
    }
    if (widget.questionsListener.description != null) {
      _descriptionController.text = widget.questionsListener.description!;
    }
    widget.questionsListener.addListener(_state);
    _dateListener.addListener(_setSubmissionTime);
    _timeListener.addListener(_setSubmissionTime);
    _descriptionController.addListener(_updateDesc);
    _updateSubmitTime = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          final DateTime current = DateTime.now();
          _dateListener.date = current;
          _timeListener.time = TimeOfDay.fromDateTime(current);
        });
      }
    });
    super.initState();
  }

  _setSubmissionTime() {
    _updateSubmitTime.cancel();
    widget.questionsListener.submitTime = _combinedTime();
  }

  _updateDesc() {
    widget.questionsListener.description = _descriptionController.text;
  }

  DateTime _combinedTime() {
    if (isEdit && widget.questionsListener.submitTime != null) {
      return widget.questionsListener.submitTime!;
    }

    final Period? period = ref
        .read(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .valueOrNull
        ?.path
        ?.period;
    final DateTime date = _dateListener.date;
    final TimeOfDay time = _timeListener.time;
    final currentTime = DateTime.now();
    final DateTime combinedEntry = DateTime(date.year, date.month, date.day,
        time.hour, time.minute, currentTime.second, currentTime.millisecond);
    return period?.getValue(combinedEntry) ?? combinedEntry;
  }

  _state() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.questionsListener.removeListener(_state);
    _dateListener.removeListener(_setSubmissionTime);
    _timeListener.removeListener(_setSubmissionTime);
    _descriptionController.removeListener(_updateDesc);
    _updateSubmitTime.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final String localizedType =
        localizations?.value(widget.type) ?? widget.type;

    final Period? period = ref
        .watch(pagesByPath(PagesByPathProps(pathName: widget.type)))
        .valueOrNull
        ?.path
        ?.period;

    List<Question> testAdditions = ref
            .watch(testsHolderProvider)
            .valueOrNull
            ?.testsRepo
            ?.getRecordAdditions(context, widget.type) ??
        [];

    if (isEdit) {
      testAdditions = testAdditions
          .where((q) => widget.questionsListener.fromQuestion(q) != null)
          .toList();
    }

    return Column(
      children: [
        const SizedBox(
          height: AppPadding.small,
        ),
        Text(
          isEdit
              ? context.translate.editSubmitHeader(localizedType)
              : context.translate.submitHeader(localizedType),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: AppPadding.xl,
        ),
        if (period != null)
          Text(
            period.getRangeString(DateTime.now(), context),
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DateWidget(
                dateListener: _dateListener,
                enabled: !isEdit,
              ),
              TimeWidget(
                timeListener: _timeListener,
                enabled: !isEdit,
              ),
            ],
          ),
        ],
        const SizedBox(
          height: AppPadding.small,
        ),
        RenderQuestions(
            questions: testAdditions,
            questionsListener: widget.questionsListener),
        const SizedBox(
          height: AppPadding.small,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
          child: Center(
            child: LongTextEntry(
                textController: _descriptionController,
                hintText: "$localizedType description"),
          ),
        ),
        const SizedBox(
          height: AppPadding.large,
        ),
      ],
    );
  }
}

class LongTextEntry extends ConsumerWidget {
  final TextEditingController textController;
  final String hintText;

  const LongTextEntry(
      {required this.textController, required this.hintText, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate.submitDescriptionTag,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppPadding.tiny),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value),
          child: ListenableBuilder(
            listenable: textController,
            builder: (context, _) {
              final hasText = textController.text.isNotEmpty;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openDescriptionEditor(context, ref),
                  borderRadius: BorderRadius.circular(AppRounding.small),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppRounding.small),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            hasText
                                ? textController.text
                                : context
                                    .translate.submitDescriptionPlaceholder,
                            style: hasText
                                ? Theme.of(context).textTheme.bodyMedium
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                        Icon(
                          hasText ? Icons.edit : Icons.add,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDescriptionEditor(BuildContext context, WidgetRef ref) {
    ref
        .read(sheetControllerProvider)
        .show<String>(
          context: context,
          scrollControlled: true,
          initialChildSize: 0.7,
          sheetBuilder: (context, scrollController) => _DescriptionEditorSheet(
            initialText: textController.text,
            scrollController: scrollController,
            hintText: hintText,
          ),
        )
        .then((result) {
      if (result != null) {
        textController.text = result;
      }
    });
  }
}

class _DescriptionEditorSheet extends StatefulWidget {
  final String initialText;
  final String hintText;
  final ScrollController scrollController;

  const _DescriptionEditorSheet({
    required this.initialText,
    required this.scrollController,
    required this.hintText,
  });

  @override
  State<_DescriptionEditorSheet> createState() =>
      _DescriptionEditorSheetState();
}

class _DescriptionEditorSheetState extends State<_DescriptionEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    // Auto-focus the text field when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    context.pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.pop(_controller.text);
        }
      },
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.medium,
              AppPadding.small,
              AppPadding.small,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.translate.submitDescriptionTag,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Text field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.medium,
                vertical: AppPadding.small,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: widget.scrollController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
