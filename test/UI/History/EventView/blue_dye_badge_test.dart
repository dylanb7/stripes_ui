import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Models/record_time.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye_badge.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';
import 'package:stripes_ui/l10n/questions_delegate.dart';

import '../../../accessibility/audit_harness.dart';

const _captureKey = ValueKey('history-bm-header-capture');
final _date = DateTime(2026, 10, 14, 7, 25);

MultiResponse _answer(int index, {bool custom = false}) => MultiResponse(
  question: MultipleChoice(
    id: 'BlueDyeQuestion',
    type: 'category.BM',
    prompt: 'Did this bowel movement contain any blue color?',
    shortPrompt: 'preview.blue',
    previewPriority: 20,
    choices: const ['Yes', 'No'],
    userCreated: custom,
  ),
  index: index,
  stamp: dateToStamp(_date),
);

List<Response> _measurements() => [
  NumericResponse(
    question: const Numeric(
      id: 'q4',
      type: 'category.BM',
      prompt: 'Average BM type (1–7)',
      shortPrompt: 'preview.stool_type',
      previewPriority: 0,
      min: 1,
      max: 7,
    ),
    response: 4,
    stamp: dateToStamp(_date),
  ),
  NumericResponse(
    question: const Numeric(
      id: 'q6',
      type: 'category.BM',
      prompt: 'Pain with bowel movement',
      shortPrompt: 'preview.pain',
      previewPriority: 10,
      min: 0,
      max: 10,
    ),
    response: 2,
    stamp: dateToStamp(_date),
  ),
];

DetailResponse _detail({
  String id = 'bowel',
  String type = 'category.BM',
  List<Response> answers = const [],
  String? sessionId,
}) => DetailResponse(
  id: id,
  detailType: type,
  stamp: dateToStamp(_date),
  linkingId: sessionId,
  responses: answers,
);

TimedDetailResponse _withMetadata(
  DetailResponse detail, {
  Object? isBlue,
  String? sessionId,
}) => TimedDetailResponse(
  response: detail,
  entry: Entry(
    id: detail.id,
    subUserId: 'participant',
    stamp: _date,
    entityType: 'event',
    sessionId: sessionId,
    data: {'type': detail.type, 'isBlue': ?isBlue},
  ),
);

class _QuestionTranslations
    extends LocalizationsDelegate<QuestionsLocalizations> {
  const _QuestionTranslations();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<QuestionsLocalizations> load(Locale locale) => SynchronousFuture(
    QuestionsLocalizations(questionTranslationPath: 'unused')
      ..currentLocale = locale.languageCode
      ..questionTranslations = {
        locale.languageCode: {
          'category.BM': 'Bowel Movement',
          'preview.blue': 'Blue color',
          'preview.stool_type': 'Stool type',
          'preview.pain': 'Pain',
        },
      },
  );

  @override
  bool shouldReload(_QuestionTranslations old) => false;
}

