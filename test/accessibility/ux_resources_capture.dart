// Explicit visual audit: flutter test test/accessibility/ux_resources_capture.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/Resources/resources.dart';

import 'audit_fixtures.dart';
import 'audit_harness.dart';

void main() {
  final report = AuditReport('build/ux_resources_after');
  setUpAll(loadAuditFonts);
  tearDownAll(report.write);
  for (final device in auditDevices) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('resources ${device.name} ${scale}x', (tester) async {
        tester.view.physicalSize = device.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixtures = AuditFixtures();
        final run = AuditRun(
          tester,
          'resources',
          device,
          scale,
          output: report.output,
        );
        report.runs.add(run);
        run.start();
        try {
          await run.checkpoint('hub', () async {
            await tester.pumpWidget(fixtures.app(run, const ResourcesScreen()));
          });
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            fixtures.app(
              run,
              const Scaffold(
                body: ResourceInfoButton(
                  topic: ResourceTopic.bristolScale,
                  sectionId: 'stool-types',
                ),
              ),
            ),
          );
          await run.checkpoint('quick-help', () async {
            await tester.tap(find.byType(ResourceInfoButton));
          });
          await run.checkpoint('full-guide', () async {
            await tester.ensureVisible(find.text('Read full guide'));
            await tester.tap(find.text('Read full guide'));
          });
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          fixtures.dispose();
          run.stop();
        }
        expect(run.hasErrors, isFalse, reason: run.issues.toString());
      });
    }
  }
}
