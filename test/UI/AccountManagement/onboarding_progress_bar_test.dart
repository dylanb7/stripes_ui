import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/AccountManagement/onboarding_header.dart';
import 'package:stripes_ui/Util/Design/palette.dart';

import '../../accessibility/audit_harness.dart';

Future<void> _pumpHeader(
  WidgetTester tester, {
  required List<String> labels,
  required int currentStep,
  double width = 320,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: OnboardingHeader(
            title: labels[currentStep],
            totalSteps: labels.length,
            currentStep: currentStep,
            labelForStep: (index) => labels[index],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuditFonts);

  for (final textScale in [1.0, 3.0]) {
    testWidgets('long step title fits 320px at ${textScale}x text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      const labels = [
        'Terms and privacy',
        'Profile',
        'Digestive health baseline questionnaire',
        'Overview',
      ];
      await _pumpHeader(
        tester,
        labels: labels,
        currentStep: 2,
        textScale: textScale,
      );
      final title = find.text(labels[2]);
      expect(title, findsOneWidget);
      final progress = find.bySemanticsLabel('Step 3 of 4');
      expect(tester.getSemantics(progress).value, labels[2]);
      expect(tester.getRect(title).right, lessThanOrEqualTo(320));
      expect(tester.getRect(title).bottom, lessThanOrEqualTo(568));
      for (final text in find.byType(RichText).evaluate()) {
        final paragraph = text.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(
        find.text('Step 3 of 4'),
        textScale == 3 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets(
    'segments sit under the title with distinct current and completed colors',
    (tester) async {
      await _pumpHeader(
        tester,
        labels: const ['Terms and privacy', 'Profile', 'Overview'],
        currentStep: 1,
      );
      final titleBottom = tester.getRect(find.text('Profile')).bottom;
      for (var i = 0; i < 3; i++) {
        final segment = find.byKey(ValueKey('onboarding-step-$i'));
        expect(tester.getRect(segment).top, greaterThan(titleBottom));
        expect(find.text('Step ${i + 1}'), findsOneWidget);
        final decoration =
            tester.widget<Container>(segment).decoration! as BoxDecoration;
        expect(
          decoration.color,
          [
            light.colorScheme.primary,
            light.colorScheme.secondary,
            light.colorScheme.primaryContainer,
          ][i],
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single step keeps its title without progress', (tester) async {
    await _pumpHeader(tester, labels: const ['New profile'], currentStep: 0);
    expect(find.text('New profile'), findsOneWidget);
    expect(find.byType(OnboardingProgressBar), findsNothing);
  });

  testWidgets('segments stay short on desktop', (tester) async {
    await _pumpHeader(
      tester,
      labels: const ['Profile', 'Overview'],
      currentStep: 1,
      width: 1200,
    );
    final progress = tester.getRect(find.byType(OnboardingProgressBar));
    expect(progress.width, lessThanOrEqualTo(240));
    expect(progress.left, tester.getRect(find.text('Overview')).left);
    expect(tester.takeException(), isNull);
  });
}
