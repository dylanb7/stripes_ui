import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/horizontal_step_scroll.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
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
            constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
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
                Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: Breakpoint.medium.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
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
        .then((test) {
      test?.setTestState(BlueDyeState(
          startTime: start, timerStart: start, pauseTime: start, logs: []));
    });
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
      if (context.mounted &&
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
          SizedBox(
            height: 200,
            child: HorizontalStepScroll(
              steps: BlueDyeProgression.values
                  .mapIndexed(
                    (stepIndex, step) =>
                        _buildScrollStep(context, currentIndex, index, step),
                  )
                  .toList(),
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
            ),
          ),
          const SizedBox(
            height: 12.0,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: getDisplayedWidget()),
        ],
      ),
      scrollController: scrollContoller,
      key: const PageStorageKey("BlueDyeArea"),
    );
  }

  Widget _buildScrollStep(BuildContext context, int activeIndex,
      int selectedIndex, BlueDyeProgression step) {
    final bool previous = step.value < activeIndex;
    final bool active = step.value == selectedIndex;
    final Color activeForeground = Theme.of(context).colorScheme.onPrimary;
    final Color activeHighlight = Theme.of(context).primaryColor;
    final Color disabledForeground = Theme.of(context).colorScheme.onSurface;
    final Color disabledBackground = Theme.of(context).colorScheme.surface;
    final Widget stepCircle = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? activeHighlight : disabledBackground,
        border: Border.all(
            color: active ? activeForeground : disabledForeground, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: disabledBackground, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                '${step.value + 1}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: disabledForeground),
              ),
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(8.0),
        ),
        border: Border.all(width: 1, color: disabledForeground),
      ),
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: disabledBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  stepCircle,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Step ${step.value + 1}",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: disabledForeground),
                      ),
                      Text(
                        step.getLabel(context),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: disabledForeground),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          Divider(
            color: disabledForeground,
          ),
          ColoredBox(
            color: disabledBackground,
            child: Center(
              child: Text(
                activeIndex < 2 ? "Transit Time 1" : "Transit Time 2",
                textAlign: TextAlign.start,
              ),
            ),
          )
        ],
      ),
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
