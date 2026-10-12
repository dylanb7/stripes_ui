import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';

import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  testWidgets('hub opens every guide and returns to the resource list', (
    tester,
  ) async {
    _setSize(tester, const Size(375, 812));
    await tester.pumpWidget(_app(const ResourcesScreen()));

    expect(find.byIcon(Icons.menu_book_outlined), findsNWidgets(4));

    for (final topic in ResourceTopic.values) {
      final tile = find.byWidgetPredicate(
        (widget) => widget is ResourceListTile && widget.article.topic == topic,
      );
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        tester.widget<ResourceScreen>(find.byType(ResourceScreen)).topic,
        topic,
      );
      expect(find.text(resourceArticle(topic).description), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ResourceScreen), findsNothing);
      expect(find.byType(ResourcesScreen), findsOneWidget);
    }
  });

  testWidgets('focused help scrolls to Type 7 and preserves the open form', (
    tester,
  ) async {
    _setSize(tester, const Size(375, 812));
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                TextField(controller: controller),
                const ResourceInfoButton(
                  topic: ResourceTopic.bristolScale,
                  sectionId: 'stool-types',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    const note = 'Symptoms started after lunch.';
    await tester.enterText(find.byType(TextField), note);
    tester.testTextInput.hide();
    await tester.tap(find.byType(ResourceInfoButton));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Find the closest stool type'), findsOneWidget);
    expect(find.text('Why this matters'), findsNothing);
    expect(find.text('If you’re unsure which type to pick'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(
      find.text(resourceArticle(ResourceTopic.bristolScale).description),
      findsNothing,
    );
    expect(find.text('Done').hitTestable(), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Type 7'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Type 7').hitTestable(), findsOneWidget);
    expect(find.text('Entirely liquid'), findsOneWidget);
    expect(find.byTooltip('Close resources').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Read full guide'));
    await tester.tap(find.text('Read full guide'));
    await tester.pumpAndSettle();
    expect(
      find.text(resourceArticle(ResourceTopic.bristolScale).description),
      findsOneWidget,
    );
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(controller.text, note);

    await tester.tap(find.byTooltip('Back to quick help'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('Read full guide').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byType(ResourceContent), findsNothing);
    expect(controller.text, note);
    expect(find.text(note), findsOneWidget);
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('hub and expanded guides fit 320px at ${scale}x text', (
      tester,
    ) async {
      _setSize(tester, const Size(320, 568));
      await tester.pumpWidget(_app(const ResourcesScreen(), scale: scale));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Terms of Service'));
      expect(find.text('Terms of Service').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final topic in ResourceTopic.values) {
        await tester.pumpWidget(
          _app(
            ResourceScreen(key: ValueKey(topic), topic: topic),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: topic.name);

        for (final section in resourceArticle(topic).sections) {
          if (section.initiallyExpanded) continue;
          final heading = find.text(section.title);
          await tester.ensureVisible(heading);
          await tester.tap(heading);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${topic.name}/${section.id}',
          );
        }

        final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${topic.name} bottom');
      }
    });

    for (final (topic, sectionId) in [
      (ResourceTopic.bristolScale, 'stool-types'),
      (ResourceTopic.blueMealAtHome, 'muffin-ingredients'),
      (ResourceTopic.blueMealAtHome, 'muffin-method'),
      (ResourceTopic.termsOfService, 'terms'),
    ]) {
      testWidgets('focused $sectionId sheet fits 320px at ${scale}x text', (
        tester,
      ) async {
        _setSize(tester, const Size(320, 568));
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: ResourceInfoButton(topic: topic, sectionId: sectionId),
            ),
            scale: scale,
          ),
        );
        await tester.tap(find.byType(ResourceInfoButton));
        await tester.pumpAndSettle();
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        expect(tester.takeException(), isNull);

        final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Close resources').hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Close resources'));
        await tester.pumpAndSettle();
        expect(find.byType(ResourceContent), findsNothing);
      });
    }
  }

  testWidgets('terms paragraphs and nested lists honor reading size', (
    tester,
  ) async {
    _setSize(tester, const Size(320, 568));
    final normalGlyphHeights = <String, double>{};
    const samples = [
      'Thanks for using our tool to track rare disease symptoms.',
      'Provide accurate and complete information when creating your account',
    ];

    for (final scale in [1.0, 2.0, 3.0]) {
      await tester.pumpWidget(
        _app(
          const ResourceScreen(topic: ResourceTopic.termsOfService),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      for (final sample in samples) {
        final text = find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains(sample),
        );
        expect(text, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final glyphHeight = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 1),
            )
            .single
            .toRect()
            .height;
        if (scale == 1) {
          expect(glyphHeight, greaterThan(0));
          normalGlyphHeights[sample] = glyphHeight;
        } else {
          expect(
            glyphHeight,
            closeTo(normalGlyphHeights[sample]! * scale, 1),
            reason: 'Actual rendered terms glyphs must scale at ${scale}x.',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('desktop help uses a bounded dialog with scrollable content', (
    tester,
  ) async {
    _setSize(tester, const Size(1440, 900));
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ResourceInfoButton(topic: ResourceTopic.termsOfService),
        ),
      ),
    );
    await tester.tap(find.byType(ResourceInfoButton));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    final contentBounds = tester.getRect(find.byType(ResourceContent));
    expect(contentBounds.width, lessThanOrEqualTo(720));
    expect(contentBounds.center.dx, closeTo(720, 1));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close resources').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Close resources'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('failed external links show actionable feedback', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      _app(const ResourceScreen(topic: ResourceTopic.bluePoop)),
    );
    await tester.ensureVisible(find.text('Visit bluepoop.info'));
    await tester.tap(find.text('Visit bluepoop.info'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(
      find.text('Unable to open https://www.bluepoop.info/. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: ThemeData(fontFamily: 'Inter'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
