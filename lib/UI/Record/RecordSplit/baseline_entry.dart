import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Util/Helpers/repo_result_handler.dart';
import 'package:stripes_ui/Providers/Questions/baseline_version_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/async_value_defaults.dart';
import 'package:stripes_ui/UI/CommonWidgets/button_loading_indicator.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/layout_helper.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_layout_shell.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';
import 'package:stripes_ui/UI/CommonWidgets/confirmation_popup.dart';
import 'package:stripes_ui/Providers/Navigation/navigation_provider.dart';

class BaselineEntry extends ConsumerStatefulWidget {
  final String recordPath;
  final List<Question>? questions;

  late final QuestionsListener questionListener;
  BaselineEntry(
      {super.key,
      required this.recordPath,
      this.questions,
      QuestionsListener? data}) {
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
  String? _errorMessage;

  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    original = widget.questionListener.copy();
    _pageController = PageController();
    widget.questionListener.addListener(_changedUpdate);
    super.initState();
  }

  @override
  void dispose() {
    widget.questionListener.removeListener(_changedUpdate);
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
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

  Future<bool> _handleNavigation(BuildContext context) async {
    if (!hasChanged) return true;
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => ErrorPrevention(
              type: widget.recordPath,
            ));
    if (result == true) {
      setState(() {
        hasChanged = false;
      });
    }
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registerGuardProvider(_handleNavigation));
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

