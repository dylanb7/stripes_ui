// Explicitly invoked discovery suite; intentionally not named *_test.dart.
// flutter test test/accessibility/text_size_audit.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/account_management_screen.dart';
import 'package:stripes_ui/UI/AccountManagement/display_settings.dart';
import 'package:stripes_ui/UI/CommonWidgets/discard_changes_sheet.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/date_header.dart';
import 'package:stripes_ui/UI/History/Filters/filter_sheet.dart';
import 'package:stripes_ui/UI/History/Filters/filter_logic.dart';
import 'package:stripes_ui/UI/History/Timeline/bottom_sheet_calendar.dart';
import 'package:stripes_ui/UI/History/Timeline/list_style_view.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/UI/Record/RecordSplit/record_entry.dart';
import 'package:stripes_ui/UI/Record/Screens/submit_screen.dart';
import 'package:stripes_ui/UI/Record/TestScreen/blue_meal_info.dart';

import 'audit_fixtures.dart';
import 'audit_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final report = AuditReport(
    const String.fromEnvironment(
      'A11Y_OUTPUT',
      defaultValue: 'build/text_size_audit',
    ),
  );
  const strict = bool.fromEnvironment('A11Y_STRICT');
  setUpAll(() async {
    await initializeDateFormatting();
    await loadAuditFonts();
  });
  tearDownAll(() {
    report.write();
    debugPrint('Text size audit: ${report.output.path}/index.html');
    debugPrint(
      strict
          ? 'Strict mode fails cases containing recorded layout errors.'
          : 'Discovery mode records known layout errors. '
                'Use --dart-define=A11Y_STRICT=true to fail on them.',
    );
  });

  for (final screen in [
    'history',
    'record-menu',
    'record-flow',
    'record-flow-redesigned',
    'study-instructions',
    'account',
    'detail-fields-auto',
    'detail-fields-stacked',
  ]) {
    for (final device in auditDevices) {
      for (final scale in [1.0, 1.5, 2.0, 3.0]) {
        testWidgets('$screen ${device.name} ${scale}x', (tester) async {
          tester.view.physicalSize = device.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fixtures = AuditFixtures();
          final run = AuditRun(
            tester,
            screen,
            device,
            scale,
            output: report.output,
          );
          report.runs.add(run);
          run.start();
          try {
            Future<void> mount(Widget widget, {bool redesigned = false}) =>
                tester.pumpWidget(
                  fixtures.app(run, widget, redesigned: redesigned),
                );
            switch (screen) {
              case 'history':
                await run.checkpoint(
                  'top',
                  () => mount(
                    auditShell(const EventsView(), tab: TabOption.history),
                  ),
                );
                final container = ProviderScope.containerOf(
                  tester.element(find.byType(EventsView)),
                );
                final scroll = container.read(historyScrollControllerProvider);
                await run.checkpoint('filters', () async {
                  await tester.tap(find.byTooltip('Filters'));
                });
                expect(find.byType(FilterSheet), findsOneWidget);
                Navigator.of(tester.element(find.byType(EventsView))).pop();
                await tester.pumpAndSettle();
                await run.checkpoint('active-filter', () async {
                  container.read(displayDataProvider.notifier).updateFilters([
                    LabeledFilter(
                      name: 'Bowel Movement',
                      filterType: FilterType.category,
                      filter: (response) => response.type == 'Bowel Movement',
                    ),
                  ]);
                });
                container.read(displayDataProvider.notifier).updateFilters([]);
                await tester.pumpAndSettle();
                await run.checkpoint('expanded-entry', () async {
                  // At very large sizes the toolbar can fill the first
                  // viewport; materialize the lazy list's first entry.
                  for (
                    var attempt = 0;
                    find.byType(EntryDisplay).evaluate().isEmpty &&
                        attempt < 20;
                    attempt++
                  ) {
                    final next = (scroll.offset + device.size.height * 0.5)
                        .clamp(0.0, scroll.position.maxScrollExtent);
                    if (next == scroll.offset) break;
                    scroll.jumpTo(next);
                    await tester.pumpAndSettle();
                  }
                  expect(find.byType(EntryDisplay), findsWidgets);
                  final entry = find.byType(EntryDisplay).first;
                  await tester.ensureVisible(entry);
                  await tester.pumpAndSettle();
                  // ensureVisible cannot account for an overlapping pinned
                  // day heading. Leave that heading clear before tapping.
                  final dayHeader = tester
                      .widgetList<SliverPersistentHeader>(
                        find.byWidgetPredicate(
                          (widget) =>
                              widget is SliverPersistentHeader &&
                              widget.delegate is DateHeaderDelegate,
                        ),
                      )
                      .first;
                  scroll.jumpTo(
                    (scroll.offset - dayHeader.delegate.maxExtent - 8).clamp(
                      0,
                      scroll.position.maxScrollExtent,
                    ),
                  );
                  await tester.pumpAndSettle();
                  await tester.tap(
                    find
                        .descendant(of: entry, matching: find.byType(InkWell))
                        .first,
                  );
                });
                await run.checkpoint('expanded-details', () async {
                  scroll.jumpTo(
                    (scroll.offset + 220).clamp(
                      0,
                      scroll.position.maxScrollExtent,
                    ),
                  );
                });
                await run.checkpoint('entry-controls', () async {
                  await Scrollable.ensureVisible(
                    tester.element(
                      find.byKey(const ValueKey('entry-controls')).first,
                    ),
                    alignment: 0.5,
                  );
                });
                expect(
                  find.byTooltip('Edit entry').hitTestable(),
                  findsOneWidget,
                );
                expect(find.byTooltip('Delete').hitTestable(), findsOneWidget);
                await run.checkpoint('floating-date', () async {
                  scroll.jumpTo(scroll.position.maxScrollExtent);
                  await tester.pumpAndSettle();
                  scroll.jumpTo(scroll.position.maxScrollExtent - 60);
                });
                expect(
                  find.byKey(const ValueKey('history-floating-date')),
                  findsOneWidget,
                );
                await run.checkpoint('calendar', () async {
                  final date = find.descendant(
                    of: find.byKey(const ValueKey('history-floating-date')),
                    matching: find.byType(Text),
                  );
                  await tester.tap(date.first);
                });
                expect(find.byType(BottomSheetCalendar), findsOneWidget);
              case 'record-menu':
                await run.checkpoint(
                  'top',
                  () => mount(
                    auditShell(
                      const RecordScreenContent(),
                      tab: TabOption.record,
                    ),
                  ),
                );
                await _sweep(run);
              case 'record-flow':
              case 'record-flow-redesigned':
                await run.checkpoint(
                  'stool',
                  () => mount(
                    auditShell(
                      RecordSplitter(
                        type: fixtures.path.name,
                        data: fixtures.session,
                      ),
                    ),
                    redesigned: screen.endsWith('redesigned'),
                  ),
                );
                final state = tester.state<RecordSplitterState>(
                  find.byType(RecordSplitter),
                );
                await _sweep(run, name: 'stool');
                for (final (page, name) in [
                  (1, 'pain'),
                  (2, 'questions'),
                  (3, 'submit'),
                ]) {
                  await run.checkpoint(name, () async {
                    state.pageController.jumpToPage(page);
                  });
                  await _sweep(run, name: name);
                }
                expect(find.byType(SubmitScreen), findsOneWidget);
                await run.checkpoint('leave-confirmation', () async {
                  final context = tester.element(find.byType(RecordSplitter));
                  ProviderScope.containerOf(context)
                      .read(sheetControllerProvider)
                      .show<bool>(
                        context: context,
                        scrollControlled: true,
                        child: (_) => const DiscardChangesSheet(),
                      );
                });
              case 'study-instructions':
                await run.checkpoint(
                  'top',
                  () => mount(
                    auditShell(
                      PreStudyInfo(onClick: () {}, isLoading: false),
                      tab: TabOption.tests,
                    ),
                  ),
                );
                await _sweep(run);
              case 'account':
                await run.checkpoint(
                  'top',
                  () => mount(auditShell(const AccountManagementScreen())),
                );
                await _sweep(run);
                await run.checkpoint('reading-preferences', () async {
                  await tester.ensureVisible(find.byType(DisplaySettingsTile));
                  await tester.pumpAndSettle();
                  await tester.tap(find.byType(DisplaySettingsTile));
                });
                expect(find.byType(DisplaySettingsSheet), findsOneWidget);
              case 'detail-fields-auto':
              case 'detail-fields-stacked':
                await run.checkpoint(
                  'top',
                  () => tester.pumpWidget(
                    fixtures.app(
                      run,
                      auditShell(fixtures.detailGallery()),
                      detailPreference: screen.endsWith('stacked')
                          ? DetailLayoutPreference.stacked
                          : DetailLayoutPreference.automatic,
                    ),
                  ),
                );
                await _sweep(run);
                // These fields are now fixed: keep their audit cases strict.
                expect(
                  run.issues,
                  isEmpty,
                  reason: 'Detail readability regression',
                );
            }
          } catch (error, stack) {
            run.addIssue(
              kind: 'scenario-error',
              severity: 'error',
              message: error.toString(),
              source: screen,
              detail: '$stack',
            );
            rethrow;
          } finally {
            // Dispose widgets/timers/providers before the graph and restore the
            // test handler even when a fixture or interaction fails.
            try {
              await tester.pumpWidget(const SizedBox());
              await tester.pumpAndSettle();
              fixtures.dispose();
            } finally {
              run.stop();
              report.write();
            }
          }
          if (strict) {
            expect(
              run.hasErrors,
              isFalse,
              reason: 'See ${report.output.path}/index.html for ${run.id}',
            );
          }
        });
      }
    }
  }
}

