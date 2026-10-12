import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/UI/Record/QuestionEntries/bowel_movement_full_view_registry.dart';
import 'package:stripes_ui/UI/Record/Screens/question_screen.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';

const String bowelMovementDemoPathName = 'Bowel Movement Description';

const List<Question> bowelMovementDemoQuestions = [
  Numeric(
    id: bowelMovementStoolTypeQuestionId,
    prompt: 'What type of stool occurred?',
    type: 'Bowel Movement Stool Type',
    min: 1,
    max: 7,
  ),
  MultipleChoice(
    id: 'demo-laxatives-taken',
    prompt: 'Did you take anything today that could affect your bowels?',
    type: 'Laxatives & Supplements',
    choices: ['Yes', 'No', 'Not sure'],
  ),
  AllThatApply(
    id: 'demo-laxatives-list',
    prompt: 'Select all that apply.',
    type: 'Laxatives & Supplements',
    choices: [
      'Osmotic (e.g. Miralax)',
      'Stimulant (e.g. Senna)',
      'Stool softener (e.g. Colace)',
      'Bulk-forming (e.g. Metamucil)',
      'Lubricant (e.g. mineral oil)',
      'Saline (e.g. milk of magnesia)',
      'Probiotic supplement',
      'Magnesium supplement',
      'Something else / Other',
    ],
  ),
  MultipleChoice(
    id: 'demo-urgency',
    prompt: 'How would you describe the urgency to use the bathroom?',
    type: 'Urgency',
    choices: [
      'No urgency',
      'Mild urge',
      'Moderate',
      'Very urgent',
      'Did not make it to bathroom',
      'Something else / Other',
      'Not sure',
    ],
  ),
  AllThatApply(
    id: 'demo-stool-observation',
    prompt: 'What did you observe? Select all that apply.',
    type: 'Stool Observation',
    choices: [
      'No observations',
      'Blood in stool',
      'Unusual color',
      'Unusual or foul odor',
      'Undigested food',
      'Black or dark stool',
      'Something else / Other',
      'Not sure',
    ],
  ),
  AllThatApply(
    id: 'demo-stool-symptoms',
    prompt: 'What stool symptoms were experienced? Select all that apply.',
    type: 'Stool Symptoms',
    choices: [
      'None',
      'Increased activity after bowel movement',
      'Swollen or bloated stomach',
      'Experienced more gas or flatulence than usual',
      'Struggled or strained during bowel movement',
      'Lost control of urine or stool',
      'Something else / Other',
      'Not sure',
    ],
  ),
  Check(
    id: 'demo-follow-up',
    prompt: 'This bowel movement felt unusually difficult.',
    type: 'Follow-up',
  ),
  FreeResponse(
    id: 'demo-bowel-note',
    prompt: 'Share any details that would be helpful to remember.',
    type: 'Anything else to add?',
  ),
];

class BowelMovementFullViewDemo extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<DetailResponse>? onSubmit;

  const BowelMovementFullViewDemo({this.onBack, this.onSubmit, super.key});

  @override
  State<BowelMovementFullViewDemo> createState() =>
      _BowelMovementFullViewDemoState();
}

class _BowelMovementFullViewDemoState extends State<BowelMovementFullViewDemo> {
  late final QuestionGraph _graph;
  late final SessionGraph _session;

  @override
  void initState() {
    super.initState();
    final questions = {
      for (final question in bowelMovementDemoQuestions) question.id: question,
    };
    final path = RecordPath(
      uid: 'bowel-movement-full-view-demo',
      name: bowelMovementDemoPathName,
      pages: [
        PageLayout(
          uid: 'bowel-movement-full-view-demo-page',
          questionIds: questions.keys.toList(growable: false),
        ),
      ],
    );
    _graph = QuestionGraphBuilder.build(
      home: _DemoQuestionHome(questions),
      recordPaths: [path],
    );
    _session = _graph.createSession(recordPathName: path.name);
  }

  @override
  void dispose() {
    _session.dispose();
    _graph.dispose();
    super.dispose();
  }

  void _submit() {
    _session.tried = true;
    final response = _session.createDetailResponse(
      detailType: bowelMovementDemoPathName,
    );
    widget.onSubmit?.call(response);
    if (widget.onSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo captured ${response.responses.length} response'
            '${response.responses.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('bowel-movement-full-view-demo'),
    backgroundColor: bowelMovementFullViewBackground,
    body: SafeArea(
      child: Column(
        children: [
          _DemoHeader(onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.large,
                AppPadding.large,
                AppPadding.large,
                AppPadding.xxxl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RenderQuestions(
                        questions: bowelMovementDemoQuestions,
                        questionsListener: _session,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Align(
                        child: FilledButton(
                          key: const ValueKey('bowel-demo-submit'),
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(132, 48),
                            backgroundColor: const Color(0xFF185EAA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRounding.small,
                              ),
                            ),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DemoHeader extends StatelessWidget {
  final VoidCallback? onBack;

  const _DemoHeader({this.onBack});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFD4DEEC))),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.medium,
        AppPadding.small,
        AppPadding.large,
        AppPadding.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: AppPadding.tiny),
            child: Semantics(
              label: 'Stripes',
              header: true,
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF0D47B5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  children: const [
                    TextSpan(text: 'STR'),
                    TextSpan(
                      text: 'i',
                      style: TextStyle(color: Color(0xFFF06B32)),
                    ),
                    TextSpan(text: 'PES'),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFD4DEEC)),
          const SizedBox(height: AppPadding.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: const ValueKey('bowel-demo-back'),
                tooltip: 'Back',
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SATURDAY, APRIL 5, 2026',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF69758A),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      bowelMovementDemoPathName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF17245E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DemoQuestionHome extends QuestionHome {
  _DemoQuestionHome(Map<String, Question> questions) {
    all = questions;
  }

  @override
  Map<String, List<Question>> byType() {
    final grouped = <String, List<Question>>{};
    for (final question in all.values) {
      grouped.putIfAbsent(question.type, () => []).add(question);
    }
    return grouped;
  }
}