    return PopScope(
      canPop: !hasChanged,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _handleNavigation(context)) {
          if (context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.HOME);
            }
          }
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoint.small.value),
          child: AsyncValueDefaults(
            value: pagesData,
            onData: (loadedPages) {
              final PagesData translatedPage =
                  localizations?.translatePage(loadedPages) ?? loadedPages;
              final List<LoadedPageLayout> filteredLayouts =
                  LayoutHelper.processLayouts(
                loadedLayouts: translatedPage.loadedLayouts,
                listener: widget.questionListener,
                deferCleanup: true,
              );

              if (filteredLayouts.isEmpty) return const SizedBox();

              final bool isLastPage =
                  _currentIndex == filteredLayouts.length - 1;
              final VoidCallback? onPressed = isLastPage
                  ? (edited && !isLoading
                      ? () async {
                          setState(() => isLoading = true);
                          try {
                            await _submit(context, ref, true);
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        }
                      : null)
                  : () {
                      final currentLayout = filteredLayouts[_currentIndex];
                      final currentQuestions = currentLayout.questions
                          .where((q) =>
                              widget.questions == null ||
                              widget.questions!.any((wq) => wq.id == q.id))
                          .toList();

                      final pendingRequired = currentQuestions.where((q) =>
                          q.requirement?.eval(widget.questionListener) ??
                          false);

                      if (pendingRequired.isNotEmpty) {
                        widget.questionListener.tried = true;
                        setState(() {
                          _errorMessage = context.translate
                              .nLevelError(pendingRequired.length);
                        });
                        return;
                      }

                      setState(() {
                        _errorMessage = null;
                      });
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    };

              final progress = LayoutHelper.calculateProgress(
                pages: filteredLayouts,
                currentIndex: _currentIndex,
                listener: widget.questionListener,
              );

              final controller = RecordEntryController(
                title: localizations?.value(widget.recordPath) ??
                    widget.recordPath,
                currentIndex: _currentIndex,
                totalPages: filteredLayouts.length,
                pageController: _pageController,
                onClose: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.HOME);
                  }
                },
                isLoading: isLoading,
                onControl: onPressed,
                controlLabel: isLastPage ? 'Submit' : 'Next',
                isReady: onPressed != null,
                isSubmit: isLastPage,
                errorMessage: _errorMessage,
                onDismissError: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                totalQuestions: progress.total,
                answeredQuestions: progress.answered,
                pendingRequiredCount: progress.pendingRequired,
              );

              return RecordEntryProvider(
                controller: controller,
                child: RecordEntryShell(
                  divider: const ComboDivider(),
                  content: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredLayouts.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _errorMessage = null;
                      });
                    },
                    itemBuilder: (context, index) {
                      final layout = filteredLayouts[index];
                      if (!_scrollControllers.containsKey(index)) {
                        _scrollControllers[index] = ScrollController();
                      }

                      final visibleQuestions = layout.questions.where((q) {
                        return widget.questions == null ||
                            widget.questions!.any((wq) => wq.id == q.id);
                      }).toList();

                      return SingleChildScrollView(
                        controller: _scrollControllers[index],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (layout.header != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: AppPadding.large,
                                    bottom: AppPadding.medium),
                                child: Text(
                                  layout.header!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            RenderQuestions(
                                questions: visibleQuestions,
                                questionsListener: widget.questionListener),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
      BuildContext context, WidgetRef ref, bool isSuccess) async {
    if (widget.questionListener.pending.isNotEmpty) {
      widget.questionListener.tried = true;
      setState(() {
        _errorMessage = context.translate
            .nLevelError(widget.questionListener.pending.length);
      });
      return;
    }

    final StampRepo? repo = await ref.read(stampProvider.future);
    final DateTime submissionEntry =
        widget.questionListener.submitTime ?? DateTime.now();
    final int entryStamp = dateToStamp(submissionEntry);
    final bool isEdit = widget.questionListener.editId != null;

    // Generate versioned baseline ID for new entries
    String entryId;
    if (isEdit) {
      entryId = widget.questionListener.editId!;
    } else {
      // Get existing versions and increment
      final versions =
          ref.read(baselineVersionsProvider(widget.recordPath)).value ?? [];
      final int nextVersion = versions.isEmpty ? 1 : versions.first.version + 1;
      entryId = BaselineId.create(widget.recordPath, nextVersion).toString();
    }

    final DetailResponse detailResponse = DetailResponse(
      id: entryId,
      description: widget.questionListener.description,
      responses: widget.questionListener.questions.values
          .map((res) => res.encodeGeneratedQuestion())
          .toList(growable: false),
      stamp: isEdit
          ? dateToStamp(widget.questionListener.submitTime!)
          : entryStamp,
      detailType: widget.recordPath,
    );

    if (isEdit) {
      final RepoResult result = await repo?.updateStamp(detailResponse) ??
          const Failure(message: 'Stamp repo not found');
      await ((await ref.read(testProvider.future))
          ?.onResponseEdit(detailResponse, widget.recordPath));
      if (context.mounted) {
        result.handle(context);
      }
    } else {
      final RepoResult result = await repo?.addStamp(detailResponse) ??
          const Failure(message: 'Stamp repo not found');
      await (await ref.read(testProvider.future))
          ?.onResponseSubmit(detailResponse, widget.recordPath);
      if (context.mounted) {
        result.handle(context);
        if (result is! Success) return;
      }
    }

    if (mounted) {
      setState(() {
        submitSuccess = true;
        hasChanged = false;
      });
      await Future.delayed(const Duration(milliseconds: 600));

      if (context.mounted) {
        if (!isEdit) {
          showSnack(
              context,
              context.translate.undoEntry(
                  widget.recordPath, submissionEntry, submissionEntry),
              action: () async {
            final RepoResult result = await repo?.removeStamp(detailResponse) ??
                Failure(message: 'Repo not found');
            await (await ref.read(testProvider.future))
                ?.onResponseDelete(detailResponse, widget.recordPath);
            if (context.mounted) {
              result.handle(context);
            }
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
}

class HybridSubmitButton extends StatelessWidget {
  final String buttonText;
  final bool isDisabled;
  final bool isLoading;
  final int currentIndex;
  final int totalLength;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  const HybridSubmitButton({
    super.key,
    required this.buttonText,
    required this.isDisabled,
    required this.isLoading,
    required this.currentIndex,
    required this.totalLength,
    required this.onSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = currentIndex == totalLength - 1;

    if (isLastPage) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isDisabled || isLoading ? null : onSubmit,
          child: isLoading ? const ButtonLoadingIndicator() : Text(buttonText),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isLoading ? null : onNext,
          child: const Text("Next"),
        ),
      );
    }
  }
}

class ErrorPrevention extends ConsumerWidget {
  final String type;

  const ErrorPrevention({required this.type, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmationPopup(
        onConfirm: () => _confirm(context),
        title: Text(
          context.translate.errorPreventionTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.translate.errorPreventionLineOne,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: AppPadding.small,
            ),
            Text(
              context.translate.errorPreventionLineTwo(type.toLowerCase()),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        onCancel: () {
          Navigator.of(context).pop(false);
        },
        cancel: context.translate.errorPreventionStay,
        confirm: context.translate.errorPreventionLeave);
  }

  _confirm(BuildContext context) {
    Navigator.of(context).pop(true);
  }
}
