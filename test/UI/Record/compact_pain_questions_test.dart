import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/compact_record_questions.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_area.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_numeric.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/pain_intensity_selector.dart';
import 'package:stripes_ui/Models/pain_intensity.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/Util/Design/palette.dart';

import '../../accessibility/audit_harness.dart';

const _location = AllThatApply(
  id: 'Pain-Location',
  prompt: 'Pain location',
  type: 'Pain',
  isRequired: true,
  choices: [
    'Unable to determine pain location',
    'Upper left',
    'Top',
    'Upper right',
    'Left',
    'Center',
    'Right',
    'Bottom left',
    'Bottom',
    'Bottom right',
  ],
);
const _level = Numeric(
  id: 'Pain-Rating',
  prompt: 'Pain level',
  type: 'Pain',
  isRequired: true,
);

void main() {
  testWidgets('tapping the initial zero records an explicit pain answer', (
    tester,
  ) async {
    final session = _session();
    await _pump(tester, session);
    await tester.pumpAndSettle();
    expect(session.fromQuestion(_level), isNull);
    expect(
      tester
          .widget<PainIntensitySelector>(find.byType(PainIntensitySelector))
          .selectedBand,
      isNull,
    );
    await _tap(tester, find.byKey(const ValueKey('pain-band-none')));
    await tester.pumpAndSettle();
    expect((session.fromQuestion(_level) as NumericResponse).response, 0);
    expect(tester.takeException(), isNull);
  });

  setUpAll(loadAuditFonts);
  testWidgets(
    'custom controls retain prompt, validation, and exclusive alternatives',
    (tester) async {
      final session = _session();
      await _pump(tester, session);
      await tester.pumpAndSettle();
      expect(find.text(_location.prompt), findsOneWidget);
      expect(find.text(_level.prompt), findsOneWidget);
      session.tried = true;
      await tester.pumpAndSettle();
      expect(
        find.text('Check this answer before continuing.'),
        findsNWidgets(2),
      );

      await _tap(
        tester,
        find.byKey(const ValueKey('compact-pain-location-unknown')),
      );
      expect((session.fromQuestion(_location) as AllResponse).responses, [0]);
      await _tap(tester, find.byType(SelectableTile).first);
      expect((session.fromQuestion(_location) as AllResponse).responses, [1]);
      expect(find.text('Check this answer before continuing.'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('pain-intensity-not-sure')));
      expect((session.fromQuestion(_level) as NumericResponse).response, -1);
      expect(find.text('Check this answer before continuing.'), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('pain-band-severe')));
      expect((session.fromQuestion(_level) as NumericResponse).response, 8);
      expect(
        tester
            .widget<PainIntensitySelector>(find.byType(PainIntensitySelector))
            .notSure,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restored undetermined pain level stays unselected on visual scale',
    (tester) async {
      final session = _session();
      session.setResponse(
        _level,
        response: NumericResponse(question: _level, stamp: 1, response: -1),
      );
      await _pump(tester, session);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Slider), findsNothing);
      expect(
        tester
            .widget<PainIntensitySelector>(find.byType(PainIntensitySelector))
            .selectedBand,
        isNull,
      );
      expect(
        tester
            .widget<PainIntensitySelector>(find.byType(PainIntensitySelector))
            .notSure,
        isTrue,
      );
      expect(find.text('0 · No Hurt'), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('pain-intensity-not-sure')));
      expect(session.fromQuestion(_level), isNull);
    },
  );

  testWidgets(
    'tablet controls stay bounded and Not sure matches the range widths',
    (tester) async {
      tester.view.physicalSize = const Size(784, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, _session());
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('compact-pain-location-diagram')),
            )
            .width,
        440,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('compact-pain-level-control')))
            .width,
        520,
      );
      for (final key in [
        'compact-pain-location-unknown',
        'pain-intensity-not-sure',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, key == 'pain-intensity-not-sure' ? 520 : 752);
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, 'tablet');
    },
  );

  testWidgets('compound controls fit phone width with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, _session(), textScale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('compact-pain-location-diagram')))
          .width,
      343,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('compact-pain-level-control')))
          .width,
      343,
    );
    await _tap(tester, find.byKey(const ValueKey('pain-intensity-not-sure')));
    expect(tester.takeException(), isNull);
    await _capture(tester, 'phone-large-text');
  });

  testWidgets(
    'every pain range saves its representative score and clears Not sure',
    (tester) async {
      final session = _session();
      await _pump(tester, session);
      await tester.pumpAndSettle();
      for (final (name, expected) in [
        ('none', 0),
        ('mild', 2),
        ('moderate', 5),
        ('severe', 8),
        ('worst', 10),
      ]) {
        await _tap(
          tester,
          find.byKey(const ValueKey('pain-intensity-not-sure')),
        );
        expect((session.fromQuestion(_level) as NumericResponse).response, -1);
        await _tap(tester, find.byKey(ValueKey('pain-band-$name')));
        final response = session.fromQuestion(_level)! as NumericResponse;
        expect(response.response, expected);
        expect(
          NumericResponse.fromJson(response.toJson(), _QuestionHome()).response,
          expected,
        );
        final selector = tester.widget<PainIntensitySelector>(
          find.byType(PainIntensitySelector),
        );
        expect(selector.notSure, isFalse);
        expect(selector.selectedBand!.name, name);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restored exact scores and metadata survive reopening and reselecting their range',
    (tester) async {
      final session = _session();
      final original = NumericResponse(
        question: _level,
        stamp: 12345,
        response: 7,
        id: 'saved-pain',
        group: 'recording',
      );
      session.setResponse(_level, response: original);
      await _pump(tester, session);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PainIntensitySelector>(find.byType(PainIntensitySelector))
            .selectedBand,
        PainIntensityBand.severe,
      );
      expect(session.fromQuestion(_level), same(original));
      await _tap(tester, find.byKey(const ValueKey('pain-band-severe')));
      expect(session.fromQuestion(_level), same(original));
      await _tap(tester, find.byKey(const ValueKey('pain-band-moderate')));
      final changed = session.fromQuestion(_level)! as NumericResponse;
      expect(changed.response, 5);
      expect(changed.id, original.id);
      expect(changed.group, original.group);
      expect(changed.stamp, original.stamp);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'range choices remain readable and operable at 320px with 3x text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = _session();
      await _pump(tester, session, textScale: 3);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('pain-band-worst')));
      expect((session.fromQuestion(_level) as NumericResponse).response, 10);
      await _tap(tester, find.byKey(const ValueKey('pain-intensity-not-sure')));
      expect((session.fromQuestion(_level) as NumericResponse).response, -1);
      for (final element
          in find
              .descendant(
                of: find.byType(PainIntensitySelector),
                matching: find.byType(RichText),
              )
              .evaluate()) {
        expect(
          (element.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('custom hierarchy remains scoped to beta form', (tester) async {
    await _pump(tester, _session(), compact: false);
    await tester.pumpAndSettle();
    expect(find.byType(CompactRecordQuestion), findsNothing);
    expect(find.byType(CompactAlternativeAnswer), findsNothing);
    expect(find.text(_location.prompt), findsNothing);
    expect(find.text(_level.prompt), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  SessionGraph session, {
  bool compact = true,
  double textScale = 1,
}) {
  final questions = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PainAreaWidget(questionsListener: session, question: _location),
      PainIntensityWidget(graph: session, question: _level),
    ],
  );
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: const ValueKey('pain-preview'),
              child: ColoredBox(
                color: Colors.white,
                child: compact
                    ? CompactRecordQuestions(
                        requiredLabel: 'Required',
                        invalidLabel: 'Check this answer before continuing.',
                        child: questions,
                      )
                    : questions,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RECORD_FLOW_SCREENSHOTS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('pain-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/private/tmp/stripes-pain-$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

SessionGraph _session() {
  final graph = QuestionGraphBuilder.build(
    home: _QuestionHome(),
    recordPaths: [
      RecordPath(
        name: 'record',
        pages: [
          PageLayout(questionIds: [_location.id, _level.id]),
        ],
      ),
    ],
  );
  final session = graph.createSession(recordPathName: 'record');
  addTearDown(() {
    session.dispose();
    graph.dispose();
  });
  return session;
}

class _QuestionHome extends QuestionHome {
  _QuestionHome() {
    all = {_location.id: _location, _level.id: _level};
  }
  @override
  Map<String, List<Question>> byType() => const {};
}
