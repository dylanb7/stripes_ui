import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/Providers/stamps_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/question_screen.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:uuid/uuid.dart';

class BaselineEntry extends ConsumerStatefulWidget {
  final String recordPath;

  late final QuestionsListener questionListener;
  BaselineEntry(
      {super.key, required this.recordPath, QuestionsListener? data}) {
    questionListener = data ?? QuestionsListener();
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BaselineEntryState();
  }
}

class _BaselineEntryState extends ConsumerState<BaselineEntry> {
  late final QuestionsListener original;

  bool hasChanged = false;
  bool isLoading = false;
  bool submitSuccess = false;

  @override
  void initState() {
    original = widget.questionListener.copy();
    widget.questionListener.addListener(_changedUpdate);
    super.initState();
  }

  @override
  void dispose() {
    widget.questionListener.removeListener(_changedUpdate);
    super.dispose();
  }

  void _changedUpdate() {
    final bool change = original != widget.questionListener;

    if (mounted) {
      setState(() {
        hasChanged = change;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuestionsLocalizations? localizations =
        QuestionsLocalizations.of(context);

    final AsyncValue<PagesData> pagesData = ref.watch(
      pagesByPath(
        PagesByPathProps(
          pathName: widget.recordPath,
          filterEnabled: true,
        ),
      ),
    );

    final bool isEdit = widget.questionListener.editId != null;
    final bool edited = !isEdit || isEdit && hasChanged;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
          child: AsyncValueDefaults(
            value: pagesData,
            onData: (loadedPages) {
              final PagesData translatedPage =
                  localizations?.translatePage(loadedPages) ?? loadedPages;

              final List<Question> allQuestions = translatedPage.loadedLayouts
                      ?.expand((page) => page.questions)
                      .toList() ??
                  [];

              final int pendingCount = widget.questionListener.pending.length;

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppPadding.medium),
                        color: ElevationOverlay.applySurfaceTint(
                            Theme.of(context).cardColor,
                            Theme.of(context).colorScheme.surfaceTint,
                            3),
                      ),
                      child: IgnorePointer(
                        ignoring: isLoading,
                        child: _buildContent(context, allQuestions),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                  IgnorePointer(
                    ignoring: isLoading || pagesData.isLoading,
                    child: Center(
                      child: FilledButton(
                        onPressed: submitSuccess
                            ? () {}
                            : (pendingCount == 0 && !isLoading && edited)
                                ? () {
                                    _submitEntry(context, ref, isEdit);
                                  }
                                : null,
                        child: submitSuccess
                            ? const Icon(Icons.check)
                            : isLoading
                                ? const ButtonLoadingIndicator()
                                : Text(isEdit
                                    ? context.translate.editSubmitButtonText
                                    : context.translate.submitButtonText),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.tiny),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Question> questions) {
    final List<Question> filtered = questions
        .where(
          (question) =>
              question.dependsOn == null ||
              question.dependsOn!.eval(widget.questionListener),
        )
        .toList();
    final ScrollController scrollController = ScrollController();
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      interactive: false,
      controller: scrollController,
      radius: const Radius.circular(AppRounding.large),
      scrollbarOrientation: ScrollbarOrientation.right,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppPadding.tiny, horizontal: AppPadding.small),
          child: QuestionScreen(
            header: '', // No header for baseline
            questions: filtered,
            questionsListener: widget.questionListener,
          ),
        ),
      ),
    );
  }

  void _submitEntry(BuildContext context, WidgetRef ref, bool isEdit) async {
    if (widget.questionListener.pending.isNotEmpty) {
      widget.questionListener.tried = true;
      showSnack(
          context,
          context.translate
              .nLevelError(widget.questionListener.pending.length));
      return;
    }
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final StampRepo? repo = await ref.read(stampProvider.future);
    final DateTime submissionEntry =
        widget.questionListener.submitTime ?? DateTime.now();
    final int entryStamp = dateToStamp(submissionEntry);
    final DetailResponse detailResponse = DetailResponse(
      id: widget.questionListener.editId ?? const Uuid().v4(),
      description: widget.questionListener.description,
      responses:
          widget.questionListener.questions.values.toList(growable: false),
      stamp: isEdit
          ? dateToStamp(widget.questionListener.submitTime!)
          : entryStamp,
      detailType: widget.recordPath,
    );

    if (isEdit) {
      await repo?.updateStamp(detailResponse);
      await ((await ref.read(testProvider.future))
          ?.onResponseEdit(detailResponse, widget.recordPath));
    } else {
      await repo?.addStamp(detailResponse);
      await (await ref.read(testProvider.future))
          ?.onResponseSubmit(detailResponse, widget.recordPath);
    }
    setState(() {
      submitSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      isLoading = false;
    });

    if (context.mounted) {
      if (!isEdit) {
        showSnack(
            context,
            context.translate
                .undoEntry(widget.recordPath, submissionEntry, submissionEntry),
            action: () async {
          await repo?.removeStamp(detailResponse);
          await (await ref.read(testProvider.future))
              ?.onResponseDelete(detailResponse, widget.recordPath);
        });
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.HOME);
      }
    }
  }
}
