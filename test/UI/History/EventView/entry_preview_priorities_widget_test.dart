import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import '../../../accessibility/audit_harness.dart';

const _captureKey = ValueKey('entry-preview-priorities-capture');

List<DetailResponse> _records() {
  final stamp = dateToStamp(DateTime(2026, 10, 14, 7, 25));
  Selected checked(
    String id,
    String prompt,
    String type, {
    String? shortPrompt,
  }) => Selected(
    question: Check(
      id: id,
      prompt: prompt,
      type: type,
      shortPrompt: shortPrompt,
      previewPriority: 30,
    ),
    stamp: stamp,
  );
  NumericResponse number(
    String id,
    String prompt,
    String type,
    num value, {
    required String shortPrompt,
    required int priority,
  }) => NumericResponse(
    question: Numeric(
      id: id,
      prompt: prompt,
      type: type,
      shortPrompt: shortPrompt,
      previewPriority: priority,
    ),
    stamp: stamp,
    response: value,
  );
  DetailResponse record(String id, String type, List<Response> responses) =>
      DetailResponse(
        id: id,
        detailType: type,
        stamp: stamp,
        responses: responses,
      );

  return [
    record('pain', 'Pain', [
      checked('q1', 'Pointed to their stomach as if in pain', 'Pain'),
      checked(
        'q18',
        'Pressed their abdomen against furniture or other objects',
        'Pain',
      ),
      number(
        'Pain-Rating',
        'How much pain are they experiencing?',
        'Pain',
        6,
        shortPrompt: 'Pain',
        priority: 0,
      ),
      AllResponse(
        question: const AllThatApply(
          id: 'Pain-Location',
          prompt: 'Where was the pain?',
          shortPrompt: 'Location',
          previewPriority: 10,
          type: 'Pain',
          choices: ['Not sure', 'Upper right', 'Lower right'],
        ),
        stamp: stamp,
        responses: [2],
      ),
    ]),
    record('bowel', 'Bowel Movement', [
      checked('q8', 'Struggled or strained during a bowel movement', 'BM'),
      number(
        'q4',
        'Average BM type (1–7)',
        'BM',
        4,
        shortPrompt: 'Stool type',
        priority: 0,
      ),
      number('q6', 'Pain with BM', 'BM', 2, shortPrompt: 'Pain', priority: 10),
    ]),
    record('sleep', 'Sleep & Mood', [
      checked(
        'q21',
        'Had difficulty falling asleep at night',
        'Sleep',
        shortPrompt: 'Difficulty falling asleep',
      ),
      checked(
        'q24',
        'Seemed more irritable than usual',
        'Sleep',
        shortPrompt: 'Increased irritability',
      ),
    ]),
    record('meal', 'Meal Time', [
      MultiResponse(
        question: const MultipleChoice(
          id: 'Meal-Type',
          prompt: 'What meal type was provided?',
          shortPrompt: 'Meal',
          previewPriority: 0,
          type: 'Meal Time',
          choices: ['Breakfast', 'Lunch', 'Dinner'],
        ),
        stamp: stamp,
        index: 2,
      ),
    ]),
    record('custom', 'My observations', [
      OpenResponse(
        question: const FreeResponse(
          id: 'custom-note',
          prompt:
              'What stood out about their day that you would like to remember?',
          type: 'Custom',
        ),
        stamp: stamp,
        response: 'Walked after dinner and enjoyed a quiet evening',
      ),
    ]),
  ];
}

Future<void> _pumpEntries(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configProvider.overrideWith(
          (ref) => StripesConfig.sandbox(
            betaUi: const BetaUiConfig.disabled(historyOverview: true),
          ),
        ),
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: light.copyWith(platform: TargetPlatform.iOS),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
                  const Text('Oct 14 · 5 entries'),
                  const SizedBox(height: 12),
                  for (final entry in _records()) ...[
                    EntryDisplay(
                      key: ValueKey(entry.id!),
                      event: entry,
                      dateLabel: '7:25 AM',
                      hasControls: false,
                    ),
                    const SizedBox(height: 8),
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
  const configuredDirectory = String.fromEnvironment('HISTORY_PREVIEW_CAPTURE');
  if (configuredDirectory.isEmpty || configuredDirectory == 'false') return;
  final directory = configuredDirectory == 'true'
      ? 'build/history_preview'
      : configuredDirectory;
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

Finder _preview(String id) => find.descendant(
  of: find.byKey(ValueKey(id)),
  matching: find.byKey(const ValueKey('entry-preview')),
);

void main() {
  setUpAll(loadAuditFonts);

  for (final device in [(390.0, 1.0), (320.0, 3.0)]) {
    final (width, scale) = device;
    testWidgets(
      'prioritized previews remain legible at ${width}px and ${scale}x',
      (tester) async {
        await _pumpEntries(tester, width: width, textScale: scale);
        final expected = {
          'pain': 'Pain: 6 · Location: Lower right',
          'bowel': 'Stool type: 4 · Pain: 2',
          'sleep': 'Difficulty falling asleep · Increased irritability',
          'meal': 'Meal: Dinner',
        };
        for (final entry in expected.entries) {
          final preview = _preview(entry.key);
          expect(tester.widget<Text>(preview).data, entry.value);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: preview, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: entry.key);
          await tester.ensureVisible(preview);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(preview);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
          final timestamp = find.descendant(
            of: find.byKey(ValueKey(entry.key)),
            matching: find.text('7:25 AM'),
          );
          expect(
            bounds.left,
            closeTo(tester.getRect(timestamp).left, 0.01),
            reason: 'Preview aligns with its category and timestamp',
          );
          expect(tester.takeException(), isNull);
          if (scale > 1) {
            await _capture(tester, '${entry.key}-${width.toInt()}px-${scale}x');
          }
        }

        final custom = tester.widget<Text>(_preview('custom'));
        expect(custom.data, contains(': Walked after'));
        expect(
          custom.semanticsLabel,
          'What stood out about their day that you would like to remember?: '
          'Walked after dinner and enjoyed a quiet evening',
        );
        await tester.ensureVisible(_preview('custom'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, 'custom-${width.toInt()}px-${scale}x');

        await tester.ensureVisible(find.byKey(const ValueKey('pain')));
        await tester.pumpAndSettle();
        await _capture(tester, 'previews-${width.toInt()}px-${scale}x');
        if (scale == 1) {
          final entry = find.byKey(const ValueKey('pain'));
          final timestamp = find.descendant(
            of: entry,
            matching: find.text('7:25 AM'),
          );
          final originalTimestampTop = tester.getTopLeft(timestamp).dy;
          tester.state<EntryDisplayState>(entry).controller.expand();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          final fading = tester.widget<FadeTransition>(
            find
                .ancestor(
                  of: _preview('pain'),
                  matching: find.byType(FadeTransition),
                )
                .first,
          );
          expect(fading.opacity.value, allOf(greaterThan(0), lessThan(1)));
          expect(
            tester.getTopLeft(timestamp).dy,
            lessThan(originalTimestampTop),
          );
          await tester.pumpAndSettle();
          expect(_preview('pain'), findsNothing);
          expect(timestamp, findsOneWidget);
          expect(tester.takeException(), isNull);
          await _capture(tester, 'pain-expanded-${width.toInt()}px-${scale}x');
        }
      },
    );
  }
}
