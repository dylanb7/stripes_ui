import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/test_progress_provider.dart';
import 'package:stripes_ui/Providers/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/timer_widget.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/mouse_hover.dart';
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
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: TestSwitcher())),
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

  late final PageController _pageController;

  final ScrollController scrollContoller = ScrollController();

  @override
  void initState() {
    currentIndex = ref
            .read(blueDyeTestProgressProvider)
            .valueOrNull
            ?.getProgression()
            ?.value ??
        0;
    _pageController =
        PageController(viewportFraction: 0.7, initialPage: currentIndex);
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

    final bool shouldWrap =
        getBreakpoint(context).isLessThan(Breakpoint.medium);
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
      final double baseLevel = index.toDouble();
      if (loaded?.stage == BlueDyeTestStage.amountConsumed) {
        return baseLevel + 0.8;
      }
      if (loaded?.stage == BlueDyeTestStage.initial &&
          (loaded?.testIteration ?? 0) > 0) {
        return baseLevel + 0.99;
      }
      return baseLevel;
    }

    Widget getDisplayedWidget() {
      final bool isStepFour = activeStage == BlueDyeProgression.stepFour;
      if (activeStage == BlueDyeProgression.stepOne || isStepFour) {
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

      if (!isPrevious && activeStage == BlueDyeProgression.stepThree) {
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

    final Widget pageView = PageView(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      children: BlueDyeProgression.values
          .map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildScrollStep(context, index, currentIndex, step),
            ),
          )
          .toList(),
    );

    return ScrollAssistedList(
      builder: (context, properties) => ListView(
        key: properties.scrollStateKey,
        shrinkWrap: true,
        controller: properties.scrollController,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120.0),
            child: shouldWrap
                ? kIsWeb
                    ? Row(
                        children: [
                          IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _pageController.previousPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.ease);
                              },
                              icon: const Icon(Icons.keyboard_arrow_left)),
                          Expanded(child: pageView),
                          IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _pageController.nextPage(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.ease);
                              },
                              icon: const Icon(Icons.keyboard_arrow_right)),
                        ],
                      )
                    : pageView
                : SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: BlueDyeProgression.values
                          .map<Widget>(
                            (step) => _buildScrollStep(
                                context, index, currentIndex, step),
                          )
                          .toList()
                          .spacedBy(space: 12, axis: Axis.horizontal),
                    ),
                  ),
          ),
          /*if (shouldWrap)
            ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120.0),
                child: CarouselView.weighted(
                  controller: carouselController,
                  flexWeights: const [2, 6, 2],
                  enableSplash: false,
                  onTap: (value) {
                    if (value > activeStage.value) {
                      showSnack(
                          context,
                          AppLocalizations.of(context)!
                              .stepClickWarning("${index + 1}"));
                      return;
                    }
                    if (currentIndex == index) return;
                    _changePage(index);
                  },
                  children: BlueDyeProgression.values
                      .map(
                        (step) => _buildScrollStep(
                            context, currentIndex, index, step),
                      )
                      .toList(),
                )),*/

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

  Widget _buildScrollStep(BuildContext context, int activeIndex,
      int selectedIndex, BlueDyeProgression step) {
    final bool previous = step.value < activeIndex;
    final bool active = step.value == activeIndex;

    final Color primary = Theme.of(context).primaryColor;
    final Color primaryLight =
        Theme.of(context).primaryColorLight.withValues(alpha: 1);
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color disabledColor = Theme.of(context).disabledColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color completedColor =
        Theme.of(context).primaryColor.withValues(alpha: 0.2);

    const double lineThickness = 1.0;

    if (step == BlueDyeProgression.stepThree) {
      return GestureDetector(
        onTap: () {
          if (currentIndex == step.value) return;
          if (activeIndex == step.value) {
            _changePage(step.value);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ),
            color: previous ? completedColor : surface,
            border: Border.all(width: 1, color: active ? primary : textColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                step.getLabel(context),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ).showCursorOnHover;
    }
    final Widget stepCircle = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? primary : surface,
        border: Border.all(
            color: active ? surface : disabledColor, width: lineThickness),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active
                  ? surface
                  : previous
                      ? primaryLight
                      : disabledColor,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '${step.value + 1}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: previous || !active ? surface : primary),
              ),
            ),
          ),
        ),
      ),
    );
    return GestureDetector(
      onTap: () {
        if (currentIndex == step.value) return;
        if (step.value > activeIndex) {
          showSnack(
              context,
              AppLocalizations.of(context)!
                  .stepClickWarning("${step.value + 1}"));
          return;
        }
        _changePage(step.value);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(8.0),
          ),
          border: Border.all(
              width: lineThickness,
              color: previous
                  ? primary
                  : active
                      ? Colors.transparent
                      : disabledColor),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: active
                    ? primary
                    : previous
                        ? completedColor
                        : surface,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      stepCircle,
                      const SizedBox(
                        width: 12.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Step ${step.value + 1}",
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: previous
                                        ? primary
                                        : active
                                            ? surface
                                            : textColor),
                          ),
                          Text(
                            activeIndex > step.value
                                ? "Completed"
                                : step.getLabel(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: active ? surface : textColor),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: lineThickness,
              color: previous || active ? primary : disabledColor,
            ),
            ColoredBox(
              color: active
                  ? primaryLight
                  : previous
                      ? completedColor
                      : disabledColor,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 6.0,
                  ),
                  Text(
                    step.value < 2
                        ? AppLocalizations.of(context)!.transitOneLabel
                        : AppLocalizations.of(context)!.transitTwoLabel,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: active || !previous ? surface : primary),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ).showCursorOnHover;
  }

  _changePage(int newIndex) {
    if (!mounted) return;
    setState(() {
      currentIndex = newIndex;
    });
    try {
      if (_pageController.hasClients) {
        _pageController.animateToPage(newIndex,
            duration: const Duration(milliseconds: 200), curve: Curves.ease);
      }
      if (scrollContoller.hasClients) {
        scrollContoller.jumpTo(scrollContoller.position.minScrollExtent);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
