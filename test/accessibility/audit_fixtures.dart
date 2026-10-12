import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Insights/insights.dart';
import 'package:stripes_ui/Models/app_display_settings.dart';
import 'package:stripes_ui/Providers/Accessibility/display_settings_provider.dart';
import 'package:stripes_ui/Providers/Auth/auth_provider.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/History/stamps_provider.dart';
import 'package:stripes_ui/Providers/Insights/engine_findings_provider.dart';
import 'package:stripes_ui/Providers/Questions/baseline_trigger_provider.dart';
import 'package:stripes_ui/Providers/Questions/questions_provider.dart';
import 'package:stripes_ui/Providers/Test/test_provider.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/base.dart';
import 'package:stripes_ui/UI/History/EventView/EntryDisplays/blue_dye.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/Design/palette.dart';
import 'package:stripes_ui/Util/Helpers/date_range_utils.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

import 'audit_harness.dart';

const auditQuestions = <Question>[
  Numeric(
    id: 'q4',
    prompt: 'What type of stool occurred?',
    type: 'Bowel Movement',
    min: 1,
    max: 7,
  ),
  Numeric(
    id: 'q6',
    prompt: 'Pain with BM',
    type: 'Bowel Movement',
    min: 0,
    max: 10,
  ),
  MultipleChoice(
    id: 'blue-color',
    prompt: 'Did this bowel movement contain any blue color?',
    type: 'Bowel Movement',
    choices: ['Yes', 'No', 'Not sure'],
  ),
  AllThatApply(
    id: 'symptoms',
    prompt: 'Select all symptoms that apply.',
    type: 'GI Symptoms',
    choices: [
      'Swollen or bloated stomach',
      'Experienced more gas or flatulence than usual',
      'Struggled or strained during bowel movement',
    ],
  ),
  Check(
    id: 'unusual',
    prompt: 'This bowel movement felt unusually difficult.',
    type: 'Bowel Movement',
  ),
  FreeResponse(
    id: 'note',
    prompt: 'Anything else you would like to record?',
    type: 'Bowel Movement',
  ),
];

class _QuestionHome extends QuestionHome {
  _QuestionHome() {
    all = {for (final q in auditQuestions) q.id: q};
  }
  @override
  Map<String, List<Question>> byType() => {
    for (final type in auditQuestions.map((q) => q.type).toSet())
      type: auditQuestions.where((q) => q.type == type).toList(),
  };
}

class _AuditProfile extends SubNotifier {
  @override
  SubState build() {
    final profile = SubUser(
      name: 'Alexandra',
      gender: '',
      birthYear: 2000,
      isControl: false,
      id: 'audit-profile',
    );
    return SubState(subUsers: [profile], selected: profile);
  }
}

class _AuditDate extends DisplayDataProvider {
  @override
  DisplayDataSettings build() => DisplayDataSettings(
    window: TimeWindow.forCycle(TimeCycle.month, anchor: DateTime(2024, 9)),
    axis: GraphYAxis.number,
  );
}

class _AuditDetailLayout extends DisplaySettingsNotifier {
  final DetailLayoutPreference preference;
  _AuditDetailLayout(this.preference);
  @override
  Future<AppDisplaySettings> build() async =>
      AppDisplaySettings(detailLayout: preference);
}

/// Synthetic data only. No repository, credentials, or writes to a backend.
class AuditFixtures {
  final home = _QuestionHome();
  late final path = RecordPath(
    uid: 'audit-record',
    name: 'Bowel Movement',
    pages: [
      PageLayout(uid: 'stool', questionIds: ['q4']),
      PageLayout(uid: 'pain', questionIds: ['q6']),
      PageLayout(
        uid: 'details',
        questionIds: ['blue-color', 'symptoms', 'unusual', 'note'],
      ),
    ],
  );
  late final paths = [
    path,
    for (final name in ['Meal Time', 'GI Symptoms', 'Seizure Checkin'])
      RecordPath(uid: name, name: name, pages: []),
  ];
  late final graph = QuestionGraphBuilder.build(home: home, recordPaths: paths);
  late final answers = <Response>[
    NumericResponse(
      question: auditQuestions[0] as Numeric,
      response: 4,
      stamp: 1,
    ),
    NumericResponse(
      question: auditQuestions[1] as Numeric,
      response: 9,
      stamp: 1,
    ),
    MultiResponse(
      question: auditQuestions[2] as MultipleChoice,
      index: 0,
      stamp: 1,
    ),
    AllResponse(
      question: auditQuestions[3] as AllThatApply,
      responses: [0, 1],
      stamp: 1,
    ),
    Selected(question: auditQuestions[4] as Check, stamp: 1),
    OpenResponse(
      question: auditQuestions[5] as FreeResponse,
      stamp: 1,
      response: 'Felt better after resting.',
    ),
  ];
  late final entries = <Response>[
    DetailResponse(
      id: 'audit-bm',
      detailType: path.name,
      responses: answers,
      stamp: dateToStamp(DateTime(2024, 9, 23, 18, 8)),
    ),
    for (var i = 1; i < 24; i++)
      DetailResponse(
        id: 'audit-entry-$i',
        detailType: i.isEven ? 'Meal Time' : 'GI Symptoms',
        responses: [
          NumericResponse(
            question: Numeric(
              id: 'duration-$i',
              prompt: 'Duration',
              type: i.isEven ? 'Meal Time' : 'GI Symptoms',
            ),
            response: 10 + i,
            stamp: 1,
          ),
        ],
        stamp: dateToStamp(DateTime(2024, 9, 23 - i ~/ 8, 18, 8 - i % 8)),
      ),
  ];
  late final session = SessionData(
    responses: {for (final response in answers) response.question.id: response},
    submitTime: DateTime(2024, 9, 23, 18, 8),
  );

