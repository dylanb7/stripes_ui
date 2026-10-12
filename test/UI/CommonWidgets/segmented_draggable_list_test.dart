import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/CommonWidgets/segmented_draggable_list.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

void main() {
  testWidgets('dragging reorders a page without mutating the input lists', (
    tester,
  ) async {
    final originalItems = <String>['A', 'B', 'C'];
    List<SegmentedDraggablePage<String>>? saved;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: SegmentedDraggableList<String>(
              layouts: [
                SegmentedDraggablePage(id: 'section-1', items: originalItems),
              ],
              canAddFirstPage: false,
              canAddLastPage: false,
              setNotEditing: () {},
              save: (layouts) async {
                saved = layouts;
                return true;
              },
              buildItem: (context, item, handle, enabled) => SizedBox(
                height: 64,
                child: Row(
                  children: [
                    Expanded(child: Text(item)),
                    ?handle,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final handles = find.byIcon(Icons.drag_indicator);
    expect(handles, findsNWidgets(3));
    final start = tester.getCenter(handles.at(0));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    final targets = find.byType(DragTarget<String>);
    expect(targets, findsNWidgets(6));
    final end = tester.getCenter(targets.at(3));
    await gesture.moveTo(end, timeStamp: const Duration(milliseconds: 300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(originalItems, ['A', 'B', 'C']);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.single.items, ['B', 'C', 'A']);
  });
}
