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
import 'package:stripes_ui/UI/Record/TestScreen/test_async_error.dart';
import 'package:stripes_ui/UI/Record/TestScreen/test_screen.dart';
import 'package:stripes_ui/Util/Design/breakpoint.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Widgets/mouse_hover.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Widgets/floating_nav_bar.dart';

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
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) {
            if (progress.stage == BlueDyeTestStage.initial &&
                progress.orderedTests.isEmpty) {
              return BlueMealPreStudy(
                onClick: () {
                  _startTest();
                },
                isLoading: isLoading,
              );
            }
            return const StudyOngoing();
          },
          loading: () => Padding(
            padding: const EdgeInsets.only(
              top: AppPadding.xl,
              right: AppPadding.xl,
              left: AppPadding.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.value),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TestSwitcher(),
                    SizedBox(height: AppPadding.medium),
                    LoadingWidget(),
                  ],
                ),
              ),
            ),
          ),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Future<void> _startTest() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final DateTime start = DateTime.now();
      final protocol = await ref.read(activeProtocolProvider.future);
      final repo = await ref.read(testProvider.future);
      if (protocol != null && repo != null) {
        final newMealState = BlueDyeMealState(
          startTime: start,
          timerStart: start,
          pauseTime: start,
        );
        final updated = protocol.copyWith(
          testContext: newMealState.replaceInContext(protocol.testContext),
        );
        await repo.updateProtocol(updated);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void toggleBottomSheet(BuildContext context) {
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
              child: BlueMealInfoSheet(scrollController: controller),
            );
          },
        );
      },
    );
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
  BlueDyeProgression? _lastProgression;

  late final PageController _pageController;

  PageStorageBucket bucket = PageStorageBucket();

  final blueDyeScrollKey = const PageStorageKey("BlueDyeScroll");

  final ScrollController scrollContoller = ScrollController();

  @override
  void initState() {
    super.initState();
    _lastProgression = ref
        .read(blueDyeTestProgressProvider)
        .when(
          data: (progress) => progress.getProgression(),
          loading: () => null,
          error: (error, stackTrace) => null,
        );
    currentIndex = _lastProgression?.value ?? 0;
    _pageController = PageController(
      viewportFraction: 0.7,
      initialPage: currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldWrap = getBreakpoint(context)
        .isLessThan(Breakpoint.medium);
    return ref
        .watch(blueDyeTestProgressProvider)
        .when(
          data: (progress) {
            final BlueDyeProgression? currentProgression = progress
                .getProgression();
            final int index = currentProgression?.value ?? 0;
            final bool isStudyCompleted =
                currentProgression == BlueDyeProgression.completed;
            _syncToProgression(currentProgression);

            final BlueDyeProgression activeStage =
                BlueDyeProgression.values[currentIndex];
            final bool isPrevious = currentIndex < index;

            Widget getDisplayedWidget() {
              // Handle activeStage being 'completed' (shouldn't happen with filtered carousel)
              if (activeStage == BlueDyeProgression.completed) {
                return const RecordingsView(
                  next: null,
                  clicked: BlueDyeProgression.stepFive,
                );
              }

              final bool isStepFour =
                  activeStage == BlueDyeProgression.stepFour;

              // Step 1 or Step 4 (meal entry steps)
              if (activeStage == BlueDyeProgression.stepOne || isStepFour) {
                // When study is complete or step is previous, show finished display
                if (isStudyCompleted || isPrevious) {
                  return MealFinishedDisplay(
                    next: isStudyCompleted
                        ? null
                        : () {
                            _changePage(currentIndex + 1);
                          },
                    displaying: activeStage,
                  );
                }
                return MealStatsEntry(clicked: activeStage);
              }

              // Step 3 (waiting time)
              if (activeStage == BlueDyeProgression.stepThree) {
                if (isStudyCompleted || isPrevious) {
                  // Show as completed waiting period
                  return RecordingsView(
                    next: isStudyCompleted
                        ? null
                        : () {
                            _changePage(currentIndex + 1);
                          },
                    clicked: activeStage,
                  );
                }
                return WaitingTime(
                  next: () {
                    _changePage(currentIndex + 1);
                  },
                );
              }

              // Step 2 or Step 5 (BM logging steps)
              if (isStudyCompleted ||
                  isPrevious ||
                  (progress.testIteration == 2 &&
                      !progress.stage.testInProgress)) {
                return RecordingsView(
                  next: isStudyCompleted
                      ? null
                      : (currentProgression == BlueDyeProgression.stepThree &&
                            isPrevious)
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

            // Filter out 'completed' since it's a terminal state, not a selectable step
            final displayableSteps = BlueDyeProgression.values
                .where((step) => step != BlueDyeProgression.completed)
                .toList();

            final Widget pageView = PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              children: displayableSteps
                  .map(
                    (step) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                      ),
                      child: _buildScrollStep(
                        context,
                        index,
                        step,
                        isStudyCompleted: isStudyCompleted,
                      ),
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
                          constraints: BoxConstraints(
                            maxWidth: Breakpoint.medium.value,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppPadding.xl),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppPadding.xl,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TestSwitcher(),
                                ),
                              ),
                              const SizedBox(height: AppPadding.medium),
                              SizedBox(
                                height:
                                    144.0 *
                                    MediaQuery.textScalerOf(context).scale(1),
                                child: shouldWrap
                                    ? kIsWeb
                                          ? Row(
                                              children: [
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () {
                                                    _pageController
                                                        .previousPage(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    200,
                                                              ),
                                                          curve: Curves.ease,
                                                        );
                                                  },
                                                  icon: const Icon(
                                                    Icons.keyboard_arrow_left,
                                                  ),
                                                ),
                                                Expanded(child: pageView),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () {
                                                    _pageController.nextPage(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      curve: Curves.ease,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.keyboard_arrow_right,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : pageView
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: displayableSteps
                                            .map<Widget>(
                                              (step) => _buildScrollStep(
                                                context,
                                                index,
                                                step,
                                                isStudyCompleted:
                                                    isStudyCompleted,
                                              ),
                                            )
                                            .toList()
                                            .spacedBy(
                                              space: AppPadding.medium,
                                              axis: Axis.horizontal,
                                            ),
                                      ),
                              ),
                              const SizedBox(height: AppPadding.medium),
                              Center(child: getDisplayedWidget()),
                              SizedBox(
                                height:
                                    FloatingNavBarScope.bottomPaddingOf(
                                      context,
                                    ) +
                                    (hasIndicator
                                        ? AppPadding.xxxl
                                        : AppPadding.large),
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
          },
          loading: () => const LoadingWidget(),
          error: (error, stackTrace) => TestAsyncError(error: error),
        );
  }

  Widget _buildScrollStep(
    BuildContext context,
    int activeIndex,
    BlueDyeProgression step, {
    required bool isStudyCompleted,
  }) {
    final bool previous = step.value < activeIndex;
    final bool active = step.value == activeIndex;

    final Color primary = Theme.of(context).primaryColor;
    final Color primaryLight = Theme.of(context).primaryColorLight
        .withValues(alpha: 1);
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color disabledColor = Theme.of(context).disabledColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color completedColor = Theme.of(context).primaryColor
        .withValues(alpha: 0.2);

    const double lineThickness = 1.0;

    if (step == BlueDyeProgression.stepThree) {
      return GestureDetector(
        onTap: () {
          if (currentIndex == step.value) return;
          if (!isStudyCompleted && step.value > activeIndex) {
            showSnack(
              context,
              context.translate.stepClickWarning('${step.value}'),
            );
            return;
          }
          _changePage(step.value);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppPadding.small),
            ),
            color: previous ? completedColor : surface,
            border: Border.all(
              width: 1,
              color: active ? primary : disabledColor,
            ),
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
          color: active ? surface : disabledColor,
          width: lineThickness,
        ),
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
                    color: previous || !active ? surface : primary,
                  ),
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
          // When study is completed, allow navigation to any previous step
          // Otherwise, only allow navigation to completed/active steps
          if (!isStudyCompleted && step.value > activeIndex) {
            showSnack(
              context,
              context.translate.stepClickWarning(
                '${step.value < 2 ? step.value + 1 : step.value}',
              ),
            );
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
                  : disabledColor,
            ),
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
                        const SizedBox(width: AppPadding.medium),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Step ${step.value < 2 ? step.value + 1 : step.value}",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: previous
                                        ? primary
                                        : active
                                        ? surface
                                        : textColor,
                                  ),
                            ),
                            Text(
                              activeIndex > step.value
                                  ? "Completed"
                                  : step.getLabel(context),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: active ? surface : textColor,
                                  ),
                            ),
                          ],
                        ),
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
                    const SizedBox(width: AppPadding.tiny),
                    Text(
                      step.value < 2
                          ? context.translate.transitOneLabel
                          : context.translate.transitTwoLabel,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: active || !previous ? surface : primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).showCursorOnHover,
    );
  }

  void _changePage(int newIndex) {
    if (!mounted) return;
    setState(() {
      currentIndex = newIndex;
    });
    try {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.ease,
        );
      }
      if (scrollContoller.hasClients) {
        scrollContoller.jumpTo(scrollContoller.position.minScrollExtent);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _syncToProgression(BlueDyeProgression? progression) {
    if (progression == null || progression == _lastProgression) return;
    _lastProgression = progression;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && currentIndex != progression.value) {
        _changePage(progression.value);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    scrollContoller.dispose();
    super.dispose();
  }
}