Future<void> _sweep(AuditRun run, {String name = 'scroll'}) async {
  final candidates = find
      .byType(Scrollable)
      .evaluate()
      .map((e) => (e as StatefulElement).state)
      .whereType<ScrollableState>()
      .where(
        (s) =>
            axisDirectionToAxis(s.position.axisDirection) == Axis.vertical &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 0 &&
            run.tester
                .getRect(find.byWidget(s.widget))
                .overlaps(Offset.zero & run.device.size),
      )
      .toList();
  if (candidates.isEmpty) return;
  // Screen's primary vertical scroll, excluding horizontal page/carousels.
  final scrollable = candidates.first;
  final position = scrollable.position;
  final style = Theme.of(scrollable.context).textTheme.bodyMedium!;
  final lineHeight =
      MediaQuery.textScalerOf(scrollable.context).scale(style.fontSize!) *
      (style.height ?? 1.2);
  if (position.viewportDimension < lineHeight * 2) {
    run.addIssue(
      kind: 'constrained-scroll-viewport',
      severity: 'review',
      message:
          'Only ${position.viewportDimension.round()} px remain for '
          'scrollable content (less than two body-text lines).',
      source: run.screen,
      detail:
          'Fixed header/footer controls consume the screen. '
          'Middle and bottom are sampled; a continuous sweep is omitted.',
    );
    if (position.viewportDimension > 0) {
      for (final (label, fraction) in [('middle', 0.5), ('bottom', 1.0)]) {
        await run.checkpoint(
          '$name-$label',
          () async => position.jumpTo(position.maxScrollExtent * fraction),
        );
      }
    }
    return;
  }
  // Overlapping viewports expose clipped text between the first and last
  // screens. Never silently truncate coverage if a fixture grows too long.
  for (var step = 1; position.pixels < position.maxScrollExtent - 1; step++) {
    if (step > 300) throw StateError('Scroll audit exceeded 300 captures');
    final delta = position.viewportDimension * 0.75;
    if (delta <= 0) {
      run.addIssue(
        kind: 'unreachable-scroll-content',
        severity: 'error',
        message: 'Scrollable content has no visible viewport.',
        source: run.screen,
      );
      return;
    }
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final label = next == position.maxScrollExtent
        ? '$name-bottom'
        : '$name-$step';
    await run.checkpoint(label, () async => position.jumpTo(next));
  }
}