Future<void> _pumpEntries(
  WidgetTester tester,
  List<DetailResponse> entries, {
  bool beta = true,
  bool themed = true,
  bool compact = false,
  bool darkMode = false,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final selectedTheme = darkMode ? dark : light;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(
            betaUi: BetaUiConfig.disabled(
              historyOverview: beta,
              compactHistory: compact,
              useCategoryTheme: themed,
            ),
          ),
        ),
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: selectedTheme.copyWith(
          platform: TargetPlatform.iOS,
          textTheme: selectedTheme.textTheme.apply(fontFamily: 'Inter'),
        ),
        localizationsDelegates: const [
          _QuestionTranslations(),
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in entries) ...[
                    EntryDisplay(
                      key: ValueKey(entry.id!),
                      event: entry,
                      dateLabel: '7:25 AM',
                      hasControls: false,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  const configured = String.fromEnvironment('HISTORY_HEADER_CAPTURE');
  if (configured.isEmpty || configured == 'false') return;
  final directory = configured == 'true' ? 'build/history_header' : configured;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    Directory(directory).createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$directory/$name.png').writeAsBytesSync(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  group('recorded study result', () {
    test(
      'accepts recorded yes and no for current and legacy BM categories',
      () {
        for (final type in ['category.BM', 'Bowel Movement', 'BM']) {
          expect(
            recordedBlueDyeResult(_detail(type: type, answers: [_answer(0)])),
            isTrue,
          );
          expect(
            recordedBlueDyeResult(_detail(type: type, answers: [_answer(1)])),
            isFalse,
          );
        }
      },
    );

    test('does not infer a result from a session or unrelated category', () {
      expect(
        recordedBlueDyeResult(_detail(sessionId: 'recording-batch')),
        isNull,
      );
      expect(
        recordedBlueDyeResult(_withMetadata(_detail(), sessionId: 'study-run')),
        isNull,
      );
      expect(
        recordedBlueDyeResult(
          _detail(type: 'category.PAIN', answers: [_answer(0)]),
        ),
        isNull,
      );
    });

    test('rejects custom, invalid, and conflicting study answers', () {
      for (final answers in <List<Response>>[
        [_answer(0, custom: true)],
        [_answer(-1)],
        [_answer(2)],
        [_answer(0), _answer(1)],
      ]) {
        expect(recordedBlueDyeResult(_detail(answers: answers)), isNull);
      }
    });

    test('keeps explicit metadata for older entries without an answer', () {
      expect(
        recordedBlueDyeResult(_withMetadata(_detail(), isBlue: true)),
        isTrue,
      );
      expect(
        recordedBlueDyeResult(_withMetadata(_detail(), isBlue: false)),
        isFalse,
      );
      expect(
        recordedBlueDyeResult(_withMetadata(_detail(), isBlue: 'false')),
        isNull,
      );
      expect(
        recordedBlueDyeResult(
          _withMetadata(_detail(type: 'category.PAIN'), isBlue: true),
        ),
        isNull,
      );
    });

    test(
      'metadata does not override an answer or conceal conflicting data',
      () {
        expect(
          recordedBlueDyeResult(
            _withMetadata(_detail(answers: [_answer(1)]), isBlue: true),
          ),
          isFalse,
        );
        for (final answers in <List<Response>>[
          [_answer(2)],
          [_answer(0), _answer(1)],
        ]) {
          expect(
            recordedBlueDyeResult(
              _withMetadata(_detail(answers: answers), isBlue: false),
            ),
            isNull,
          );
        }
      },
    );
  });

  for (final isBlue in [true, false]) {
    testWidgets(
      'beta ${isBlue ? 'blue' : 'no-blue'} entry has one category icon and an accessible result',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpEntries(tester, [
            _detail(answers: [_answer(isBlue ? 0 : 1)]),
          ]);
          expect(find.byType(CategoryIcon), findsOneWidget);
          expect(find.byType(Image), findsNothing);
          expect(find.byType(HistoryBlueDyeBadge), findsOneWidget);
          final label = isBlue ? 'Blue' : 'No blue';
          final description = isBlue
              ? 'Blue color recorded'
              : 'No blue color recorded';
          expect(find.text(label), findsOneWidget);
          expect(find.byTooltip(description), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(description))),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('ordinary bowel movement has no study badge', (tester) async {
    await _pumpEntries(tester, [_detail()]);
    expect(find.byType(CategoryIcon), findsOneWidget);
    expect(find.byType(HistoryBlueDyeBadge), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  for (final themed in [false, true]) {
    testWidgets(
      'study status remains visible in compact history with theme $themed',
      (tester) async {
        await _pumpEntries(
          tester,
          [
            _detail(answers: [_answer(1)]),
          ],
          compact: true,
          themed: themed,
          width: 320,
          textScale: 3,
        );
        expect(
          find.byKey(const ValueKey('compact-entry-surface')),
          findsOneWidget,
        );
        expect(find.text('No blue'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('changing the entry removes a previously displayed result', (
    tester,
  ) async {
    await _pumpEntries(tester, [
      _detail(answers: [_answer(0)]),
    ]);
    final priorState = tester.state<EntryDisplayState>(
      find.byType(EntryDisplay),
    );
    expect(find.text('Blue'), findsOneWidget);
    await _pumpEntries(tester, [_detail()]);
    expect(
      tester.state<EntryDisplayState>(find.byType(EntryDisplay)),
      same(priorState),
    );
    expect(find.byType(HistoryBlueDyeBadge), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('beta-disabled entries preserve the existing image treatment', (
    tester,
  ) async {
    await _pumpEntries(tester, [
      _detail(answers: [_answer(0)]),
    ], beta: false);
    expect(find.byType(HistoryBlueDyeBadge), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, endsWith('/Blue_Poop.png'));
  });

  for (final darkMode in [false, true]) {
    for (final size in [(390.0, 1.0), (320.0, 3.0)]) {
      testWidgets(
        'BM header fits ${size.$1}px at ${size.$2}x in ${darkMode ? 'dark' : 'light'} mode',
        (tester) async {
          await tester.runAsync(loadAuditFonts);
          await _pumpEntries(
            tester,
            [
              _detail(id: 'ordinary', answers: _measurements()),
              _detail(
                id: 'study-no-blue',
                answers: [..._measurements(), _answer(1)],
              ),
              _detail(
                id: 'study-blue',
                answers: [..._measurements(), _answer(0)],
              ),
            ],
            width: size.$1,
            textScale: size.$2,
            darkMode: darkMode,
          );
          expect(find.byType(HistoryBlueDyeBadge), findsNWidgets(2));
          expect(find.byType(CategoryIcon), findsNWidgets(3));
          expect(find.byType(Image), findsNothing);
          expect(tester.takeException(), isNull);
          for (final badge in find.byType(HistoryBlueDyeBadge).evaluate()) {
            final rect = tester.getRect(find.byWidget(badge.widget));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.$1));
          }
          await _capture(
            tester,
            'bm-headers-${size.$1.toInt()}px-${size.$2}x-${darkMode ? 'dark' : 'light'}',
          );
        },
      );
    }
  }
}
