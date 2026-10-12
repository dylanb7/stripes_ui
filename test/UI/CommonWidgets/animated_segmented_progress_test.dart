import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/CommonWidgets/animated_segmented_progress.dart';

void main() {
  testWidgets('repaints as the attached page controller settles', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AnimatedSegmentedProgress(
                segmentIds: const ['first', 'second', 'submit'],
                currentIndex: 0,
                pageController: pageController,
              ),
              Expanded(
                child: PageView(
                  controller: pageController,
                  children: const [SizedBox(), SizedBox(), SizedBox()],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final progressPaint = find.descendant(
      of: find.byType(AnimatedSegmentedProgress),
      matching: find.byType(CustomPaint),
    );
    final before = tester.widget<CustomPaint>(progressPaint);

    pageController.jumpToPage(2);
    await tester.pump();

    final after = tester.widget<CustomPaint>(progressPaint);
    expect(after, isNot(same(before)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports state and morphs segment changes', (tester) async {
    final pageController = PageController(initialPage: 1);
    addTearDown(pageController.dispose);
    var segmentIds = const ['first', 'second', 'submit'];
    var currentIndex = 1;
    var currentHasError = false;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  AnimatedSegmentedProgress(
                    segmentIds: segmentIds,
                    currentIndex: currentIndex,
                    currentHasError: currentHasError,
                    pageController: pageController,
                    semanticsKey: const ValueKey('progress'),
                  ),
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      onPageChanged: (index) {
                        update(() => currentIndex = index);
                      },
                      children: const [
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final progress = find.byKey(const ValueKey('progress'));
    expect(tester.getSemantics(progress).label, 'Step 2 of 3');

    update(() => currentHasError = true);
    await tester.pump();
    expect(
      tester.getSemantics(progress).value,
      'Current step has validation errors',
    );

    update(() {
      segmentIds = const ['first', 'second', 'conditional', 'submit'];
      currentHasError = false;
    });
    await tester.pump();
    expect(tester.getSemantics(progress).label, 'Step 2 of 4');
    await tester.pumpAndSettle();

    pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await tester.pumpAndSettle();
    expect(tester.getSemantics(progress).label, 'Step 3 of 4');

    update(() {
      segmentIds = const ['first', 'second', 'submit'];
      currentIndex = 1;
    });
    await tester.pumpAndSettle();
    expect(tester.getSemantics(progress).label, 'Step 2 of 3');
    expect(tester.takeException(), isNull);
  });
}
