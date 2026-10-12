import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';

import '../../accessibility/audit_fixtures.dart';
import '../../accessibility/audit_harness.dart';

void main() {
  setUpAll(loadAuditFonts);

  for (final device in auditDevices) {
    for (final terms in [false, true]) {
      testWidgets(
        '${terms ? 'terms' : 'study'} remains readable and requires acceptance on ${device.name} at 3x',
        (tester) async {
          tester.view.physicalSize = device.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixtures = AuditFixtures();
          final run = AuditRun(tester, 'study-reading', device, 3);
          var continued = false;
          await tester.pumpWidget(
            fixtures.app(
              run,
              auditShell(
                terms
                    ? AppTos(onContinue: () => continued = true)
                    : PreStudyInfo(
                        onClick: () => continued = true,
                        isLoading: false,
                      ),
                tab: TabOption.tests,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final scrollView = find.byType(SingleChildScrollView).first;
          expect(tester.getSize(scrollView).height, greaterThan(126));
          final action = find.byType(FilledButton).last;
          expect(tester.widget<FilledButton>(action).onPressed, isNull);
          final checkbox = find.byType(Checkbox);
          await tester.ensureVisible(checkbox);
          await tester.pumpAndSettle();
          final position = tester
              .widget<SingleChildScrollView>(scrollView)
              .controller!;
          final offset = position.offset;
          final label = find.descendant(
            of: find.byType(ReadConfirmation),
            matching: find.byType(Text),
          );
          final labelRect = tester.getRect(label);
          await tester.tapAt(
            Offset(labelRect.left + 12, tester.getCenter(checkbox).dy),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(checkbox).value, isTrue);
          expect(position.offset, offset);
          expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(continued, isTrue);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          fixtures.dispose();
        },
      );
    }
  }
}
