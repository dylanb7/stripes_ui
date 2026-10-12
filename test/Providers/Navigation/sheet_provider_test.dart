import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

Future<ProviderContainer> _openSheet(
  WidgetTester tester, {
  required Size size,
  bool safeArea = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: const EdgeInsets.only(top: 20, bottom: 12)),
          child: child!,
        ),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => ref
                  .read(sheetControllerProvider)
                  .show<void>(
                    context: context,
                    safeArea: safeArea,
                    scrollControlled: true,
                    child: (context) => SizedBox(
                      key: const ValueKey('sheet-content'),
                      width: double.infinity,
                      height: 200,
                      child: Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ),
                  ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.text('Open sheet')),
  );
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
  expect(container.read(isSheetOpenProvider), isTrue);
  return container;
}

void main() {
  for (final safeArea in [true, false]) {
    testWidgets('short screens use full width; safe area $safeArea', (
      tester,
    ) async {
      final container = await _openSheet(
        tester,
        size: const Size(320, 568),
        safeArea: safeArea,
      );
      final bounds = tester.getRect(
        find.byKey(const ValueKey('sheet-content')),
      );
      expect(bounds.left, 0);
      expect(bounds.width, 320);
      expect(bounds.top, safeArea ? 20 : 0);
      expect(bounds.bottom, safeArea ? 556 : 568);
      expect(find.text('Close').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(container.read(isSheetOpenProvider), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large screens retain a centered bounded dialog', (tester) async {
    await _openSheet(tester, size: const Size(1600, 1000));
    final bounds = tester.getRect(find.byKey(const ValueKey('sheet-content')));
    expect(bounds.width, 1000);
    expect(bounds.height, 200);
    expect(bounds.left, 300);
    expect(find.text('Close').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