  Widget app(
    AuditRun run,
    Widget child, {
    bool redesigned = false,
    DetailLayoutPreference detailPreference = DetailLayoutPreference.automatic,
    bool displaySettingsEnabled = true,
    bool symptomEditingEnabled = true,
  }) {
    return ProviderScope(
      overrides: [
        displaySettingsProvider.overrideWith(
          () => _AuditDetailLayout(detailPreference),
        ),
        configProvider.overrideWith(
          (ref) => StripesConfig(
            profileType: ProfileType.username,
            hasLogging: true,
            allowsSummaryReport: true,
            betaUi: redesigned
                ? BetaUiConfig.enabled(hasSymptomEditing: symptomEditingEnabled)
                : BetaUiConfig.disabled(
                    hasGraphing: true,
                    hasSymptomEditing: symptomEditingEnabled,
                  ),
            display: StripesDisplayConfig(
              settingsEnabled: displaySettingsEnabled,
              insightsEnabled: true,
            ),
          ),
        ),
        subHolderProvider.overrideWith(_AuditProfile.new),
        authStream.overrideWith((ref) => Stream.value(const AuthUser.empty())),
        stampProvider.overrideWith((ref) async => null),
        testProvider.overrideWith((ref) async => null),
        hasTestsProvider.overrideWith((ref) async => true),
        questionHomeProvider.overrideWith((ref) => Stream.value(home)),
        questionGraphProvider.overrideWith((ref) async => graph),
        baselinesStreamProvider.overrideWith((ref) => Stream.value([])),
        stampsStreamProvider.overrideWith((ref) => Stream.value(entries)),
        availableRecordPaths.overrideWith(
          (ref) async => [for (final p in paths) RecordItem(path: p)],
        ),
        incompleteBaselinesProvider.overrideWith((ref) async => []),
        reviewPaths.overrideWith(
          (ref, props) async => props.searchDate != null
              ? []
              : [
                  ReviewItem(
                    path: RecordPath(
                      uid: 'audit-review',
                      name: 'Weekly Seizure Checkin',
                      pages: [],
                      period: Period.week,
                    ),
                    type: 'Weekly Seizure Checkin',
                    response: null,
                  ),
                ],
        ),
        recordPaths.overrideWith((ref, props) async => []),
        displayDataProvider.overrideWith(_AuditDate.new),
        historyFindingsProvider.overrideWith(
          (ref) async => FindingFeed(
            run: runFindingsFromResponses(
              responses: [],
              windows: findingWindowsForHistoryRange(
                DateTimeRange(
                  start: DateTime(2024, 9),
                  end: DateTime(2024, 10),
                ),
              ),
              catalog: const InsightAnalysisCatalog.empty(),
              rules: [],
            ),
            ranked: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: light.copyWith(platform: TargetPlatform.iOS),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(run.scale),
            padding: run.device.insets,
            viewPadding: run.device.insets,
          ),
          // Outside the Navigator so sheets/dialogs are included in captures.
          child: RepaintBoundary(key: auditBoundaryKey, child: child!),
        ),
        home: child,
      ),
    );
  }

  void dispose() => graph.dispose();

  Widget detailGallery() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final response in [
          NumericResponse(
            question: const Numeric(
              id: 'average',
              prompt: 'Average number of bowel movements per day over the last week',
              type: 'Bowel Movement',
            ),
            response: 4,
            stamp: 1,
          ),
          ...answers,
          MultiResponse(
            question: const MultipleChoice(
              id: 'long-choice',
              prompt:
                  'How did the symptoms affect your usual daily activities?',
              type: 'GI Symptoms',
              choices: ['Needed help completing most daily activities'],
            ),
            index: 0,
            stamp: 1,
          ),
        ]) ...[ResponseDisplay(res: response), const Divider(height: 24)],
        BlueDyeVisualDisplay(
          resp: BlueDyeResp(
            startEating: DateTime(2024, 9, 20, 12),
            eatingDuration: const Duration(minutes: 20),
            normalBowelMovements: 0,
            blueBowelMovements: 1,
            logs: [],
            amountConsumed: AmountConsumed.moreThanHalf,
            firstBlue: DateTime(2024, 9, 21, 8),
            lastBlue: DateTime(2024, 9, 22, 9),
          ),
        ),
      ],
    ),
  );
}

/// PageWrap geometry without Rive's unavailable native renderer in unit tests.
/// The placeholder is fixed-size branding, not a change to the app's header.
Widget auditShell(Widget body, {TabOption? tab}) => Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    scrolledUnderElevation: 0,
    title: const SizedBox(
      height: 35,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'STRiPES',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xff1460a5),
          ),
        ),
      ),
    ),
    actions: const [UserProfileButton(), SizedBox(width: 8)],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1),
    ),
  ),
  body: body,
  bottomNavigationBar: tab == null ? null : SmallLayout(selected: tab),
);
