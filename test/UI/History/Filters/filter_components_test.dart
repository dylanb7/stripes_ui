import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/History/Filters/filter_components.dart';

void main() {
  testWidgets('long filter choices wrap fully and retain their selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3)),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FilterChipSection(
                title: 'Categories',
                items: const ['Bowel Movement', 'Pain'],
                selectedItems: selected,
                onSelected: (item, isSelected) => setState(() {
                  if (isSelected) {
                    selected.add(item);
                  } else {
                    selected.remove(item);
                  }
                }),
              ),
            ),
          ),
        ),
      ),
    );

    final label = find.text('Bowel Movement');
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: label, matching: find.byType(RichText)),
    );
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: TextDirection.ltr,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    expect(painter.computeLineMetrics().length, greaterThan(1));
    expect(paragraph.size.height, greaterThanOrEqualTo(painter.height));
    painter.dispose();
    expect(paragraph.didExceedMaxLines, isFalse);

    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(selected, {'Bowel Movement'});
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Bowel Movement'))
          .selected,
      isTrue,
    );
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
