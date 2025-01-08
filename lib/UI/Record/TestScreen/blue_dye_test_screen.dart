import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/horizontal_stepper.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class BlueDyeTestScreen extends ConsumerStatefulWidget {
  const BlueDyeTestScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BlueDyeTestScreenState();
  }
}

class _BlueDyeTestScreenState extends ConsumerState<BlueDyeTestScreen> {
  bool isLoading = false;

  final ScrollController scrollContoller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    if (progress.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TestSwitcher(),
                SizedBox(
                  height: 12.0,
                ),
                LoadingWidget()
              ],
            ),
          ),
        ),
      );
    }
    final BlueDyeTestProgress? loaded = progress.valueOrNull;
    return RefreshWidget(
      depth: RefreshDepth.authuser,
      scrollable: AddIndicator(
        builder: (context, hasIndicator) => ScrollAssistedList(
          scrollController: scrollContoller,
          key: const PageStorageKey("BlueDyeScroll"),
          builder: (context, properties) => SizedBox.expand(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: properties.scrollStateKey,
              shrinkWrap: true,
              controller: properties.scrollController,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: SMALL_LAYOUT),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const TestSwitcher(),
                              (loaded?.stage != BlueDyeTestStage.initial ||
                                      loaded!.orderedTests.isNotEmpty)
                                  ? IconButton(
                                      onPressed: () {
                                        toggleBottomSheet(context);
                                      },
                                      icon: const Icon(Icons.info))
                                  : SizedBox(
                                      width: Theme.of(context).iconTheme.size,
                                    ),
                            ],
                          ),
                          const SizedBox(
                            height: 12.0,
                          ),
                          loaded?.stage == BlueDyeTestStage.initial &&
                                  loaded!.orderedTests.isEmpty
                              ? BlueMealPreStudy(
                                  onClick: () {
                                    _startTest();
                                  },
                                  isLoading: isLoading,
                                )
                              : const StudyOngoing(),
                          if (hasIndicator)
                            const SizedBox(
                              height: 100,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() {
      isLoading = true;
    });
    final DateTime start = DateTime.now();
    await ref
        .read(testsHolderProvider.notifier)
        .getTest<Test<BlueDyeState>>()
        .then((test) => test?.setTestState(BlueDyeState(
            startTime: start, timerStart: start, pauseTime: start, logs: [])));
    setState(() {
      isLoading = false;
    });
  }

  toggleBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 1.0,
              builder: (context, controller) {
                return SafeArea(
                  child: BlueMealInfoSheet(
                    scrollController: controller,
                  ),
                );
              });
        });
  }
}

class StudyOngoing extends ConsumerStatefulWidget {
  const StudyOngoing({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _StudyOngoingState();
  }
}

class _StudyOngoingState extends ConsumerState<StudyOngoing> {
  late int currentIndex;

  final ScrollController scrollContoller = ScrollController();

  @override
  void initState() {
    currentIndex = ref
            .read(blueDyeTestProgressProvider)
            .valueOrNull
            ?.getProgression()
            ?.value ??
        0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Future<BlueDyeProgression?>>(
        blueDyeTestProgressProvider.selectAsync(
            (progress) => progress.getProgression()), (prev, next) async {
      final BlueDyeProgression? nextValue = await next;
      final BlueDyeProgression? prevValue = await next;
      if (mounted &&
          nextValue != null &&
          (prevValue == null || nextValue.index > prevValue.index)) {
        _changePage(nextValue.index);
      }
    });
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);

    if (progress.isLoading) {
      return const LoadingWidget();
    }

    final BlueDyeTestProgress? loaded = progress.valueOrNull;

    final BlueDyeProgression? currentProgression = loaded?.getProgression();
    final int index = currentProgression?.value ?? 0;

    final BlueDyeProgression activeStage =
        BlueDyeProgression.values[currentIndex];
    final bool isPrevious = currentIndex < index;

    double getDetailedProgress() {
      final double base = index.toDouble();
      if (loaded?.stage == BlueDyeTestStage.amountConsumed) return base + 0.8;
      if (loaded?.stage == BlueDyeTestStage.initial &&
          (loaded?.testIteration ?? 0) > 0) {
        return base + 0.99;
      }
      return base;
    }

    Widget getDisplayedWidget() {
      final bool isStepThree = activeStage == BlueDyeProgression.stepThree;
      if (activeStage == BlueDyeProgression.stepOne || isStepThree) {
        if (isPrevious) {
          return MealFinishedDisplay(
            next: () {
              _changePage(currentIndex + 1);
            },
            displaying: activeStage,
          );
        }
        return loaded?.stage == BlueDyeTestStage.amountConsumed
            ? const AmountConsumedEntry()
            : const TimerWidget();
      }
      final List<TestDate> orderedTests = loaded?.orderedTests ?? [];
      if (!isPrevious &&
          currentProgression == BlueDyeProgression.stepTwo &&
          orderedTests.length == 1 &&
          !(loaded?.stage.testInProgress ?? false)) {
        return const RecordingsWaiting();
      }
      if (isPrevious ||
          (loaded?.testIteration == 2 && !loaded!.stage.testInProgress)) {
        return RecordingsView(
          next: () {
            _changePage(currentIndex + 1);
          },
          clicked: activeStage,
        );
      }
      return const RecordingsState();
    }

    return ScrollAssistedList(
      builder: (context, properties) => ListView(
        key: properties.scrollStateKey,
        shrinkWrap: true,
        controller: properties.scrollController,
        children: [
          HorizontalStepper(
              steps: BlueDyeProgression.values
                  .map(
                    (step) => HorizontalStep(
                      title: Text(
                        step.getLabel(context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: step.value > index
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5)
                                  : null,
                              decoration: currentIndex != step.value &&
                                      step.value <= index
                                  ? TextDecoration.underline
                                  : null,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      dotContents: Text(
                        "${step.value + 1}",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
              circleWidth: 45.0,
              onStepPressed: (index, isActive) {
                if (!isActive) {
                  showSnack(
                      context,
                      AppLocalizations.of(context)!
                          .stepClickWarning("${index + 1}"));
                  return;
                }
                if (currentIndex == index) return;
                _changePage(index);
              },
              progress: getDetailedProgress(),
              active: Theme.of(context).colorScheme.primary,
              inactive: Theme.of(context).dividerColor.darken()),
          const SizedBox(
            height: 12.0,
          ),
          getDisplayedWidget(),
        ],
      ),
      scrollController: scrollContoller,
      key: const PageStorageKey("BlueDyeArea"),
    );
  }

  _changePage(int newIndex) {
    if (!mounted) return;
    setState(() {
      currentIndex = newIndex;
    });
    try {
      if (scrollContoller.hasClients) {
        scrollContoller.jumpTo(scrollContoller.position.minScrollExtent);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
