import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/Test/test_progress_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/scroll_assisted_list.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/amount_consumed.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';
import 'package:stripes_ui/UI/Record/TestScreen/recordings_state.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

class BlueDyeTestScreen extends ConsumerStatefulWidget {
  const BlueDyeTestScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _BlueDyeTestScreenState();
  }
}

class _BlueDyeTestScreenState extends ConsumerState<BlueDyeTestScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BlueDyeTestProgress> progress =
        ref.watch(blueDyeTestProgressProvider);
    if (progress.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(
            top: AppPadding.xl, right: AppPadding.xl, left: AppPadding.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TestSwitcher(),
                SizedBox(
                  height: AppPadding.medium,
                ),
                LoadingWidget()
              ],
            ),
          ),
        ),
      );
    }
    final BlueDyeTestProgress? loaded = progress.valueOrNull;
    if (loaded?.stage == BlueDyeTestStage.initial &&
        loaded!.orderedTests.isEmpty) {
      return BlueMealPreStudy(
        onClick: () {
          _startTest();
        },
        isLoading: isLoading,
      );
    }
    return const StudyOngoing();
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
            topLeft: Radius.circular(AppRounding.large),
            topRight: Radius.circular(AppRounding.large),
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

  PageStorageBucket bucket = PageStorageBucket();

  final blueDyeScrollKey = const PageStorageKey("BlueDyeScroll");

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
    _setCurrentPage();
    super.initState();
  }

  _setCurrentPage() async {
    final BlueDyeTestProgress progress =
        await ref.read(blueDyeTestProgressProvider.future);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(progress.getProgression()?.value ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Future<BlueDyeProgression?>>(
        blueDyeTestProgressProvider.selectAsync(
            (progress) => progress.getProgression()), (prev, next) async {
      final BlueDyeProgression? nextValue = await next;
      final BlueDyeProgression? prevValue = await prev;
      if (context.mounted &&
          nextValue != null &&
          (prevValue == null ||
              nextValue.index > prevValue.index &&
                  nextValue.index != currentIndex)) {
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
        return MealStatsEntry(
          clicked: activeStage,
        );
      }

      if (!isPrevious && activeStage == BlueDyeProgression.stepThree) {
        return WaitingTime(
          next: () {
            _changePage(currentIndex + 1);
          },
        );
      }
      if (isPrevious ||
          (loaded?.testIteration == 2 && !loaded!.stage.testInProgress)) {
        return RecordingsView(
          next: currentProgression == BlueDyeProgression.stepThree && isPrevious
              ? null
              : () {
                  if (activeStage == BlueDyeProgression.stepTwo) {
                    _changePage(currentIndex + 2);
                  } else {
                    _changePage(currentIndex + 1);
                  }
                },
          clicked: activeStage,
        );
      }
      return const RecordingsInProgress();
    }

    final Widget pageView = PageView(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      children: BlueDyeProgression.values
          .map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
              child: _buildScrollStep(context, index, currentIndex, step),
            ),
          )
          .toList(),
    );

    return RefreshWidget(
      depth: RefreshDepth.authuser,
      scrollable: AddIndicator(
        builder: (context, hasIndicator) => ScrollAssistedList(
          scrollController: ScrollController(),
          builder: (context, properties) => SizedBox.expand(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: properties.scrollStateKey,
              controller: properties.scrollController,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: Breakpoint.medium.value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: AppPadding.xl,
                      ),
                      const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: AppPadding.xl),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: TestSwitcher())),
                      const SizedBox(
                        height: AppPadding.medium,
                      ),
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
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.ease);
                                          },
                                          icon: const Icon(
                                              Icons.keyboard_arrow_left)),
                                      Expanded(child: pageView),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            _pageController.nextPage(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.ease);
                                          },
                                          icon: const Icon(
                                              Icons.keyboard_arrow_right)),
                                    ],
                                  )
                                : pageView
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: BlueDyeProgression.values
                                    .map<Widget>(
                                      (step) => _buildScrollStep(
                                          context, index, currentIndex, step),
                                    )
                                    .toList()
                                    .spacedBy(
                                        space: AppPadding.medium,
                                        axis: Axis.horizontal),
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
                          context.translate
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
                        height: AppPadding.medium,
                      ),
                      Center(
                        child: getDisplayedWidget(),
                      ),
                      if (hasIndicator)
                        const SizedBox(
                          height: AppPadding.xxxl,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
              Radius.circular(AppPadding.small),
            ),
            color: previous ? completedColor : surface,
            border:
                Border.all(width: 1, color: active ? primary : disabledColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
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
        padding: const EdgeInsets.all(AppPadding.tiny),
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
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Center(
                child: Text(
                  '${step.value < 2 ? step.value + 1 : step.value}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: previous || !active ? surface : primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoint.tiny.value / 2.5),
        child: GestureDetector(
          onTap: () {
            if (currentIndex == step.value) return;
            if (step.value > activeIndex) {
              showSnack(
                  context,
                  context.translate.stepClickWarning(
                      '${step.value < 2 ? step.value + 1 : step.value}'));
              return;
            }
            _changePage(step.value);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRounding.small),
              ),
              border: Border.all(
                  width: lineThickness,
                  color: previous
                      ? primary
                      : active
                          ? Colors.transparent
                          : disabledColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRounding.small),
                        topRight: Radius.circular(AppRounding.small),
                      ),
                      color: active
                          ? primary
                          : previous
                              ? completedColor
                              : surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          stepCircle,
                          const SizedBox(
                            width: AppPadding.medium,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Step ${step.value < 2 ? step.value + 1 : step.value}",
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
                                    ?.copyWith(
                                        color: active ? surface : textColor),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppRounding.small),
                      bottomRight: Radius.circular(AppRounding.small),
                    ),
                    color: active
                        ? primaryLight
                        : previous
                            ? completedColor
                            : disabledColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: AppPadding.tiny,
                      ),
                      Text(
                        step.value < 2
                            ? context.translate.transitOneLabel
                            : context.translate.transitTwoLabel,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: active || !previous ? surface : primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).showCursorOnHover);
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
